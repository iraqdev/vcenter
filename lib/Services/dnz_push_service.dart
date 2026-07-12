import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ecommerce/config/dnz_config.dart';
import 'package:ecommerce/dnz_notifications.dart';

/// تسجيل الجهاز عند DNZ حسب دليل: initialize → registerDevice → startBackground
/// Android: nativeFcmToken | iOS: nativeApnsToken (+ FCM إن وُجد)
class DnzPushService {
  static bool _backgroundStarted = false;
  static bool _handlersAttached = false;

  static String recipientIdForPhone(String phone) {
    final p = phone.trim();
    if (p.isEmpty) return '';
    return p.startsWith('user_') ? p : 'user_$p';
  }

  static String recipientIdForDashboardToken(String token) {
    final hash = sha256.convert(utf8.encode(token.trim())).toString().substring(0, 24);
    return 'dashboard_$hash';
  }

  static bool get isWebSocketConnected =>
      DNZNotifications.instance.isWebSocketConnected;

  static Future<void> ensureInitialized() async {
    await DNZNotifications.instance.initialize(
      apiKey: DnzConfig.apiKey,
      apiBase: DnzConfig.apiBase,
    );
  }

  static void attachMessageHandler(void Function(Map<String, dynamic> msg) handler) {
    if (_handlersAttached) return;
    DNZNotifications.instance.onMessage(handler);
    _handlersAttached = true;
  }

  /// انتظار توكن APNs على iOS (قد يتأخر بعد منح الإذن).
  static Future<String?> _resolveApnsToken() async {
    if (!Platform.isIOS) return null;
    for (var i = 0; i < 8; i++) {
      final token = await FirebaseMessaging.instance.getAPNSToken();
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
      await Future.delayed(const Duration(milliseconds: 700));
    }
    return null;
  }

  static Future<void> registerCustomer(String phone) async {
    if (phone.trim().isEmpty) return;

    await ensureInitialized();

    final fcmToken = await FirebaseMessaging.instance.getToken();
    final apnsToken = await _resolveApnsToken();
    final isIos = Platform.isIOS;

    if (isIos) {
      if (apnsToken == null || apnsToken.isEmpty) {
        print('❌ DNZ iOS: لا يوجد APNs token بعد — تأكد من Push Capability وملف APNs في كونسول DNZ');
        // ما زلنا نحاول بالـ FCM إن وُجد كاحتياط
        if (fcmToken == null || fcmToken.isEmpty) return;
      }
    } else {
      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ DNZ: لا يوجد FCM token للعميل');
        return;
      }
    }

    final recipientId = recipientIdForPhone(phone);
    try {
      final result = await DNZNotifications.instance.registerDevice(
        recipientId: recipientId,
        fcmToken: (fcmToken != null && fcmToken.isNotEmpty) ? fcmToken : null,
        apnsToken: apnsToken,
      );
      print(
        '✅ DNZ register customer: $recipientId '
        '(platform=${isIos ? 'ios' : 'android'}, '
        'apns=${apnsToken != null}, fcm=${fcmToken != null}) '
        '→ ${result['message'] ?? 'ok'}',
      );

      if (!_backgroundStarted) {
        await DNZNotifications.instance.startBackground();
        _backgroundStarted = true;
      }

      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (users.docs.isNotEmpty) {
        final data = <String, dynamic>{
          'dnzRecipientId': recipientId,
          'dnzConnectionId': DNZNotifications.instance.connectionId,
          'dnzRegisteredAt': FieldValue.serverTimestamp(),
          'dnzRegisterError': FieldValue.delete(),
          'pushPlatform': isIos ? 'ios' : 'android',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (fcmToken != null && fcmToken.isNotEmpty) {
          data['fcmToken'] = fcmToken;
        }
        if (apnsToken != null && apnsToken.isNotEmpty) {
          data['apnsToken'] = apnsToken;
        } else if (isIos) {
          data['apnsToken'] = FieldValue.delete();
        }
        await users.docs.first.reference.set(data, SetOptions(merge: true));
      }
    } catch (e) {
      print('❌ DNZ register customer failed: $e');
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (users.docs.isNotEmpty) {
        await users.docs.first.reference.set({
          'dnzRegisterError': e.toString(),
          'dnzRegisterAttemptAt': FieldValue.serverTimestamp(),
          'pushPlatform': isIos ? 'ios' : 'android',
        }, SetOptions(merge: true));
      }
    }
  }
}
