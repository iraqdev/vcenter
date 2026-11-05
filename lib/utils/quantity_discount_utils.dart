import 'package:cloud_firestore/cloud_firestore.dart';

/// القيم الافتراضية لتخفيض الكمية.
const double kDefaultQuantityDiscountPercent = 2.5;
const int kDefaultQuantityDiscountMinQuantity = 3;
const int kDefaultQuantityDiscountPieces = 3;

/// إعدادات تخفيض الكمية من Firestore: app_settings/quantity_discount
class QuantityDiscountConfig {
  /// نسبة التخفيض (%)
  final double percent;

  /// الحد الأدنى للكمية لتفعيل التخفيض
  final int minQuantity;

  /// عدد القطع التي يُطبَّق عليها التخفيض
  final int discountPieces;

  const QuantityDiscountConfig({
    this.percent = kDefaultQuantityDiscountPercent,
    this.minQuantity = kDefaultQuantityDiscountMinQuantity,
    this.discountPieces = kDefaultQuantityDiscountPieces,
  });
}

QuantityDiscountConfig _cachedConfig = const QuantityDiscountConfig();
bool _loadedOnce = false;

QuantityDiscountConfig get quantityDiscountConfig => _cachedConfig;

int _parsePositiveInt(dynamic raw, int fallback) {
  final v = raw is num ? raw.toInt() : int.tryParse('$raw');
  if (v == null || v < 1) return fallback;
  return v;
}

double _parsePercent(dynamic raw, double fallback) {
  final v = raw is num ? raw.toDouble() : double.tryParse('$raw');
  if (v == null || v < 0) return fallback;
  return v;
}

/// جلب/تحديث إعدادات التخفيض من Firestore (مع كاش محلي).
Future<QuantityDiscountConfig> loadQuantityDiscountConfig({
  bool forceRefresh = false,
}) async {
  if (_loadedOnce && !forceRefresh) return _cachedConfig;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('quantity_discount')
        .get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      // توافق مع الإعداد القديم: pieces كان يخدم الحد وعدد التخفيض معاً
      final legacyPieces = data['pieces'];
      final legacy = _parsePositiveInt(
        legacyPieces,
        kDefaultQuantityDiscountPieces,
      );
      _cachedConfig = QuantityDiscountConfig(
        percent: _parsePercent(data['percent'], kDefaultQuantityDiscountPercent),
        minQuantity: _parsePositiveInt(
          data['minQuantity'] ?? legacyPieces,
          legacy,
        ),
        discountPieces: _parsePositiveInt(
          data['discountPieces'] ?? legacyPieces,
          legacy,
        ),
      );
    } else {
      _cachedConfig = const QuantityDiscountConfig();
    }
  } catch (e) {
    print('خطأ في جلب إعدادات تخفيض الكمية: $e');
    if (!_loadedOnce) {
      _cachedConfig = const QuantityDiscountConfig();
    }
  }
  _loadedOnce = true;
  return _cachedConfig;
}

/// مجموع السطر بعد تخفيض الكمية.
/// يُفعَّل إذا الكمية >= [minQuantity]، ويُطبَّق على [discountPieces] قطعة فقط.
int lineTotalWithQuantityDiscount({
  required int unitPrice,
  required int quantity,
  double? percent,
  int? minQuantity,
  int? discountPieces,
}) {
  if (quantity <= 0 || unitPrice <= 0) return 0;
  final p = percent ?? _cachedConfig.percent;
  final minQty = minQuantity ?? _cachedConfig.minQuantity;
  final applyOn = discountPieces ?? _cachedConfig.discountPieces;
  if (p <= 0 || minQty <= 0 || applyOn <= 0 || quantity < minQty) {
    return unitPrice * quantity;
  }
  final n = applyOn > quantity ? quantity : applyOn;
  final discountedUnit = (unitPrice * (100 - p) / 100).round();
  return discountedUnit * n + unitPrice * (quantity - n);
}

/// قيمة التوفير مقارنة بالسعر الكامل (0 إن لم ينطبق التخفيض).
int quantityDiscountSavings({
  required int unitPrice,
  required int quantity,
  double? percent,
  int? minQuantity,
  int? discountPieces,
}) {
  final full = unitPrice * quantity;
  final discounted = lineTotalWithQuantityDiscount(
    unitPrice: unitPrice,
    quantity: quantity,
    percent: percent,
    minQuantity: minQuantity,
    discountPieces: discountPieces,
  );
  final save = full - discounted;
  return save > 0 ? save : 0;
}

bool isQuantityDiscountApplied(int quantity, {int? minQuantity}) {
  final n = minQuantity ?? _cachedConfig.minQuantity;
  return quantity >= n && _cachedConfig.percent > 0;
}
