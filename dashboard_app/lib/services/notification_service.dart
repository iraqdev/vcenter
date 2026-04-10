import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const String _collection = 'notifications';
  static const String _usersCollection = 'users';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<Map<String, dynamic>> _sendViaCloudFunction({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? branch,
    String? phoneNumber,
  }) async {
    final callable = _functions.httpsCallable('sendNotificationToUsers');
    final result = await callable.call({
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'data': data ?? {},
      'branch': branch,
      'phoneNumber': phoneNumber,
    });
    final payload = Map<String, dynamic>.from(result.data as Map);
    return {
      'success': payload['success'] == true,
      'message': payload['message'] ?? 'تمت العملية',
      'sentCount': payload['sentCount'] ?? 0,
      'failedCount': payload['failedCount'] ?? 0,
      'invalidTokens': payload['invalidTokens'] ?? <String>[],
    };
  }

  // إرسال إشعار لجميع المستخدمين (مع إمكانية التصفية حسب الفرع)
  static Future<Map<String, dynamic>> sendToAllUsers({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? branch, // فلترة حسب الفرع
  }) async {
    try {
      final response = await _sendViaCloudFunction(
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
        branch: branch,
      );

      // حفظ الإشعار في قاعدة البيانات
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: 'all',
        branch: branch,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
        status: response['success'] ? 'sent' : 'failed',
        sentCount: response['sentCount'] ?? 0,
        failedCount: response['failedCount'] ?? 0,
        errorMessage: response['success'] ? null : response['message'],
      );

      await _db.collection(_collection).doc(notification.id).set(notification.toFirestore());

      return {
        'success': response['success'],
        'message': response['message'],
        'sentCount': response['sentCount'] ?? 0,
        'failedCount': response['failedCount'] ?? 0,
        'notificationId': notification.id,
      };
    } catch (e) {
      print('خطأ في إرسال الإشعار لجميع المستخدمين: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: $e',
        'sentCount': 0,
        'failedCount': 0,
      };
    }
  }

  // تطبيع رقم الهاتف للبحث (محاولة صيغ متعددة)
  static Future<QuerySnapshot> _findUserByPhone(String phoneNumber) async {
    final variations = <String>[
      phoneNumber.trim(),
      phoneNumber.trim().replaceFirst(RegExp(r'^0'), ''), // بدون 0
      '0${phoneNumber.trim().replaceFirst(RegExp(r'^0'), '')}', // مع 0
    ];
    for (final phone in variations) {
      if (phone.isEmpty) continue;
      final snap = await _db.collection(_usersCollection).where('phone', isEqualTo: phone).limit(1).get();
      if (snap.docs.isNotEmpty) return snap;
    }
    return _db.collection(_usersCollection).where('phone', isEqualTo: 'x').limit(0).get();
  }

  // إرسال إشعار لمستخدم محدد (باستخدام filters لاستهداف العملاء فقط - وليس الداشبورد)
  static Future<Map<String, dynamic>> sendToSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _sendViaCloudFunction(
        phoneNumber: phoneNumber,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );

      // تحديد حالة الإشعار بناءً على الاستجابة
      bool notificationSent = response['success'] ?? false;
      String notificationStatus = notificationSent ? 'sent' : 'failed';
      int sentCount = response['sentCount'] ?? (notificationSent ? 1 : 0);
      int failedCount = response['failedCount'] ?? (notificationSent ? 0 : 1);
      String? errorMessage = notificationSent ? null : response['message'];

      // حفظ الإشعار في قاعدة البيانات (مجموعة الإشعارات العامة)
      print('💾 إنشاء نموذج الإشعار...');
      // استخدام النوع المُمرَّر من data إن وُجد، وإلا 'specific'
      final notifType = data?['type']?.toString() ?? 'specific';
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: notifType,
        branch: null,
        targetPhone: phoneNumber,
        targetUserId: null,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
        status: notificationStatus,
        sentCount: sentCount,
        failedCount: failedCount,
        errorMessage: errorMessage,
      );

      print('💾 حفظ الإشعار في قاعدة البيانات: ${notification.id}');
      print('📋 بيانات الإشعار: ${notification.toFirestore()}');
      
      await _db.collection(_collection).doc(notification.id).set(notification.toFirestore());
      
      print('✅ تم حفظ الإشعار بنجاح في مجموعة: $_collection');

      return {
        'success': notificationSent,
        'message': notificationSent ? 'تم إرسال الإشعار بنجاح' : 'فشل في إرسال الإشعار: ${errorMessage ?? "خطأ غير معروف"}',
        'sentCount': sentCount,
        'failedCount': failedCount,
        'notificationId': notification.id,
      };
    } catch (e) {
      print('خطأ في إرسال الإشعار للمستخدم المحدد: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: $e',
        'sentCount': 0,
        'failedCount': 1,
      };
    }
  }

  // إرسال إشعار ترويجي/عرض
  static Future<Map<String, dynamic>> sendPromotionalNotification({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? targetPhone,
  }) async {
    if (targetPhone != null) {
      // إرسال لمستخدم محدد
      return await sendToSpecificUser(
        phoneNumber: targetPhone,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );
    } else {
      // إرسال لجميع المستخدمين
      return await sendToAllUsers(
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );
    }
  }

  // اختبار إرسال إشعار لمستخدم محدد (FCM)
  static Future<Map<String, dynamic>> testSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
  }) async {
    try {
      final response = await _sendViaCloudFunction(
        phoneNumber: phoneNumber,
        title: title,
        message: message,
      );
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'تمت العملية',
        'sentCount': response['sentCount'] ?? 0,
        'failedCount': response['failedCount'] ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في اختبار المستخدم المحدد: $e',
      };
    }
  }

  // اختبار إرسال FCM عبر Cloud Function
  static Future<Map<String, dynamic>> testOneSignalDirectly() async {
    try {
      final response = await _sendViaCloudFunction(
        title: 'اختبار إشعار',
        message: 'هذا إشعار تجريبي من الداشبورد',
        data: {'type': 'test', 'timestamp': DateTime.now().millisecondsSinceEpoch},
      );
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في اختبار FCM: $e',
      };
    }
  }

  // إرسال إشعار مخصص لجميع المستخدمين (العملاء فقط - حسب الفرع)
  static Future<Map<String, dynamic>> sendCustomNotificationToAll({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? branch,
  }) async {
    // استخدام sendToAllUsers لاستهداف العملاء فقط (من Firebase) وليس الداشبورد
    return sendToAllUsers(
      title: title,
      message: message,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      data: data,
      branch: branch,
    );
  }

  // إرسال إشعار مخصص لمستخدم محدد
  static Future<Map<String, dynamic>> sendCustomNotificationToSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _sendViaCloudFunction(
        phoneNumber: phoneNumber,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );
      final bool success = response['success'] == true;
      
      // حفظ الإشعار في مجموعة notifications (بتنسيق NotificationModel) لعرضه في شاشة الإشعارات
      print('💾 حفظ الإشعار في مجموعة notifications...');
      try {
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          message: message,
          type: data?['type'] ?? 'specific',
          branch: null,
          targetPhone: phoneNumber,
          targetUserId: null,
          data: data,
          imageUrl: imageUrl,
          actionUrl: actionUrl,
          scheduledAt: DateTime.now(),
          createdAt: DateTime.now(),
          status: success ? 'sent' : 'failed',
          sentCount: response['sentCount'] ?? (success ? 1 : 0),
          failedCount: response['failedCount'] ?? (success ? 0 : 1),
          errorMessage: success ? null : 'فشل الإرسال',
        );
        await _db.collection(_collection).doc(notification.id).set(notification.toFirestore());
        print('✅ تم حفظ الإشعار بنجاح');
      } catch (e) {
        print('❌ خطأ في حفظ الإشعار: $e');
      }

      if (success) {
        return {
          'success': true,
          'message': 'تم إرسال الإشعار بنجاح',
          'oneSignalResponse': null,
          'sentCount': response['sentCount'] ?? 1,
          'failedCount': response['failedCount'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل في إرسال الإشعار',
          'sentCount': response['sentCount'] ?? 0,
          'failedCount': response['failedCount'] ?? 1,
        };
      }
    } catch (e) {
      print('❌ خطأ في إرسال الإشعار المخصص للمستخدم المحدد: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار المخصص للمستخدم المحدد: $e',
        'sentCount': 0,
        'failedCount': 1,
      };
    }
  }

  // جلب جميع الإشعارات
  static Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب الإشعارات: $e');
      return [];
    }
  }

  // جلب إشعارات حسب النوع
  static Future<List<NotificationModel>> getNotificationsByType(String type) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب الإشعارات حسب النوع: $e');
      return [];
    }
  }

  // حذف إشعار
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _db.collection(_collection).doc(notificationId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف الإشعار: $e');
      return false;
    }
  }

  // جلب إحصائيات الإشعارات
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final allNotifications = await getAllNotifications();
      
      return {
        'total': allNotifications.length,
        'sent': allNotifications.where((n) => n.isSent).length,
        'failed': allNotifications.where((n) => n.isFailed).length,
        'scheduled': allNotifications.where((n) => n.isScheduled).length,
        'draft': allNotifications.where((n) => n.isDraft).length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الإشعارات: $e');
      return {
        'total': 0,
        'sent': 0,
        'failed': 0,
        'scheduled': 0,
        'draft': 0,
      };
    }
  }

  // البحث في الإشعارات
  static Future<List<NotificationModel>> searchNotifications(String query) async {
    try {
      final allNotifications = await getAllNotifications();
      
      return allNotifications.where((notification) {
        return notification.title.toLowerCase().contains(query.toLowerCase()) ||
               notification.message.toLowerCase().contains(query.toLowerCase()) ||
               notification.type.toLowerCase().contains(query.toLowerCase()) ||
               (notification.targetPhone?.contains(query) ?? false);
      }).toList();
    } catch (e) {
      print('خطأ في البحث في الإشعارات: $e');
      return [];
    }
  }

  // فحص جميع المستخدمين وطباعة تفاصيلهم
  static Future<Map<String, dynamic>> debugAllUsers() async {
    try {
      print('🔍 فحص جميع المستخدمين في قاعدة البيانات...');
      
      final usersSnapshot = await _db
          .collection(_usersCollection)
          .get();

      print('📊 إجمالي المستخدمين: ${usersSnapshot.docs.length}');
      print('👥 تفاصيل جميع المستخدمين:');
      
      int usersWithToken = 0;
      int usersWithoutToken = 0;
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final phone = userData['phone'] ?? 'غير محدد';
        final name = userData['name'] ?? 'غير محدد';
        final fcmToken = userData['fcmToken'];
        
        print('   📱 رقم الهاتف: $phone');
        print('   👤 الاسم: $name');
        print('   🆔 FCM Token: $fcmToken');
        
        if (fcmToken != null && fcmToken.toString().isNotEmpty && fcmToken.toString() != 'null') {
          usersWithToken++;
          print('   ✅ لديه FCM token صالح');
        } else {
          usersWithoutToken++;
          print('   ❌ لا يوجد FCM token');
        }
        print('   ---');
      }
      
      print('📈 ملخص:');
      print('   - مستخدمين لديهم FCM token: $usersWithToken');
      print('   - مستخدمين بدون FCM token: $usersWithoutToken');
      
      return {
        'success': true,
        'message': 'تم فحص جميع المستخدمين',
        'totalUsers': usersSnapshot.docs.length,
        'usersWithToken': usersWithToken,
        'usersWithoutToken': usersWithoutToken,
      };
      
    } catch (e) {
      print('❌ خطأ في فحص المستخدمين: $e');
      return {
        'success': false,
        'message': 'خطأ في فحص المستخدمين: $e',
      };
    }
  }
}
