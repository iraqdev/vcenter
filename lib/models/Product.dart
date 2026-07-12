// To parse this JSON data, do
//
//     final product = productFromJson(jsonString);

import 'dart:convert';

List<Product> productFromJson(String str) =>
    List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

String productToJson(List<Product> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Product {
  int id;
  String title;
  int price;
  int? customerPrice;
  String description;
  String image;
  int category;
  Map<String, String>? branchMessages; // رسائل خاصة بكل فرع

  Product(
      {required this.id,
      required this.title,
      required this.price,
      this.customerPrice,
      required this.description,
      required this.image,
      required this.category,
      this.branchMessages});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"] is String ? int.parse(json["id"]) : json["id"],
        title: json["title"],
        price:
            json["price"] is String ? int.parse(json["price"]) : json["price"],
        customerPrice: json["customerPrice"] == null
            ? null
            : (json["customerPrice"] is String
                ? int.tryParse(json["customerPrice"])
                : json["customerPrice"] as int?),
        description: json["description"],
        image: json["image"],
        category: json["category"] is String
            ? int.parse(json["category"])
            : json["category"],
        branchMessages: json["branchMessages"] != null 
            ? Map<String, String>.from(json["branchMessages"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "price": price,
        "customerPrice": customerPrice,
        "description": description,
        "image": image,
        "category": category,
        "branchMessages": branchMessages,
      };

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
