import 'dart:convert';

import 'package:ecommerce/config/dnz_gateway_config.dart';
import 'package:http/http.dart' as http;

class DnzPaymentCreateResult {
  final String paymentUrl;
  final String paymentId;

  const DnzPaymentCreateResult({
    required this.paymentUrl,
    required this.paymentId,
  });
}

/// إنشاء رابط دفع DNZ Gateway والتحقق من الحالة قبل إنشاء الطلب.
class DnzPaymentService {
  /// يُرجع رابط الدفع ومعرّف العملية، أو null مع رسالة خطأ عبر [onError].
  static Future<DnzPaymentCreateResult?> createPaymentLink({
    required int productsTotal,
    required String productName,
    String? description,
    void Function(String message)? onError,
  }) async {
    if (productsTotal <= 0) {
      onError?.call('السلة فارغة');
      return null;
    }

    final uri = Uri.parse('${DnzGatewayConfig.apiBase}/api/payments/create');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': DnzGatewayConfig.apiKey,
        },
        body: jsonEncode({
          'productName': productName,
          'amount': productsTotal,
          'currency': DnzGatewayConfig.currency,
          'description': description ?? productName,
        }),
      );

      Map<String, dynamic> body = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = body['message']?.toString() ??
            body['error']?.toString() ??
            body['detail']?.toString() ??
            'فشل إنشاء رابط الدفع (${response.statusCode})';
        onError?.call(msg);
        return null;
      }

      final link = _extractPaymentUrl(body);
      if (link == null || link.isEmpty) {
        onError?.call('لم يتم إرجاع رابط دفع من البوابة');
        return null;
      }

      final paymentId = _extractPaymentId(body, link);
      if (paymentId == null || paymentId.isEmpty) {
        onError?.call('لم يتم إرجاع معرّف الدفع من البوابة');
        return null;
      }

      return DnzPaymentCreateResult(paymentUrl: link, paymentId: paymentId);
    } catch (e) {
      onError?.call('خطأ في الاتصال ببوابة الدفع');
      print('❌ DnzPaymentService create: $e');
      return null;
    }
  }

  /// الحالة المتوقعة: pending | success | failed
  static Future<String?> getPaymentStatus(
    String paymentId, {
    void Function(String message)? onError,
  }) async {
    final id = paymentId.trim();
    if (id.isEmpty) {
      onError?.call('معرّف الدفع غير صالح');
      return null;
    }

    final uri = Uri.parse(
      '${DnzGatewayConfig.apiBase}/api/payments/status/$id',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'X-API-Key': DnzGatewayConfig.apiKey,
        },
      );

      Map<String, dynamic> body = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = body['message']?.toString() ??
            body['error']?.toString() ??
            'فشل التحقق من حالة الدفع (${response.statusCode})';
        onError?.call(msg);
        return null;
      }

      final status = _extractStatus(body);
      if (status == null || status.isEmpty) {
        onError?.call('لم يتم إرجاع حالة الدفع');
        return null;
      }
      return status;
    } catch (e) {
      onError?.call('خطأ في التحقق من حالة الدفع');
      print('❌ DnzPaymentService status: $e');
      return null;
    }
  }

  static bool isSuccessStatus(String? status) {
    final s = (status ?? '').trim().toLowerCase();
    return s == 'success' ||
        s == 'succeeded' ||
        s == 'paid' ||
        s == 'completed' ||
        s == 'complete';
  }

  static bool isFailedStatus(String? status) {
    final s = (status ?? '').trim().toLowerCase();
    return s == 'failed' ||
        s == 'fail' ||
        s == 'cancelled' ||
        s == 'canceled' ||
        s == 'expired' ||
        s == 'rejected';
  }

  static String? _extractStatus(Map<String, dynamic> body) {
    const keys = ['status', 'paymentStatus', 'payment_status', 'state'];
    for (final key in keys) {
      final value = body[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    final payment = body['payment'];
    if (payment is Map<String, dynamic>) {
      for (final key in keys) {
        final value = payment[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    return null;
  }

  static String? _extractPaymentUrl(Map<String, dynamic> body) {
    const keys = [
      'paymentUrl',
      'payment_url',
      'checkoutUrl',
      'checkout_url',
      'formUrl',
      'form_url',
      'url',
      'link',
      'paymentLink',
      'payment_link',
      'redirectUrl',
      'redirect_url',
    ];

    for (final key in keys) {
      final value = body[key];
      if (value is String && value.trim().startsWith('http')) {
        return value.trim();
      }
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is String && value.trim().startsWith('http')) {
          return value.trim();
        }
      }
    }

    final payment = body['payment'];
    if (payment is Map<String, dynamic>) {
      for (final key in keys) {
        final value = payment[key];
        if (value is String && value.trim().startsWith('http')) {
          return value.trim();
        }
      }
    }

    return null;
  }

  static String? _extractPaymentId(Map<String, dynamic> body, String paymentUrl) {
    const keys = [
      'paymentId',
      'payment_id',
      'id',
      'transactionId',
      'transaction_id',
    ];

    String? fromMap(Map<String, dynamic> map) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return null;
    }

    final direct = fromMap(body);
    if (direct != null) return direct;

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nested = fromMap(data);
      if (nested != null) return nested;
    }

    final payment = body['payment'];
    if (payment is Map<String, dynamic>) {
      final nested = fromMap(payment);
      if (nested != null) return nested;
    }

    try {
      final uri = Uri.parse(paymentUrl);
      for (final key in ['paymentId', 'payment_id', 'id', 'pid']) {
        final v = uri.queryParameters[key];
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last.trim();
        if (last.isNotEmpty && last.toLowerCase() != 'pay') return last;
      }
    } catch (_) {}

    return null;
  }
}
