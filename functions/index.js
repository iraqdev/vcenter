const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

function toStringSafe(value) {
  return (value || '').toString().trim();
}

async function sendFcmToTokens({ tokens, title, message, data = {}, imageUrl, actionUrl }) {
  const uniqueTokens = [...new Set(tokens.filter(Boolean))];
  if (uniqueTokens.length === 0) {
    return { successCount: 0, failureCount: 0, invalidTokens: [] };
  }

  const multicastMessage = {
    tokens: uniqueTokens,
    notification: { title, body: message },
    data: Object.entries({ ...data, actionUrl: actionUrl || '' }).reduce((acc, [k, v]) => {
      acc[String(k)] = typeof v === 'string' ? v : JSON.stringify(v);
      return acc;
    }, {}),
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel_v4',
        sound: 'vcenter_notify',
        ...(imageUrl ? { imageUrl } : {}),
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'vcenter_notify.wav',
          contentAvailable: true,
        },
      },
      fcmOptions: imageUrl ? { imageUrl } : undefined,
    },
  };

  const result = await admin.messaging().sendEachForMulticast(multicastMessage);
  const invalidTokens = [];
  result.responses.forEach((response, index) => {
    if (!response.success) {
      const code = response.error?.code || '';
      if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) {
        invalidTokens.push(uniqueTokens[index]);
      }
    }
  });

  return {
    successCount: result.successCount,
    failureCount: result.failureCount,
    invalidTokens,
  };
}

exports.sendNotificationToUsers = functions.https.onCall(async (data) => {
  try {
    const title = toStringSafe(data?.title);
    const message = toStringSafe(data?.message);
    const imageUrl = toStringSafe(data?.imageUrl);
    const actionUrl = toStringSafe(data?.actionUrl);
    const payloadData = data?.data && typeof data.data === 'object' ? data.data : {};
    const branch = toStringSafe(data?.branch);
    const phoneNumber = toStringSafe(data?.phoneNumber);

    if (!title || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'title and message are required');
    }

    let query = admin.firestore().collection('users');

    if (phoneNumber) {
      query = query.where('phone', '==', phoneNumber).limit(1);
    } else if (branch) {
      query = query.where('closestBranch', '==', branch);
    }

    const usersSnapshot = await query.get();
    if (usersSnapshot.empty) {
      console.log('sendNotificationToUsers: no matched users', { branch, phoneNumber });
      return {
        success: false,
        message: 'لا يوجد مستخدمين مطابقين للشروط',
        sentCount: 0,
        failedCount: 0,
        invalidPlayerIds: [],
      };
    }

    const tokens = [];
    for (const doc of usersSnapshot.docs) {
      const user = doc.data() || {};
      const token = toStringSafe(user.fcmToken);
      if (token) tokens.push(token);
    }

    if (tokens.length === 0) {
      console.log('sendNotificationToUsers: matched users but no valid tokens', {
        matchedUsers: usersSnapshot.size,
        branch,
        phoneNumber,
      });
      return {
        success: false,
        message: 'لا يوجد مستخدمين لديهم fcmToken صالح',
        sentCount: 0,
        failedCount: 0,
        invalidTokens: [],
      };
    }

    const fcmResult = await sendFcmToTokens({
      tokens,
      title,
      message,
      imageUrl: imageUrl || undefined,
      actionUrl: actionUrl || undefined,
      data: payloadData,
    });

    if (fcmResult.invalidTokens.length > 0) {
      const batch = admin.firestore().batch();
      usersSnapshot.docs.forEach((doc) => {
        const user = doc.data() || {};
        if (fcmResult.invalidTokens.includes(toStringSafe(user.fcmToken))) {
          batch.update(doc.ref, { fcmToken: admin.firestore.FieldValue.delete() });
        }
      });
      await batch.commit();
    }

    console.log('sendNotificationToUsers: fcm result', {
      matchedUsers: usersSnapshot.size,
      tokensCount: tokens.length,
      sentCount: fcmResult.successCount,
      failedCount: fcmResult.failureCount,
      invalidTokens: fcmResult.invalidTokens.length,
      branch,
      phoneNumber,
    });

    return {
      success: fcmResult.successCount > 0,
      message: fcmResult.successCount > 0 ? 'تم إرسال الإشعار بنجاح' : 'فشل في الإرسال',
      sentCount: fcmResult.successCount,
      failedCount: fcmResult.failureCount,
      invalidTokens: fcmResult.invalidTokens,
    };
  } catch (error) {
    console.error('❌ خطأ في sendNotificationToUsers:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to send notification');
  }
});

/**
 * عند إضافة طلب جديد في bills، إرسال إشعار Push لأجهزة الداشبورد فقط (FCM)
 * العنوان: (اسم الفرع) لديك طلب جديد
 */
exports.onNewOrderCreated = functions.firestore
  .document('bills/{orderId}')
  .onCreate(async (snap, context) => {
    try {
      const orderData = snap.data();
      const orderId = context.params.orderId;
      const closestBranch = orderData.closestBranch || 'العراق';
      const title = `(${closestBranch}) لديك طلب جديد`;
      const message = `طلب جديد من ${orderData.name || 'عميل'} - ${orderData.phone || ''}`;

      const devicesSnapshot = await admin
        .firestore()
        .collection('dashboard_devices')
        .where('active', '==', true)
        .where('branch', 'in', [closestBranch, 'المسؤول'])
        .get();

      const tokens = devicesSnapshot.docs
        .map((doc) => toStringSafe(doc.data().token))
        .filter(Boolean);

      if (tokens.length === 0) {
        console.log(
          `ℹ️ لا يوجد أجهزة داش مطابقة للفرع ${closestBranch} أو المسؤول. لن يتم إرسال إشعار الطلب ${orderId}`
        );
        return null;
      }

      const result = await sendFcmToTokens({
        tokens,
        title,
        message,
        data: { type: 'new_order', orderId, closestBranch },
      });

      if (result.invalidTokens.length > 0) {
        const batch = admin.firestore().batch();
        devicesSnapshot.docs.forEach((doc) => {
          const token = toStringSafe(doc.data().token);
          if (result.invalidTokens.includes(token)) {
            batch.delete(doc.ref);
          }
        });
        await batch.commit();
      }

      console.log(
        `✅ إشعار طلب جديد - Order: ${orderId}, Branch: ${closestBranch}, Success: ${result.successCount}, Failed: ${result.failureCount}`
      );

      await admin.firestore().collection('notifications').doc(`new_order_${orderId}`).set({
        title,
        message,
        type: 'new_order',
        branch: closestBranch,
        data: { orderId, closestBranch, type: 'new_order' },
        status: result.successCount > 0 ? 'sent' : 'failed',
        sentCount: result.successCount,
        failedCount: result.failureCount,
        targetPhone: null,
        targetUserId: null,
        imageUrl: null,
        actionUrl: null,
        scheduledAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return null;
    } catch (error) {
      console.error('❌ خطأ في onNewOrderCreated:', error);
      return null;
    }
  });
