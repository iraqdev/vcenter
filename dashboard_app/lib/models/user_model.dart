class UserModel {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String address;
  final String near;
  final int points;
  final bool isActive;
  final bool isReviewed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, double>? shopLocation;
  final String? profilePic;
  final String? shopPic;
  final String? playerId; // OneSignal Player ID
  final String? closestBranch; // الفرع الأقرب: الغزالية، الزعفرانية، الاعظمية، العراق

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    required this.near,
    required this.points,
    required this.isActive,
    required this.isReviewed,
    required this.createdAt,
    this.updatedAt,
    this.shopLocation,
    this.profilePic,
    this.shopPic,
    this.playerId,
    this.closestBranch,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      near: data['near'] ?? '',
      points: data['point'] ?? 0,
      isActive: (data['active'] == true || data['active'] == 1) ? true : false,
      isReviewed: data['isReviewed'] ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as dynamic).toDate() 
          : null,
      shopLocation: data['shopLocation'] != null 
          ? Map<String, double>.from(data['shopLocation'])
          : null,
      profilePic: data['profilePic'],
      shopPic: data['shopPic'],
      playerId: data['playerId'],
      closestBranch: data['closestBranch'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'city': city,
      'address': address,
      'near': near,
      'point': points,
      'active': isActive,
      'isReviewed': isReviewed,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'shopLocation': shopLocation,
      'profilePic': profilePic,
      'shopPic': shopPic,
      'playerId': playerId,
      'closestBranch': closestBranch,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? city,
    String? address,
    String? near,
    int? points,
    bool? isActive,
    bool? isReviewed,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, double>? shopLocation,
    String? profilePic,
    String? shopPic,
    String? playerId,
    String? closestBranch,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      near: near ?? this.near,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      isReviewed: isReviewed ?? this.isReviewed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shopLocation: shopLocation ?? this.shopLocation,
      profilePic: profilePic ?? this.profilePic,
      shopPic: shopPic ?? this.shopPic,
      playerId: playerId ?? this.playerId,
      closestBranch: closestBranch ?? this.closestBranch,
    );
  }
}
