import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إرسال إشعار لجميع المستخدمين
  static Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // جلب جميع المستخدمين
      final usersSnapshot = await _db.collection('users').get();
      
      if (usersSnapshot.docs.isEmpty) {
        print('لا يوجد مستخدمين في النظام');
        return;
      }

      // إرسال الإشعار لكل مستخدم
      final batch = _db.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _db.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'timestamp': timestamp,
          'data': data ?? {},
        });
      }

      await batch.commit();
      print('تم إرسال الإشعار لـ ${usersSnapshot.docs.length} مستخدم');
    } catch (e) {
      print('خطأ في إرسال الإشعار لجميع المستخدمين: $e');
    }
  }

  // إرسال إشعار لمستخدم محدد
  static Future<void> sendNotificationToUser({
    required String userPhone,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // البحث عن المستخدم بالهاتف
      final userDoc = await _db
          .collection('users')
          .where('phone', isEqualTo: userPhone)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        print('لم يتم العثور على المستخدم بالهاتف: $userPhone');
        return;
      }

      final userId = userDoc.docs.first.id;

      // إضافة الإشعار
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });

      print('تم إرسال الإشعار للمستخدم: $userPhone');
    } catch (e) {
      print('خطأ في إرسال الإشعار للمستخدم: $e');
    }
  }

  // إرسال إشعار لمستخدمين في منطقة معينة
  static Future<void> sendNotificationToUsersInArea({
    required String closestBranch,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // البحث عن المستخدمين في المنطقة
      final usersSnapshot = await _db
          .collection('users')
          .where('closestBranch', isEqualTo: closestBranch)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('لا يوجد مستخدمين في المنطقة: $closestBranch');
        return;
      }

      // إرسال الإشعار لكل مستخدم في المنطقة
      final batch = _db.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _db.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': userDoc.id,
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'timestamp': timestamp,
          'data': data ?? {},
        });
      }

      await batch.commit();
      print('تم إرسال الإشعار لـ ${usersSnapshot.docs.length} مستخدم في منطقة $closestBranch');
    } catch (e) {
      print('خطأ في إرسال الإشعار للمستخدمين في المنطقة: $e');
    }
  }

  // إرسال إشعار حالة الطلب
  static Future<void> sendOrderStatusNotification({
    required String userPhone,
    required String orderId,
    required String status,
  }) async {
    String title = '';
    String body = '';

    switch (status) {
      case 'جاري التحضير':
        title = 'تم استلام طلبك';
        body = 'طلبك رقم $orderId جاري التحضير الآن';
        break;
      case 'جاري التوصيل':
        title = 'طلبك في الطريق';
        body = 'طلبك رقم $orderId جاري التوصيل إليك';
        break;
      case 'تم التسليم':
        title = 'تم تسليم طلبك';
        body = 'طلبك رقم $orderId تم تسليمه بنجاح';
        break;
      case 'تم الإلغاء':
        title = 'تم إلغاء طلبك';
        body = 'طلبك رقم $orderId تم إلغاؤه';
        break;
      default:
        title = 'تحديث حالة الطلب';
        body = 'تم تحديث حالة طلبك رقم $orderId إلى $status';
    }

    await sendNotificationToUser(
      userPhone: userPhone,
      title: title,
      body: body,
      type: 'order_status',
      data: {
        'orderId': orderId,
        'status': status,
      },
    );
  }
}
