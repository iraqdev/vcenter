import 'package:cloud_firestore/cloud_firestore.dart';

/// إعدادات تخفيض الكمية — المستند: app_settings/quantity_discount
class QuantityDiscountSettings {
  final double percent;
  /// الحد الأدنى للكمية لتفعيل التخفيض
  final int minQuantity;
  /// عدد القطع التي يُطبَّق عليها التخفيض
  final int discountPieces;

  const QuantityDiscountSettings({
    this.percent = 2.5,
    this.minQuantity = 3,
    this.discountPieces = 3,
  });

  QuantityDiscountSettings copyWith({
    double? percent,
    int? minQuantity,
    int? discountPieces,
  }) {
    return QuantityDiscountSettings(
      percent: percent ?? this.percent,
      minQuantity: minQuantity ?? this.minQuantity,
      discountPieces: discountPieces ?? this.discountPieces,
    );
  }
}

class AppSettingsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'app_settings';
  static const String _docId = 'quantity_discount';

  static int _parsePositiveInt(dynamic raw, int fallback) {
    final v = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (v == null || v < 1) return fallback;
    return v;
  }

  static double _parsePercent(dynamic raw, double fallback) {
    final v = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (v == null || v < 0) return fallback;
    return v;
  }

  static Future<QuantityDiscountSettings> getQuantityDiscount() async {
    try {
      final doc = await _db.collection(_collection).doc(_docId).get();
      if (!doc.exists || doc.data() == null) {
        return const QuantityDiscountSettings();
      }
      final data = doc.data()!;
      final legacyPieces = data['pieces'];
      final legacy = _parsePositiveInt(legacyPieces, 3);
      return QuantityDiscountSettings(
        percent: _parsePercent(data['percent'], 2.5),
        minQuantity: _parsePositiveInt(data['minQuantity'] ?? legacyPieces, legacy),
        discountPieces:
            _parsePositiveInt(data['discountPieces'] ?? legacyPieces, legacy),
      );
    } catch (e) {
      print('خطأ في جلب إعدادات تخفيض الكمية: $e');
      return const QuantityDiscountSettings();
    }
  }

  static Future<bool> saveQuantityDiscount(QuantityDiscountSettings settings) async {
    try {
      await _db.collection(_collection).doc(_docId).set(
        {
          'percent': settings.percent,
          'minQuantity': settings.minQuantity,
          'discountPieces': settings.discountPieces,
          // إبقاء pieces متوافقاً مع النسخ القديمة = عدد القطع المخفّضة
          'pieces': settings.discountPieces,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      print('خطأ في حفظ إعدادات تخفيض الكمية: $e');
      return false;
    }
  }
}
