import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../config/dnz_config.dart';
import '../dnz_notifications.dart';

/// تسجيل جهاز الداشبورد عند DNZ
class DnzPushService {
  static bool _backgroundStarted = false;

  static String recipientIdForDashboardToken(String token) {
    final hash = sha256.convert(utf8.encode(token.trim())).toString().substring(0, 24);
    return 'dashboard_$hash';
  }

  static Future<void> ensureInitialized() async {
    await DNZNotifications.instance.initialize(
      apiKey: DnzConfig.apiKey,
      apiBase: DnzConfig.apiBase,
    );
  }

  static Future<void> registerDashboard({
    required String fcmToken,
    required String branch,
  }) async {
    if (fcmToken.isEmpty) return;

    await ensureInitialized();
    final recipientId = recipientIdForDashboardToken(fcmToken);

    try {
      final result = await DNZNotifications.instance.registerDevice(
        recipientId: recipientId,
        fcmToken: fcmToken,
      );
      print('✅ DNZ register dashboard: $recipientId → ${result['message'] ?? 'ok'}');

      if (!_backgroundStarted) {
        await DNZNotifications.instance.startBackground();
        _backgroundStarted = true;
      }

      await FirebaseFirestore.instance.collection('dashboard_devices').doc(fcmToken).set({
        'token': fcmToken,
        'branch': branch,
        'active': true,
        'dnzRecipientId': recipientId,
        'dnzConnectionId': DNZNotifications.instance.connectionId,
        'dnzRegisteredAt': FieldValue.serverTimestamp(),
        'dnzSubscriberId': result['subscriberId'],
        'dnzRegisterError': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ DNZ register dashboard failed: $e');
      await FirebaseFirestore.instance.collection('dashboard_devices').doc(fcmToken).set({
        'token': fcmToken,
        'branch': branch,
        'active': true,
        'dnzRegisterError': e.toString(),
        'dnzRegisterAttemptAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
