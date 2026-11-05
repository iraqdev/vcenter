import '../models/order_model.dart';

/// بيانات الموقع/العنوان كما تُعرض في الداشبورد.
class OrderLocationInfo {
  final String governorate;
  final String regionOrDetails;
  final String landmark;
  final bool isCustomerOrder;

  const OrderLocationInfo({
    this.governorate = '',
    this.regionOrDetails = '',
    this.landmark = '',
    this.isCustomerOrder = false,
  });

  bool get hasContent =>
      governorate.isNotEmpty || regionOrDetails.isNotEmpty || landmark.isNotEmpty;

  /// سطر العنوان الرئيسي: المحافظة — المنطقة
  String get cardPrimary {
    if (governorate.isNotEmpty &&
        regionOrDetails.isNotEmpty &&
        regionOrDetails != governorate) {
      return '$governorate — $regionOrDetails';
    }
    if (governorate.isNotEmpty) return governorate;
    return regionOrDetails;
  }

  /// أقرب نقطة دالة في البطاقة.
  String? get cardLandmark => landmark.isNotEmpty ? landmark : null;

  String get primaryLabel => 'المحافظة';

  String? get secondaryLabel {
    if (regionOrDetails.isEmpty || regionOrDetails == governorate) return null;
    return 'المنطقة';
  }

  String? get secondaryValue {
    if (secondaryLabel == null) return null;
    return regionOrDetails;
  }

  String? get landmarkLabel => landmark.isNotEmpty ? 'أقرب نقطة دالة' : null;
}

OrderLocationInfo orderLocationInfo(OrderModel order) {
  final landmark = order.nearpoint.trim().isNotEmpty
      ? order.nearpoint.trim()
      : order.near.trim();
  return OrderLocationInfo(
    governorate: order.city.trim(),
    regionOrDetails: order.address.trim(),
    landmark: landmark,
    isCustomerOrder: order.isCustomerOrder,
  );
}

/// للتوافق مع الاستدعاءات القديمة — يعيد السطر الرئيسي فقط.
String formatOrderLocation(String city, String address, {bool isCustomerOrder = false}) {
  return OrderLocationInfo(
    governorate: city.trim(),
    regionOrDetails: address.trim(),
    isCustomerOrder: isCustomerOrder,
  ).cardPrimary;
}
