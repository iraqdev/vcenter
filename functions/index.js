const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {
  getDnzConfig,
  recipientIdForPhone,
  recipientIdCandidates,
  recipientIdForDashboardToken,
  registerDnzMobileSubscriber,
  sendDnzPush,
} = require('./dnz_notifications');
const {
  OTP_TTL_MS,
  RESEND_COOLDOWN_MS,
  MAX_ATTEMPTS,
  normalizeIraqiPhone,
  toE164Iraq,
  otpDocId,
  hashOtp,
  generateOtpCode,
  buildOtpMessage,
  sendWhatsAppOtpMessage,
} = require('./dnz_whatsapp_otp');

admin.initializeApp();

const ALLOWED_OTP_PURPOSES = new Set(['register', 'reset']);

function setCors(res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
}

function readJsonBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  return {};
}

async function findUserByPhone(phone07) {
  const snap = await admin.firestore()
    .collection('users')
    .where('phone', '==', phone07)
    .limit(1)
    .get();
  if (snap.empty) return null;
  return { id: snap.docs[0].id, ref: snap.docs[0].ref, data: snap.docs[0].data() };
}

async function consumeVerifiedOtp({ phone07, purpose, code }) {
  const docRef = admin.firestore().collection('whatsapp_otps').doc(otpDocId(phone07, purpose));
  const snap = await docRef.get();
  if (!snap.exists) {
    return { ok: false, error: 'otp_not_found', message: 'اطلب رمز تحقق جديد أولاً.' };
  }
  const data = snap.data() || {};
  if (data.consumed === true) {
    return { ok: false, error: 'otp_used', message: 'تم استخدام هذا الرمز مسبقاً.' };
  }
  const expiresAt = data.expiresAt?.toMillis?.() ?? 0;
  if (!expiresAt || Date.now() > expiresAt) {
    return { ok: false, error: 'otp_expired', message: 'انتهت صلاحية رمز التحقق.' };
  }
  const attempts = Number(data.attempts || 0);
  if (attempts >= MAX_ATTEMPTS) {
    return { ok: false, error: 'otp_locked', message: 'تم تجاوز عدد المحاولات. اطلب رمزاً جديداً.' };
  }
  const expected = hashOtp(phone07, purpose, String(code || '').trim());
  if (expected !== data.codeHash) {
    await docRef.set({
      attempts: attempts + 1,
      lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: false, error: 'otp_invalid', message: 'رمز التحقق غير صحيح.' };
  }
  await docRef.set({
    verified: true,
    consumed: true,
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return { ok: true };
}

function toStringSafe(value) {
  return (value || '').toString().trim();
}

function dnzDataPayload({ data = {}, imageUrl, actionUrl }) {
  return Object.entries({
    ...data,
    actionUrl: actionUrl || '',
    imageUrl: imageUrl || '',
  }).reduce((acc, [k, v]) => {
    if (v == null) return acc;
    acc[String(k)] = typeof v === 'string' ? v : JSON.stringify(v);
    return acc;
  }, {});
}

async function registerUserWithDnz({ phone, fcmToken, apnsToken, platform, userRef, extra = {} }) {
  const recipientId = recipientIdForPhone(phone);
  const token = toStringSafe(fcmToken);
  const apns = toStringSafe(apnsToken);
  if (!recipientId || (!token && !apns)) return { ok: false };

  const resolvedPlatform =
    toStringSafe(platform) ||
    (apns && !token ? 'ios' : toStringSafe(extra.platform)) ||
    'android';

  const result = await registerDnzMobileSubscriber({
    recipientId,
    fcmToken: token || undefined,
    apnsToken: apns || undefined,
    platform: resolvedPlatform,
    metadata: {
      phone,
      source: 'akelapp',
      ...extra.metadata,
    },
  });

  if (result.ok && userRef) {
    await userRef.set({
      dnzRecipientId: recipientId,
      dnzRegisteredAt: admin.firestore.FieldValue.serverTimestamp(),
      dnzSubscriberId: result.payload?.subscriberId || null,
      dnzRegisterError: admin.firestore.FieldValue.delete(),
      pushPlatform: resolvedPlatform,
    }, { merge: true });
  } else if (userRef) {
    await userRef.set({
      dnzRegisterError: result.error || `http_${result.status}`,
      dnzRegisterStatus: result.status || 0,
      dnzRegisterPayload: result.payload || null,
      dnzRegisterAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  return { ok: result.ok, recipientId, result };
}

async function registerDashboardWithDnz({ token, branch, deviceRef }) {
  const recipientId = recipientIdForDashboardToken(token);
  if (!recipientId || !token) return { ok: false };

  const result = await registerDnzMobileSubscriber({
    recipientId,
    fcmToken: token,
    platform: 'android',
    metadata: {
      branch: branch || '',
      source: 'dashboard_app',
    },
  });

  if (result.ok && deviceRef) {
    await deviceRef.set({
      dnzRecipientId: recipientId,
      dnzRegisteredAt: admin.firestore.FieldValue.serverTimestamp(),
      dnzSubscriberId: result.payload?.subscriberId || null,
    }, { merge: true });
  }

  return { ok: result.ok, recipientId, result };
}

async function sendDnzToRecipients({
  recipientIds,
  title,
  message,
  data = {},
  imageUrl,
  actionUrl,
}) {
  const uniqueRecipients = [...new Set(recipientIds.filter(Boolean))];
  if (uniqueRecipients.length === 0) {
    return { sentCount: 0, failedCount: 0, results: [] };
  }

  const payload = dnzDataPayload({ data, imageUrl, actionUrl });
  const results = [];
  let sentCount = 0;
  let failedCount = 0;
  const tried = new Set();

  for (const recipientId of uniqueRecipients) {
    if (tried.has(recipientId)) continue;
    tried.add(recipientId);

    const result = await sendDnzPush({
      recipientId,
      title,
      body: message,
      data: payload,
    });
    results.push({ recipientId, ...result });
    if (result.ok) sentCount += 1;
    else failedCount += 1;
  }

  return { sentCount, failedCount, results };
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
    const userType = toStringSafe(data?.userType);

    if (!title || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'title and message are required');
    }

    let query = admin.firestore().collection('users');

    if (phoneNumber) {
      query = query.where('phone', '==', phoneNumber).limit(1);
    } else if (branch) {
      query = query.where('closestBranch', '==', branch);
    } else if (userType) {
      query = query.where('userType', '==', userType);
    }

    const usersSnapshot = await query.get();

    let matchedDocs = usersSnapshot.docs;
    if (!phoneNumber && userType) {
      matchedDocs = matchedDocs.filter(
        (doc) => toStringSafe((doc.data() || {}).userType) === userType
      );
    }

    if (matchedDocs.length === 0) {
      console.log('sendNotificationToUsers: no matched users', { branch, phoneNumber, userType });
      return {
        success: false,
        message: 'لا يوجد مستخدمين مطابقين للشروط',
        sentCount: 0,
        failedCount: 0,
        invalidPlayerIds: [],
      };
    }

    const dnzCfg = getDnzConfig();
    let sentCount = 0;
    let failedCount = 0;
    let invalidTokens = [];
    let transport = 'none';

    for (const doc of matchedDocs) {
      const user = doc.data() || {};
      const phone = toStringSafe(user.phone);
      const token = toStringSafe(user.fcmToken);
      const apnsToken = toStringSafe(user.apnsToken);
      const pushPlatform = toStringSafe(user.pushPlatform);
      const storedRecipientId = toStringSafe(user.dnzRecipientId);

      if (!phone) {
        failedCount += 1;
        continue;
      }

      if (dnzCfg.apiKey && (token || apnsToken)) {
        await registerUserWithDnz({
          phone,
          fcmToken: token || undefined,
          apnsToken: apnsToken || undefined,
          platform: pushPlatform || (apnsToken ? 'ios' : 'android'),
          userRef: doc.ref,
        });
      }

      const dnzResult = await sendDnzToRecipients({
        recipientIds: recipientIdCandidates(phone, storedRecipientId),
        title,
        message,
        data: payloadData,
        imageUrl: imageUrl || undefined,
        actionUrl: actionUrl || undefined,
      });

      if (dnzResult.sentCount > 0) {
        sentCount += dnzResult.sentCount;
        transport = 'dnz';
      } else {
        failedCount += dnzResult.failedCount || 1;
      }
    }

    if (sentCount === 0 && failedCount === 0) {
      return {
        success: false,
        message: 'لا يوجد مستخدمين لديهم توكن إشعارات صالح',
        sentCount: 0,
        failedCount: 0,
        invalidTokens: [],
      };
    }

    console.log('sendNotificationToUsers: result', {
      matchedUsers: matchedDocs.length,
      sentCount,
      failedCount,
      invalidTokens: invalidTokens.length,
      transport,
      branch,
      phoneNumber,
      userType,
    });

    return {
      success: sentCount > 0,
      message: sentCount > 0 ? 'تم إرسال الإشعار بنجاح' : 'فشل في الإرسال',
      sentCount,
      failedCount,
      invalidTokens,
      transport,
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

      const dnzCfg = getDnzConfig();
      const recipientIds = [];
      const tokens = [];

      for (const doc of devicesSnapshot.docs) {
        const data = doc.data() || {};
        const token = toStringSafe(data.token);
        if (token) tokens.push(token);

        if (dnzCfg.apiKey && token) {
          const reg = await registerDashboardWithDnz({
            token,
            branch: toStringSafe(data.branch),
            deviceRef: doc.ref,
          });
          if (reg.recipientId) recipientIds.push(reg.recipientId);
        } else {
          const recipientId = toStringSafe(data.dnzRecipientId) || recipientIdForDashboardToken(token);
          if (recipientId) recipientIds.push(recipientId);
        }
      }

      if (tokens.length === 0 && recipientIds.length === 0) {
        console.log(
          `ℹ️ لا يوجد أجهزة داش مطابقة للفرع ${closestBranch} أو المسؤول. لن يتم إرسال إشعار الطلب ${orderId}`
        );
        return null;
      }

      let successCount = 0;
      let failureCount = 0;
      let transport = 'dnz';

      if (dnzCfg.apiKey && recipientIds.length > 0) {
        const dnzResult = await sendDnzToRecipients({
          recipientIds,
          title,
          message,
          data: { type: 'new_order', orderId, closestBranch },
        });
        successCount = dnzResult.sentCount;
        failureCount = dnzResult.failedCount;
      } else {
        failureCount = tokens.length;
      }

      console.log(
        `✅ إشعار طلب جديد - Order: ${orderId}, Branch: ${closestBranch}, Success: ${successCount}, Failed: ${failureCount}, Transport: ${transport}`
      );

      await admin.firestore().collection('notifications').doc(`new_order_${orderId}`).set({
        title,
        message,
        type: 'new_order',
        branch: closestBranch,
        data: { orderId, closestBranch, type: 'new_order' },
        status: successCount > 0 ? 'sent' : 'failed',
        sentCount: successCount,
        failedCount: failureCount,
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

const CANCELLED_RETENTION_MS = 15 * 60 * 1000;

function isOrderCancelledData(data) {
  const orderstatus = toStringSafe(data?.orderstatus);
  const status = data?.status;
  return orderstatus === 'ملغي' || status === 3 || status === '3';
}

function cancelledAtMs(data) {
  const cancelledAt = data?.cancelledAt;
  if (cancelledAt && typeof cancelledAt.toDate === 'function') {
    return cancelledAt.toDate().getTime();
  }
  const updatedAt = data?.updatedAt;
  if (updatedAt && typeof updatedAt.toDate === 'function') {
    return updatedAt.toDate().getTime();
  }
  return null;
}

/**
 * حذف الطلبات الملغية بعد 15 دقيقة من الإلغاء (يعمل حتى بدون فتح التطبيق).
 */
/**
 * تسجيل جهاز المستخدم عند DNZ عند تحديث fcmToken / apnsToken.
 */
exports.onUserPushTokenUpdated = functions.firestore
  .document('users/{userId}')
  .onWrite(async (change) => {
    if (!change.after.exists) return null;

    const after = change.after.data() || {};
    const before = change.before.exists ? (change.before.data() || {}) : {};
    const fcmToken = toStringSafe(after.fcmToken);
    const apnsToken = toStringSafe(after.apnsToken);
    const phone = toStringSafe(after.phone);
    const pushPlatform = toStringSafe(after.pushPlatform);

    if (!phone) return null;
    if (!fcmToken && !apnsToken) return null;

    const expectedRecipientId = recipientIdForPhone(phone);
    const tokensUnchanged =
      fcmToken === toStringSafe(before.fcmToken) &&
      apnsToken === toStringSafe(before.apnsToken);
    if (
      tokensUnchanged &&
      toStringSafe(after.dnzRecipientId) === expectedRecipientId
    ) {
      return null;
    }

    const { apiKey } = getDnzConfig();
    if (!apiKey) return null;

    const result = await registerUserWithDnz({
      phone,
      fcmToken: fcmToken || undefined,
      apnsToken: apnsToken || undefined,
      platform: pushPlatform || (apnsToken ? 'ios' : 'android'),
      userRef: change.after.ref,
    });

    console.log('onUserPushTokenUpdated', {
      phone,
      platform: pushPlatform || (apnsToken ? 'ios' : 'android'),
      ok: result.ok,
      recipientId: result.recipientId,
      status: result.result?.status,
    });
    return null;
  });

/**
 * تسجيل جهاز الداشبورد عند DNZ عند تحديث token.
 */
exports.onDashboardDeviceUpdated = functions.firestore
  .document('dashboard_devices/{deviceId}')
  .onWrite(async (change) => {
    if (!change.after.exists) return null;

    const after = change.after.data() || {};
    const before = change.before.exists ? (change.before.data() || {}) : {};
    const token = toStringSafe(after.token);
    const branch = toStringSafe(after.branch);

    if (!token || after.active === false) return null;
    if (token === toStringSafe(before.token) && toStringSafe(after.dnzRecipientId)) {
      return null;
    }

    const { apiKey } = getDnzConfig();
    if (!apiKey) return null;

    const result = await registerDashboardWithDnz({
      token,
      branch,
      deviceRef: change.after.ref,
    });

    console.log('onDashboardDeviceUpdated', {
      branch,
      ok: result.ok,
      recipientId: result.recipientId,
      status: result.result?.status,
    });
    return null;
  });

/**
 * طلب إرسال رمز واتساب — purposes: register | reset
 * Body: { phone, purpose }
 */
exports.requestWhatsAppOtp = functions.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(204).send('');
  if (req.method !== 'POST') {
    return res.status(405).json({ ok: false, error: 'method_not_allowed' });
  }

  try {
    const body = readJsonBody(req);
    const purpose = toStringSafe(body.purpose);
    const phone07 = normalizeIraqiPhone(body.phone);

    if (!ALLOWED_OTP_PURPOSES.has(purpose)) {
      return res.status(400).json({ ok: false, error: 'invalid_purpose', message: 'نوع العملية غير صالح.' });
    }
    if (!phone07) {
      return res.status(400).json({
        ok: false,
        error: 'invalid_phone',
        message: 'رقم الهاتف غير صحيح. يجب أن يكون 11 رقماً ويبدأ بـ 07.',
      });
    }

    const existing = await findUserByPhone(phone07);
    if (purpose === 'register' && existing) {
      return res.status(409).json({
        ok: false,
        error: 'phone_in_use',
        message: 'رقم الهاتف مستخدم بالفعل.',
      });
    }
    if (purpose === 'reset' && !existing) {
      return res.status(404).json({
        ok: false,
        error: 'user_not_found',
        message: 'لا يوجد حساب مرتبط بهذا الرقم.',
      });
    }

    const docRef = admin.firestore().collection('whatsapp_otps').doc(otpDocId(phone07, purpose));
    const prev = await docRef.get();
    if (prev.exists) {
      const lastSentAt = prev.data()?.lastSentAt?.toMillis?.() ?? 0;
      if (lastSentAt && Date.now() - lastSentAt < RESEND_COOLDOWN_MS) {
        const waitSec = Math.ceil((RESEND_COOLDOWN_MS - (Date.now() - lastSentAt)) / 1000);
        return res.status(429).json({
          ok: false,
          error: 'resend_cooldown',
          message: `انتظر ${waitSec} ثانية قبل إعادة الإرسال.`,
          waitSec,
        });
      }
    }

    const code = generateOtpCode();
    const numberE164 = toE164Iraq(phone07);
    const sendResult = await sendWhatsAppOtpMessage({
      numberE164,
      message: buildOtpMessage(code),
    });

    if (!sendResult.ok) {
      const configured = sendResult.error !== 'whatsapp_otp_not_configured';
      return res.status(configured ? 502 : 503).json({
        ok: false,
        error: sendResult.error || 'send_failed',
        message: configured
          ? 'فشل إرسال رمز واتساب. حاول لاحقاً.'
          : 'خدمة واتساب غير مُعدّة بعد. أضف مفتاح API ثم أعد النشر.',
      });
    }

    const now = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + OTP_TTL_MS);
    await docRef.set({
      phone: phone07,
      purpose,
      codeHash: hashOtp(phone07, purpose, code),
      attempts: 0,
      verified: false,
      consumed: false,
      createdAt: now,
      lastSentAt: now,
      expiresAt,
      jobId: sendResult.payload?.jobId || null,
    });

    return res.status(200).json({
      ok: true,
      message: 'تم إرسال رمز التحقق عبر واتساب.',
      expiresInSec: Math.floor(OTP_TTL_MS / 1000),
      resendInSec: Math.floor(RESEND_COOLDOWN_MS / 1000),
    });
  } catch (error) {
    console.error('requestWhatsAppOtp error', error);
    return res.status(500).json({
      ok: false,
      error: 'server_error',
      message: 'حدث خطأ في الخادم.',
    });
  }
});

/**
 * التحقق من رمز واتساب
 * Body: { phone, purpose, code }
 */
exports.verifyWhatsAppOtp = functions.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(204).send('');
  if (req.method !== 'POST') {
    return res.status(405).json({ ok: false, error: 'method_not_allowed' });
  }

  try {
    const body = readJsonBody(req);
    const purpose = toStringSafe(body.purpose);
    const phone07 = normalizeIraqiPhone(body.phone);
    const code = toStringSafe(body.code);

    if (!ALLOWED_OTP_PURPOSES.has(purpose) || !phone07 || !code) {
      return res.status(400).json({
        ok: false,
        error: 'invalid_request',
        message: 'بيانات غير مكتملة.',
      });
    }

    // للتسجيل: نتحقق دون استهلاك كامل إن أردنا — لكن نستهلك بعد النجاح
    // ونسمح بإكمال التسجيل مباشرة بعد verify
    const result = await consumeVerifiedOtp({ phone07, purpose, code });
    if (!result.ok) {
      const status = result.error === 'otp_locked' ? 429 : 400;
      return res.status(status).json({
        ok: false,
        error: result.error,
        message: result.message,
      });
    }

    return res.status(200).json({
      ok: true,
      message: 'تم التحقق بنجاح.',
      phone: phone07,
      purpose,
    });
  } catch (error) {
    console.error('verifyWhatsAppOtp error', error);
    return res.status(500).json({
      ok: false,
      error: 'server_error',
      message: 'حدث خطأ في الخادم.',
    });
  }
});

/**
 * إعادة تعيين كلمة المرور بعد التحقق من OTP
 * Body: { phone, code, newPassword }
 */
exports.resetPasswordWithOtp = functions.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(204).send('');
  if (req.method !== 'POST') {
    return res.status(405).json({ ok: false, error: 'method_not_allowed' });
  }

  try {
    const body = readJsonBody(req);
    const phone07 = normalizeIraqiPhone(body.phone);
    const code = toStringSafe(body.code);
    const newPassword = toStringSafe(body.newPassword);

    if (!phone07 || !code) {
      return res.status(400).json({
        ok: false,
        error: 'invalid_request',
        message: 'بيانات غير مكتملة.',
      });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({
        ok: false,
        error: 'weak_password',
        message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.',
      });
    }

    const user = await findUserByPhone(phone07);
    if (!user) {
      return res.status(404).json({
        ok: false,
        error: 'user_not_found',
        message: 'لا يوجد حساب مرتبط بهذا الرقم.',
      });
    }

    const result = await consumeVerifiedOtp({
      phone07,
      purpose: 'reset',
      code,
    });
    if (!result.ok) {
      const status = result.error === 'otp_locked' ? 429 : 400;
      return res.status(status).json({
        ok: false,
        error: result.error,
        message: result.message,
      });
    }

    await user.ref.set({
      password: newPassword,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return res.status(200).json({
      ok: true,
      message: 'تم تغيير كلمة المرور بنجاح.',
    });
  } catch (error) {
    console.error('resetPasswordWithOtp error', error);
    return res.status(500).json({
      ok: false,
      error: 'server_error',
      message: 'حدث خطأ في الخادم.',
    });
  }
});

exports.purgeCancelledOrders = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('Asia/Baghdad')
  .onRun(async () => {
    try {
      const cutoff = Date.now() - CANCELLED_RETENTION_MS;
      const snap = await admin.firestore()
        .collection('bills')
        .where('orderstatus', '==', 'ملغي')
        .get();

      let deleted = 0;
      let batch = admin.firestore().batch();
      let batchCount = 0;

      for (const doc of snap.docs) {
        const ms = cancelledAtMs(doc.data() || {});
        if (ms == null || ms > cutoff) continue;
        batch.delete(doc.ref);
        batchCount += 1;
        deleted += 1;
        if (batchCount >= 500) {
          await batch.commit();
          batch = admin.firestore().batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      console.log(`purgeCancelledOrders: deleted ${deleted}`);
      return null;
    } catch (error) {
      console.error('❌ خطأ في purgeCancelledOrders:', error);
      return null;
    }
  });
