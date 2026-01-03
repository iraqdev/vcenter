class SubCategoryModel {
  final String id;
  final String title;
  final int category; // الفئة الرئيسية
  final int originalId;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubCategoryModel({
    required this.id,
    required this.title,
    required this.category,
    required this.originalId,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  // تحويل من Firebase Document
  factory SubCategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SubCategoryModel(
      id: id,
      title: data['title'] ?? '',
      category: data['category'] is String ? int.tryParse(data['category']) ?? 0 : data['category'] ?? 0,
      originalId: data['originalId'] is String ? int.tryParse(data['originalId']) ?? 0 : data['originalId'] ?? 0,
      active: data['active'] ?? true,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  // تحويل إلى Map للـ Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'originalId': originalId,
      'active': active,
      'createdAt': createdAt ?? DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  // نسخ مع تعديلات
  SubCategoryModel copyWith({
    String? id,
    String? title,
    int? category,
    int? originalId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubCategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      originalId: originalId ?? this.originalId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SubCategoryModel(id: $id, title: $title, category: $category, originalId: $originalId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubCategoryModel &&
        other.id == id &&
        other.title == title &&
        other.category == category &&
        other.originalId == originalId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ category.hashCode ^ originalId.hashCode;
  }
}
