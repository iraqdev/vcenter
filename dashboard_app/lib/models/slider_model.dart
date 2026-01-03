import 'package:cloud_firestore/cloud_firestore.dart';

class SliderModel {
  final String id;
  final String title;
  final String image;
  final bool active;
  final int? originalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SliderModel({
    required this.id,
    required this.title,
    required this.image,
    this.active = true,
    this.originalId,
    this.createdAt,
    this.updatedAt,
  });

  // تحويل من Firebase Document
  factory SliderModel.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      return SliderModel(
        id: id,
        title: data['title']?.toString() ?? '',
        image: data['image']?.toString() ?? '',
        active: data['active'] is bool ? data['active'] : true,
        originalId: data['originalId'] is int ? data['originalId'] : null,
        createdAt: data['createdAt'] is Timestamp ? data['createdAt'].toDate() : null,
        updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'].toDate() : null,
      );
    } catch (e) {
      print('❌ خطأ في تحويل SliderModel: $e');
      print('📊 البيانات: $data');
      rethrow;
    }
  }

  // تحويل إلى Firebase Document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'image': image,
      'active': active,
      'originalId': originalId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // نسخ مع تعديلات
  SliderModel copyWith({
    String? id,
    String? title,
    String? image,
    bool? active,
    int? originalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SliderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      active: active ?? this.active,
      originalId: originalId ?? this.originalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SliderModel(id: $id, title: $title, image: $image, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SliderModel &&
        other.id == id &&
        other.title == title &&
        other.image == image &&
        other.active == active;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ image.hashCode ^ active.hashCode;
  }
}
