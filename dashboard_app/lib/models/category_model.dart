class CategoryModel {
  final String id;
  final String title;
  final String image;
  final int originalId;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.title,
    required this.image,
    required this.originalId,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      title: data['title'] ?? 'فئة بدون اسم',
      image: data['image'] ?? '',
      originalId: data['originalId'] ?? 0,
      active: data['active'] ?? true,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'image': image,
      'originalId': originalId,
      'active': active,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? title,
    String? image,
    int? originalId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      originalId: originalId ?? this.originalId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
