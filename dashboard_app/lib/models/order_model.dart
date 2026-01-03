class OrderModel {
  // دوال مساعدة لتحويل الأنواع
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  final String id;
  final String userPhone;
  final String name;
  final String address;
  final String city;
  final String near;
  final String nearpoint;
  final List<OrderItem> items;
  final double price;
  final String orderstatus; // 'جاري التجهيز', 'جاري التوصيل', 'تم الاستلام', 'ملغي'
  final int status; // 0 = جاري التجهيز, 1 = جاري التوصيل, 2 = تم الاستلام, 3 = ملغي
  final int delivery;
  final String? note;
  final int originalId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? closestBranch; // الفرع الأقرب: الغزالية، الزعفرانية، الاعظمية، العراق
  final String? deliveryTime; // وقت التوصيل المتوقع

  OrderModel({
    required this.id,
    required this.userPhone,
    required this.name,
    required this.address,
    required this.city,
    required this.near,
    required this.nearpoint,
    required this.items,
    required this.price,
    required this.orderstatus,
    required this.status,
    required this.delivery,
    this.note,
    required this.originalId,
    required this.createdAt,
    this.updatedAt,
    this.closestBranch,
    this.deliveryTime,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      userPhone: data['phone'] ?? data['user_phone'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      near: data['near'] ?? '',
      nearpoint: data['nearpoint'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item))
          .toList() ?? [],
      price: _parseDouble(data['price']),
      orderstatus: data['orderstatus'] ?? 'جاري التجهيز',
      status: _parseInt(data['status']),
      delivery: _parseInt(data['delivery']),
      note: data['note'],
      originalId: _parseInt(data['originalId']),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate()
          : null,
      closestBranch: data['closestBranch'],
      deliveryTime: data['deliveryTime'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phone': userPhone,
      'user_phone': userPhone,
      'name': name,
      'address': address,
      'city': city,
      'near': near,
      'nearpoint': nearpoint,
      'items': items.map((item) => item.toMap()).toList(),
      'price': price,
      'orderstatus': orderstatus,
      'status': status,
      'delivery': delivery,
      'note': note,
      'originalId': originalId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'closestBranch': closestBranch,
      'deliveryTime': deliveryTime,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userPhone,
    String? name,
    String? address,
    String? city,
    String? near,
    String? nearpoint,
    List<OrderItem>? items,
    double? price,
    String? orderstatus,
    int? status,
    int? delivery,
    String? note,
    int? originalId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? closestBranch,
    String? deliveryTime,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userPhone: userPhone ?? this.userPhone,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      near: near ?? this.near,
      nearpoint: nearpoint ?? this.nearpoint,
      items: items ?? this.items,
      price: price ?? this.price,
      orderstatus: orderstatus ?? this.orderstatus,
      status: status ?? this.status,
      delivery: delivery ?? this.delivery,
      note: note ?? this.note,
      originalId: originalId ?? this.originalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closestBranch: closestBranch ?? this.closestBranch,
      deliveryTime: deliveryTime ?? this.deliveryTime,
    );
  }

  // دوال مساعدة للحالة
  bool get isPreparing => status == 0; // جاري التجهيز
  bool get isDelivering => status == 1; // جاري التوصيل
  bool get isDelivered => status == 2; // تم الاستلام
  bool get isCancelled => status == 3; // ملغي

  String get statusText {
    return orderstatus; // استخدام النص العربي المباشر من Firebase
  }

  String get statusColor {
    switch (status) {
      case 0:
        return 'orange';
      case 1:
        return 'blue';
      case 2:
        return 'purple';
      case 3:
        return 'green';
      case 4:
        return 'red';
      default:
        return 'grey';
    }
  }

  String get formattedTotalAmount {
    return '${price.toStringAsFixed(0)} د.ع';
  }

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}

class OrderItem {
  final int id;
  final String title;
  final String image;
  final double price;
  final int count;
  final String color;
  final String size;

  OrderItem({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    required this.count,
    required this.color,
    required this.size,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      count: map['count'] ?? 1,
      color: map['color'] ?? '',
      size: map['size'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'price': price,
      'count': count,
      'color': color,
      'size': size,
    };
  }

  // حساب السعر الإجمالي للعنصر
  double get totalPrice => price * count;
}