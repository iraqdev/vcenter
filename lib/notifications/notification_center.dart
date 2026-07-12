import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// مركز واحد لعرض الإشعارات — قناة واحدة، صوت واحد، بدون تكرار.
/// عند إغلاق التطبيق يعتمد FCM على صوت النظام الافتراضي (حسب دليل DNZ المحدّث).
class NotificationCenter {
  NotificationCenter._();

  static const String channelId = 'vcenter_push_v3';
  static const String channelName = 'إشعارات v center';
  static const String channelDescription = 'تنبيهات مع صوت النظام';
  static const String androidIcon = '@mipmap/launcher_icon';

  /// صوت النظام الافتراضي — يعمل مع FCM والتطبيق مغلق بشكل أوثق من raw المخصص.
  static const UriAndroidNotificationSound defaultAndroidSound =
      UriAndroidNotificationSound('content://settings/system/notification_sound');

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final Map<String, DateTime> _recentKeys = {};
  static bool _ready = false;

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.max,
    playSound: true,
    sound: defaultAndroidSound,
    enableVibration: true,
  );

  static Future<void> init() async {
    if (_ready) return;

    const androidInit = AndroidInitializationSettings(androidIcon);
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _ready = true;
  }

  static bool _isDuplicate(String key) {
    final now = DateTime.now();
    _recentKeys.removeWhere(
      (_, t) => now.difference(t) > const Duration(seconds: 8),
    );
    if (_recentKeys.containsKey(key)) return true;
    _recentKeys[key] = now;
    return false;
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
    String? dedupeKey,
    int? id,
  }) async {
    await init();
    final key = dedupeKey ?? '$title|$body';
    if (_isDuplicate(key)) {
      print('🔕 NotificationCenter: تخطي مكرر ($key)');
      return;
    }

    await _plugin.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title.isEmpty ? 'v center' : title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: defaultAndroidSound,
          enableVibration: true,
          icon: androidIcon,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// عرض إشعار من FCM (للمقدمة أو data-only فقط — لا تستخدم cancelAll).
  static Future<void> showFromFcm(RemoteMessage message) async {
    await init();

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'إشعار جديد';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';
    if (title.isEmpty && body.isEmpty) return;

    await show(
      title: title,
      body: body,
      dedupeKey: message.messageId ?? '$title|$body',
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
