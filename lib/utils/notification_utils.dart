import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ecommerce/notifications/notification_center.dart';

/// توافق مع الاستدعاءات القديمة — كل العرض عبر NotificationCenter.
Future<void> ensureAndroidNotificationChannel(_) async {
  await NotificationCenter.init();
}

Future<void> showRemoteMessageNotification(
  _,
  RemoteMessage message,
) async {
  await NotificationCenter.showFromFcm(message);
}

String notificationTitleFromMessage(RemoteMessage message) {
  return message.notification?.title ??
      message.data['title']?.toString() ??
      'إشعار جديد';
}

String notificationBodyFromMessage(RemoteMessage message) {
  return message.notification?.body ??
      message.data['body']?.toString() ??
      message.data['message']?.toString() ??
      '';
}
