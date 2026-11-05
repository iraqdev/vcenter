class PosItemModel {
  final int itemCode;
  final String itemName;
  final String? barcode;
  final double balance;
  final String? unitName;
  final double? sellPrice;
  final double? costPrice;
  final int? categoryCode;
  final double? qtyMin;
  final String? kindName;
  final String? shelfName;
  final Map<String, dynamic> rawData;

  PosItemModel({
    required this.itemCode,
    required this.itemName,
    this.barcode,
    required this.balance,
    this.unitName,
    this.sellPrice,
    this.costPrice,
    this.categoryCode,
    this.qtyMin,
    this.kindName,
    this.shelfName,
    required this.rawData,
  });

  factory PosItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    final itemCode = _toInt(data['itemCode'] ?? id);
    return PosItemModel(
      itemCode: itemCode,
      itemName: data['itemName']?.toString() ?? '',
      barcode: _emptyToNull(data['barcode']?.toString()),
      balance: _toDouble(data['balance']),
      unitName: _emptyToNull(data['unitName']?.toString()),
      sellPrice: _toDoubleOrNull(data['sellPrice']),
      costPrice: _toDoubleOrNull(data['costPrice']),
      categoryCode: _toIntOrNull(data['categoryCode']),
      qtyMin: _toDoubleOrNull(data['qtyMin']),
      kindName: _emptyToNull(data['kindName']?.toString()),
      shelfName: _emptyToNull(data['shelfName']?.toString()),
      rawData: Map<String, dynamic>.from(data),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'barcode': barcode,
      'balance': balance,
      'unitName': unitName,
      'sellPrice': sellPrice,
      'costPrice': costPrice,
      'categoryCode': categoryCode,
      'qtyMin': qtyMin,
      'kindName': kindName,
      'shelfName': shelfName,
      ...rawData,
    };
  }

  /// يُحفظ داخل منتج التطبيق عند الربط.
  Map<String, dynamic> toPosLinkMap() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'barcode': barcode,
      'balance': balance,
      'unitName': unitName,
      'sellPrice': sellPrice,
      'costPrice': costPrice,
      'categoryCode': categoryCode,
      'qtyMin': qtyMin,
      'kindName': kindName,
      'shelfName': shelfName,
      'linkedAt': DateTime.now().toIso8601String(),
      'raw': rawData,
    };
  }

  String get displaySubtitle {
    final parts = <String>[
      'كود: $itemCode',
      if (barcode != null && barcode!.isNotEmpty) 'باركود: $barcode',
      'كمية: ${_formatQty(balance)}',
      if (unitName != null && unitName!.isNotEmpty) unitName!,
    ];
    return parts.join(' • ');
  }

  static String? _emptyToNull(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    final n = _toInt(v);
    return n == 0 && v.toString() != '0' ? null : n;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    return _toDouble(v);
  }

  static String _formatQty(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
