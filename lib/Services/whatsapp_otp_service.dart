import 'dart:convert';

import 'package:http/http.dart' as http;

/// استدعاء Cloud Functions لواتساب OTP عبر DNZ (المفتاح على السيرفر فقط).
class WhatsAppOtpService {
  static const String _baseUrl =
      'https://us-central1-v-center-5f74b.cloudfunctions.net';

  static Future<Map<String, dynamic>> requestOtp({
    required String phone,
    required String purpose,
  }) async {
    return _post('requestWhatsAppOtp', {
      'phone': phone.trim(),
      'purpose': purpose,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String purpose,
    required String code,
  }) async {
    return _post('verifyWhatsAppOtp', {
      'phone': phone.trim(),
      'purpose': purpose,
      'code': code.trim(),
    });
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    return _post('resetPasswordWithOtp', {
      'phone': phone.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
    });
  }

  static Future<Map<String, dynamic>> _post(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/$functionName'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        data = {};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'ok': data['ok'] == true,
          ...data,
        };
      }

      return {
        'ok': false,
        'error': data['error'] ?? 'http_${response.statusCode}',
        'message': data['message']?.toString() ??
            'فشل الاتصال بالخادم. حاول مرة أخرى.',
        if (data['waitSec'] != null) 'waitSec': data['waitSec'],
      };
    } catch (_) {
      return {
        'ok': false,
        'error': 'network_error',
        'message': 'فشل الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
      };
    }
  }
}
