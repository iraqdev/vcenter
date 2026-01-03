// To parse this JSON data, do
//
//     final bill = billFromJson(jsonString);

import 'dart:convert';

List<Bill> billFromJson(String str) => List<Bill>.from(json.decode(str).map((x) => Bill.fromJson(x)));

String billToJson(List<Bill> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Bill {
  int id;
  String name;
  String phone;
  String city;
  String address;
  int status;
  String date;
  int price;
  int delivery;
  int userId;
  String? nearpoint;
  String? note;
  String? orderstatus; // حالة الطلب الجديدة
  List<Map<String, dynamic>>? items; // تفاصيل المنتجات
  String? closestBranch; // الفرع الأقرب: الغزالية، الزعفرانية، الاعظمية، العراق
  String? deliveryTime; // وقت التوصيل المتوقع

  Bill({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    required this.status,
    required this.date,
    required this.price,
    required this.delivery,
    required this.userId,
    required this.nearpoint,
    required this.note,
    this.orderstatus,
    this.items,
    this.closestBranch,
    this.deliveryTime,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: _parseInt(json["id"]),
    name: json["name"] ?? '',
    phone: json["phone"] ?? '',
    city: json["city"] ?? '',
    address: json["address"] ?? '',
    status: _parseInt(json["status"]),
    date: json["date"] ?? '',
    price: _parseInt(json["price"]),
    delivery: _parseInt(json["delivery"]),
    userId: _parseInt(json["user_id"]),
    nearpoint: json["nearpoint"],
    note: json["note"],
    orderstatus: json["orderstatus"],
    items: json["items"] != null ? List<Map<String, dynamic>>.from(json["items"]) : null,
    closestBranch: json["closestBranch"],
    deliveryTime: json["deliveryTime"],
  );

  // دالة مساعدة لتحويل String إلى int بأمان
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "city": city,
    "address": address,
    "status": status,
    "date": date,
    "price": price,
    "delivery": delivery,
    "user_id": userId,
    "nearpoint": nearpoint,
    "note": note,
    "orderstatus": orderstatus,
    "items": items,
    "closestBranch": closestBranch,
    "deliveryTime": deliveryTime,
  };
}
