class ProductModel {
  final String id;
  final String title;
  final String description;
  final int price;
  final String image; // الصورة الرئيسية (للتوافق مع النظام القديم)
  final List<String> images; // قائمة الصور المتعددة
  final int category;
  final bool active;
  final int? originalId;
  final Map<String, dynamic>? additionalInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, String>? branchMessages; // رسائل خاصة بكل فرع
  final String? brand; // العلامة التجارية
  final String? logo; // شعار المنتج
  final String? logoBrand; // شعار العلامة التجارية
  final String? model; // موديل المنتج
  final int? subCategory; // الفئة الفرعية

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.image,
    this.images = const [],
    required this.category,
    this.active = true,
    this.originalId,
    this.additionalInfo,
    this.createdAt,
    this.updatedAt,
    this.branchMessages,
    this.brand,
    this.logo,
    this.logoBrand,
    this.model,
    this.subCategory,
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

    return ProductModel(
      id: id,
      title: data['title'] ?? data['name'] ?? 'منتج بدون اسم',
      description: data['description'] ?? '',
      price: data['price'] is String ? int.tryParse(data['price']) ?? 0 : data['price'] ?? 0,
      image: data['image'] ?? '',
      images: images,
      category: data['category'] is String ? int.tryParse(data['category']) ?? 0 : data['category'] ?? 0,
      active: data['active'] ?? true,
      originalId: data['originalId'],
      additionalInfo: data,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      branchMessages: branchMessages,
      brand: data['brand'],
      logo: data['logo'],
      logoBrand: data['logoBrand'],
      model: data['model'],
      subCategory: data['subCategory'] is String ? int.tryParse(data['subCategory']) : data['subCategory'],
    );
  }

  // تحويل إلى Map للـ Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'image': image,
      'images': images,
      'category': category,
      'active': active,
      'originalId': originalId,
      'branchMessages': branchMessages ?? {},
      'brand': brand ?? '',
      'logo': logo ?? '',
      'logoBrand': logoBrand ?? '',
      'model': model ?? '',
      'subCategory': subCategory,
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
    String? image,
    List<String>? images,
    int? category,
    bool? active,
    int? originalId,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? branchMessages,
    String? brand,
    String? logo,
    String? logoBrand,
    String? model,
    int? subCategory,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      images: images ?? this.images,
      category: category ?? this.category,
      active: active ?? this.active,
      originalId: originalId ?? this.originalId,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      branchMessages: branchMessages ?? this.branchMessages,
      brand: brand ?? this.brand,
      logo: logo ?? this.logo,
      logoBrand: logoBrand ?? this.logoBrand,
      model: model ?? this.model,
      subCategory: subCategory ?? this.subCategory,
    );
  }

  // تنسيق السعر
  String get formattedPrice {
    return '$price د.ع';
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
