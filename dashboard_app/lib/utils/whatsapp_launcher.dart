import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// فتح محادثة واتساب برقم هاتف عراقي.
class WhatsAppLauncher {
  static const _noPhoneMessage = 'لا يوجد رقم هاتف لصاحب هذا الطلب';

  /// يحوّل 07xxxxxxxxx إلى 9647xxxxxxxxx لرابط wa.me
  static String? normalizeIraqiPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('964') && digits.length >= 12) {
      return digits;
    }
    if (digits.length == 11 && digits.startsWith('07')) {
      return '964${digits.substring(1)}';
    }
    if (digits.length == 10 && digits.startsWith('7')) {
      return '964$digits';
    }
    return null;
  }

  static Future<void> openChat(
    String phone, {
    String? message,
  }) async {
    final normalized = normalizeIraqiPhone(phone);
    if (normalized == null) {
      _showNoPhone();
      return;
    }

    final uri = message == null || message.trim().isEmpty
        ? Uri.parse('https://wa.me/$normalized')
        : Uri.parse(
            'https://wa.me/$normalized?text=${Uri.encodeComponent(message.trim())}',
          );

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showNoPhone();
    } catch (_) {
      _showNoPhone();
    }
  }

  static void _showNoPhone() {
    Get.snackbar(
      'غير متاح',
      _noPhoneMessage,
      backgroundColor: Colors.orange.shade800,
      colorText: Colors.white,
      icon: const Icon(Icons.phone_disabled, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
