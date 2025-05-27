class SellerModel {
  final String id;
  final String userId;
  final String storeName;
  final String? storeDescription;
  final String? storeImageUrl;
  final String? phone;
  final String? address;
  final double? locationLat;
  final double? locationLng;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerModel({
    required this.id,
    required this.userId,
    required this.storeName,
    this.storeDescription,
    this.storeImageUrl,
    this.phone,
    this.address,
    this.locationLat,
    this.locationLng,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'],
      userId: json['user_id'],
      storeName: json['store_name'],
      storeDescription: json['store_description'],
      storeImageUrl: json['store_image_url'],
      phone: json['phone'],
      address: json['address'],
      locationLat: json['location_lat']?.toDouble(),
      locationLng: json['location_lng']?.toDouble(),
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'store_name': storeName,
      'store_description': storeDescription,
      'store_image_url': storeImageUrl,
      'phone': phone,
      'address': address,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'is_verified': isVerified,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
