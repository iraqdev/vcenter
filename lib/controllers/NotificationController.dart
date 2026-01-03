import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/main.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  var notifications = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // جلب الإشعارات من Firebase للمستخدم الحالي
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      
      print('🔍 بدء جلب الإشعارات...');
      
      final phone = sharedPreferences?.getString('phone');
      if (phone == null) {
        print('❌ لم يتم العثور على رقم الهاتف');
        return;
      }

      print('📱 رقم الهاتف: $phone');

      // البحث عن المستخدم بالهاتف
      final userDoc = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        print('❌ لم يتم العثور على المستخدم');
        return;
      }

      final userId = userDoc.docs.first.id;
      print('👤 معرف المستخدم: $userId');

      // جلب الإشعارات للمستخدم (بدون orderBy لتجنب مشكلة الفهرس)
      print('📥 جلب الإشعارات من Firestore...');
      final notificationsSnapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      print('📊 عدد الإشعارات المسترجعة: ${notificationsSnapshot.docs.length}');

      // تحويل البيانات وترتيبها محلياً
      notifications.value = notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        print('📄 إشعار: ${data['title']}, timestamp: ${data['timestamp']}');
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'body': data['body'] ?? '',
          'type': data['type'] ?? 'general',
          'isRead': data['isRead'] ?? false,
          'timestamp': data['timestamp'] != null 
              ? (data['timestamp'] as Timestamp).toDate() 
              : DateTime.now(),
          'data': data['data'] ?? {},
        };
      }).toList();

      // ترتيب الإشعارات محلياً (الأحدث أولاً)
      notifications.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      // حساب عدد الإشعارات غير المقروءة
      unreadCount.value = notifications.where((n) => !n['isRead']).length;

      print('✅ تم جلب ${notifications.length} إشعار بنجاح');
      print('📬 إشعارات غير مقروءة: ${unreadCount.value}');

    } catch (e) {
      print('❌ خطأ في جلب الإشعارات: $e');
      Get.snackbar('خطأ', 'فشل في جلب الإشعارات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // تمييز إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // تحديث القائمة المحلية
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        notifications.refresh();
        unreadCount.value = notifications.where((n) => !n['isRead']).length;
      }
    } catch (e) {
      print('خطأ في تمييز الإشعار كمقروء: $e');
      Get.snackbar('خطأ', 'فشل في تمييز الإشعار كمقروء');
    }
  }

  // تمييز جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    try {
      final phone = sharedPreferences?.getString('phone');
      if (phone == null) return;

      // البحث عن المستخدم
      final userDoc = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) return;

      final userId = userDoc.docs.first.id;

      // تحديث جميع الإشعارات غير المقروءة
      final batch = _db.batch();
      final unreadNotifications = notifications.where((n) => !n['isRead']).toList();
      
      for (final notification in unreadNotifications) {
        final docRef = _db.collection('notifications').doc(notification['id']);
        batch.update(docRef, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // تحديث القائمة المحلية
      for (final notification in notifications) {
        notification['isRead'] = true;
      }
      notifications.refresh();
      unreadCount.value = 0;

    } catch (e) {
      print('خطأ في تمييز جميع الإشعارات كمقروءة: $e');
      Get.snackbar('خطأ', 'فشل في تمييز جميع الإشعارات كمقروءة');
    }
  }

  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();

      // إزالة من القائمة المحلية
      notifications.removeWhere((n) => n['id'] == notificationId);
      unreadCount.value = notifications.where((n) => !n['isRead']).length;

      Get.snackbar('تم', 'تم حذف الإشعار');
    } catch (e) {
      print('خطأ في حذف الإشعار: $e');
      Get.snackbar('خطأ', 'فشل في حذف الإشعار');
    }
  }

  // إرسال إشعار جديد (للمطورين)
  Future<void> sendNotificationToUser({
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
      print('خطأ في إرسال الإشعار: $e');
    }
  }

  // تحديث الإشعارات (للاستدعاء عند فتح الشاشة)
  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }
}
