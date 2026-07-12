import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppNotificationController extends GetxController {
  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;
  static const String _storageKey = 'app_notifications_cache';

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  // تحميل الإشعارات المحفوظة
  Future<void> _loadNotifications() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        notifications.value = decoded.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map['timestamp'] is String) {
            map['timestamp'] = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
          }
          map['isRead'] = map['isRead'] == true;
          return map;
        }).toList();
        _updateUnreadCount();
      }
    } catch (e) {
      print('خطأ في تحميل الإشعارات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persistNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializable = notifications.map((n) {
        final map = Map<String, dynamic>.from(n);
        final ts = map['timestamp'];
        if (ts is DateTime) {
          map['timestamp'] = ts.toIso8601String();
        }
        return map;
      }).toList();
      await prefs.setString(_storageKey, jsonEncode(serializable));
    } catch (e) {
      print('خطأ في حفظ الإشعارات محلياً: $e');
    }
  }

  // تحديث عدد الإشعارات غير المقروءة
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((notification) => !notification['isRead']).length;
  }

  // إضافة إشعار وارد من DNZ WebSocket
  void addIncomingDnzMessage(Map<String, dynamic> msg) {
    final newNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': msg['title']?.toString() ?? 'إشعار جديد',
      'body': msg['body']?.toString() ?? '',
      'timestamp': DateTime.now(),
      'isRead': false,
      'data': msg['data'] is Map ? Map<String, dynamic>.from(msg['data'] as Map) : <String, dynamic>{},
    };
    notifications.insert(0, newNotification);
    _updateUnreadCount();
    _persistNotifications();
  }

  // إضافة إشعار وارد من FCM
  void addIncomingMessage(RemoteMessage message) {
    final newNotification = {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? 'إشعار جديد',
      'body': message.notification?.body ?? '',
      'timestamp': DateTime.now(),
      'isRead': false,
      'data': message.data,
    };
    notifications.insert(0, newNotification);
    _updateUnreadCount();
    _persistNotifications();
  }

  // تمييز الإشعار كمقروء
  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((notification) => notification['id'] == notificationId);
    if (index != -1) {
      notifications[index]['isRead'] = true;
      _updateUnreadCount();
      _persistNotifications();
    }
  }

  // تمييز جميع الإشعارات كمقروءة
  void markAllAsRead() {
    for (var notification in notifications) {
      notification['isRead'] = true;
    }
    _updateUnreadCount();
    _persistNotifications();
  }

  // حذف إشعار
  void deleteNotification(String notificationId) {
    notifications.removeWhere((notification) => notification['id'] == notificationId);
    _updateUnreadCount();
    _persistNotifications();
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

