import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AppNotificationController extends GetxController {
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _setupNotificationListeners();
    _loadNotifications();
  }

  // إعداد مستمعي الإشعارات
  void _setupNotificationListeners() {
    // مستمع للإشعارات عند النقر عليها
    OneSignal.Notifications.addClickListener((event) {
      print('تم النقر على إشعار: ${event.notification.title}');
      _handleNotificationClick(event.notification);
      // تمييز الإشعار كمقروء عند النقر عليه
      final notificationId = event.notification.notificationId;
      if (notificationId != null) {
        markAsRead(notificationId);
      }
    });

    // ملاحظة: معالجة استلام الإشعارات تتم في main.dart
    // لتجنب التسجيل المزدوج للمستمعين
  }

  // معالجة النقر على الإشعار
  void _handleNotificationClick(OSNotification notification) {
    // يمكنك إضافة منطق التنقل هنا
    print('تفاصيل الإشعار: ${notification.additionalData}');
  }

  // معالجة الإشعار الجديد
  void _handleNewNotification(OSNotification notification) {
    // إضافة الإشعار الجديد للقائمة
    final newNotification = {
      'id': notification.notificationId,
      'title': notification.title ?? 'إشعار جديد',
      'body': notification.body ?? '',
      'timestamp': DateTime.now(),
      'isRead': false,
      'data': notification.additionalData ?? {},
    };
    
    notifications.insert(0, newNotification);
    _updateUnreadCount();
  }

  // تحميل الإشعارات المحفوظة
  Future<void> _loadNotifications() async {
    try {
      isLoading.value = true;
      
      // يمكنك إضافة منطق لتحميل الإشعارات من Firebase هنا
      // حالياً سنستخدم الإشعارات المحلية فقط
      
    } catch (e) {
      print('خطأ في تحميل الإشعارات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث عدد الإشعارات غير المقروءة
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((notification) => !notification['isRead']).length;
  }

  // تمييز الإشعار كمقروء
  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((notification) => notification['id'] == notificationId);
    if (index != -1) {
      notifications[index]['isRead'] = true;
      _updateUnreadCount();
    }
  }

  // تمييز جميع الإشعارات كمقروءة
  void markAllAsRead() {
    for (var notification in notifications) {
      notification['isRead'] = true;
    }
    _updateUnreadCount();
  }

  // حذف إشعار
  void deleteNotification(String notificationId) {
    notifications.removeWhere((notification) => notification['id'] == notificationId);
    _updateUnreadCount();
  }

  // الحصول على الإشعارات غير المقروءة
  List<Map<String, dynamic>> get unreadNotifications {
    return notifications.where((notification) => !notification['isRead']).toList();
  }

  // إضافة إشعار تجريبي (للاستخدام في التطوير)
  void addTestNotification() {
    final testNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'إشعار تجريبي',
      'body': 'هذا إشعار تجريبي للتطبيق',
      'timestamp': DateTime.now(),
      'isRead': false,
      'data': {'type': 'test'},
    };
    
    notifications.insert(0, testNotification);
    _updateUnreadCount();
  }
}

