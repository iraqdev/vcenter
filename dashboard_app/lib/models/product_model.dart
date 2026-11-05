class ProductModel {
  final String id;
  final String title;
  final String description;
  final int price; // سعر المتجر
  final int? customerPrice; // سعر الزبون
  final String image; // الصورة الرئيسية (للتوافق مع النظام القديم)
  final List<String> images; // قائمة الصور المتعددة
  final int category;
  final bool active;
  final int? originalId;
  final Map<String, dynamic>? additionalInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, String>? branchMessages; // رسائل خاصة بكل فرع
  final String? branch; // الفرع الذي ينتمي إليه المنتج (الغزالية، الزعفرانية، الاعظمية، العراق)
  final String? brand; // العلامة التجارية
  final String? logo; // شعار المنتج
  final String? logoBrand; // شعار العلامة التجارية
  final String? model; // موديل المنتج
  final int? subCategory; // الفئة الفرعية
  final Map<String, dynamic>? posLink; // ربط مادة سطح المكتب (DNZTeamPOS)
  final double? stock; // كمية المخزون من POS
  /// ظهور للمتجر — المنتجات القديمة بدون الحقل = true
  final bool showForStore;
  /// ظهور للزبون — المنتجات القديمة بدون الحقل = false
  final bool showForCustomer;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.customerPrice,
    required this.image,
    this.images = const [],
    required this.category,
    this.active = true,
    this.originalId,
    this.additionalInfo,
    this.createdAt,
    this.updatedAt,
    this.branchMessages,
    this.branch,
    this.brand,
    this.logo,
    this.logoBrand,
    this.model,
    this.subCategory,
    this.posLink,
    this.stock,
    this.showForStore = true,
    this.showForCustomer = true,
  });

  // تحويل من Firebase Document
  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    // معالجة الصور المتعددة
    List<String> images = [];
    if (data['images'] != null && data['images'] is List) {
      images = List<String>.from(data['images']);
    } else if (data['image'] != null && data['image'].toString().isNotEmpty) {
      // إذا لم تكن هناك صور متعددة، استخدم الصورة الرئيسية
      images = [data['image'].toString()];
    }

    // معالجة رسائل الفروع
    Map<String, String>? branchMessages;
    if (data['branchMessages'] != null && data['branchMessages'] is Map) {
      branchMessages = Map<String, String>.from(data['branchMessages']);
    }

    Map<String, dynamic>? posLink;
    if (data['posLink'] != null && data['posLink'] is Map) {
      posLink = Map<String, dynamic>.from(data['posLink'] as Map);
    }

    return ProductModel(
      id: id,
      title: data['title'] ?? data['name'] ?? 'منتج بدون اسم',
      description: data['description'] ?? '',
      price: _toInt(data['price']) ?? 0,
      customerPrice: _toInt(data['customerPrice']),
      image: data['image'] ?? '',
      images: images,
      category: data['category'] is String ? int.tryParse(data['category']) ?? 0 : data['category'] ?? 0,
      active: data['active'] ?? true,
      originalId: data['originalId'],
      additionalInfo: data,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      branchMessages: branchMessages,
      branch: data['branch'],
      brand: data['brand'],
      logo: data['logo'],
      logoBrand: data['logoBrand'],
      model: data['model'],
      subCategory: data['subCategory'] is String ? int.tryParse(data['subCategory']) : data['subCategory'],
      posLink: posLink,
      stock: _toDoubleOrNull(data['stock'] ?? posLink?['balance']),
      // بدون الحقل = يظهر للمتجر والزبون
      showForStore: data['showForStore'] is bool ? data['showForStore'] as bool : true,
      showForCustomer: data['showForCustomer'] is bool ? data['showForCustomer'] as bool : true,
    );
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  // تحويل إلى Map للـ Firebase (بدون null — Firestore update يرفض null)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      if (customerPrice != null) 'customerPrice': customerPrice,
      'image': image,
      'images': images,
      'category': category,
      'active': active,
      'originalId': originalId,
      'branchMessages': branchMessages ?? {},
      'branch': branch ?? '',
      'brand': brand ?? '',
      'logo': logo ?? '',
      'logoBrand': logoBrand ?? '',
      'model': model ?? '',
      if (subCategory != null) 'subCategory': subCategory,
      if (posLink != null) 'posLink': posLink,
      if (stock != null) 'stock': stock,
      'showForStore': showForStore,
      'showForCustomer': showForCustomer,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  // نسخ مع تعديلات
  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    int? price,
    int? customerPrice,
    String? image,
    List<String>? images,
    int? category,
    bool? active,
    int? originalId,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? branchMessages,
    String? branch,
    String? brand,
    String? logo,
    String? logoBrand,
    String? model,
    int? subCategory,
    Map<String, dynamic>? posLink,
    double? stock,
    bool? showForStore,
    bool? showForCustomer,
    bool clearPosLink = false,
    bool clearStock = false,
    bool clearCustomerPrice = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      customerPrice: clearCustomerPrice
          ? null
          : (customerPrice ?? this.customerPrice),
      image: image ?? this.image,
      images: images ?? this.images,
      category: category ?? this.category,
      active: active ?? this.active,
      originalId: originalId ?? this.originalId,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      branchMessages: branchMessages ?? this.branchMessages,
      branch: branch ?? this.branch,
      brand: brand ?? this.brand,
      logo: logo ?? this.logo,
      logoBrand: logoBrand ?? this.logoBrand,
      model: model ?? this.model,
      subCategory: subCategory ?? this.subCategory,
      posLink: clearPosLink ? null : (posLink ?? this.posLink),
      stock: clearStock ? null : (stock ?? this.stock),
      showForStore: showForStore ?? this.showForStore,
      showForCustomer: showForCustomer ?? this.showForCustomer,
    );
  }

  bool get isPosLinked => posItemCode != null;

  int? get posItemCode {
    final code = posLink?['itemCode'];
    if (code is int) return code;
    if (code is num) return code.toInt();
    return int.tryParse('$code');
  }

  String? get posItemName => posLink?['itemName']?.toString();

  // تنسيق السعر
  String get formattedPrice {
    return '$price د.ع';
  }

  /// سعر الزبون المعروض: مخصص إن وُجد، وإلا أساسي + 4000
  int get effectiveCustomerPrice =>
      customerPrice ?? (price + 4000);

  bool get hasCustomCustomerPrice => customerPrice != null;

  String get formattedCustomerPrice {
    return '$effectiveCustomerPrice د.ع';
  }

  String get audienceLabel {
    if (showForStore && showForCustomer) return 'متجر + زبون';
    if (showForCustomer) return 'زبون فقط';
    if (showForStore) return 'متجر فقط';
    return 'مخفي';
  }

  // حالة المنتج
  String get statusText {
    if (!active) return 'غير نشط';
    return 'نشط';
  }

  // لون حالة المنتج
  String get statusColor {
    if (!active) return 'red';
    return 'green';
  }

  // الحصول على الصورة الرئيسية
  String get mainImage {
    if (images.isNotEmpty) {
      return images.first;
    }
    return image;
  }

  // الحصول على جميع الصور
  List<String> get allImages {
    if (images.isNotEmpty) {
      return images;
    }
    if (image.isNotEmpty) {
      return [image];
    }
    return [];
  }

  // التحقق من وجود صور
  bool get hasImages {
    return allImages.isNotEmpty;
  }

  // عدد الصور
  int get imagesCount {
    return allImages.length;
  }

  // الحصول على رسالة الفرع
  String? getBranchMessage(String branch) {
    if (branchMessages == null) return null;
    return branchMessages![branch];
  }

  // هل يوجد رسالة للفرع
  bool hasBranchMessage(String branch) {
    return getBranchMessage(branch) != null && getBranchMessage(branch)!.isNotEmpty;
  }
}
