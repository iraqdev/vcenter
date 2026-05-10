class CustomerRequestModel {
  final String id;
  final String name;
  final String phone;
  final String areaOrGovernorate;
  final String requestDetails;
  final String email;
  final DateTime createdAt;

  CustomerRequestModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.areaOrGovernorate,
    required this.requestDetails,
    required this.email,
    required this.createdAt,
  });

  factory CustomerRequestModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return CustomerRequestModel(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      areaOrGovernorate: data['areaOrGovernorate'] ?? '',
      requestDetails: data['requestDetails'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as dynamic?)?.toDate() ?? DateTime.now(),
    );
  }
}
