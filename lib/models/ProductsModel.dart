// To parse this JSON data, do
//
//     final productModel = productModelFromJson(jsonString);

import 'dart:convert';

ProductModel productModelFromJson(String str) => ProductModel.fromJson(json.decode(str));

String productModelToJson(ProductModel data) => json.encode(data.toJson());

class ProductModel {
  int id;
  String title;
  int price;
  String image;
  String description;
  int category;
  List<String> images;
  Map<String, String>? branchMessages; // رسائل خاصة بكل فرع

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.description,
    required this.category,
    required this.images,
    this.branchMessages,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json["id"],
    title: json["title"],
    price: json["price"],
    image: json["image"],
    description: json["description"],
    category: json["category"],
    images: List<String>.from(json["images"].map((x) => x)),
    branchMessages: json["branchMessages"] != null 
        ? Map<String, String>.from(json["branchMessages"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "price": price,
    "image": image,
    "description": description,
    "category": category,
    "images": List<dynamic>.from(images.map((x) => x)),
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
