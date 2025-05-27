class ProductModel {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final double discountPercentage;
  final int stock;
  final List<String> images;
  final dynamic variants;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? categoryName;
  final String? sellerStoreName;
  final String? sellerStoreImage;

  ProductModel({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.discountPercentage = 0,
    required this.stock,
    required this.images,
    this.variants,
    this.rating = 0,
    this.reviewCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.sellerStoreName,
    this.sellerStoreImage,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      sellerId: json['seller_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null ? (json['original_price'] as num).toDouble() : null,
      discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      variants: json['variants'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      categoryName: json['category_name'],
      sellerStoreName: json['seller_store_name'],
      sellerStoreImage: json['seller_store_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'discount_percentage': discountPercentage,
      'stock': stock,
      'images': images,
      'variants': variants,
      'rating': rating,
      'review_count': reviewCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'seller_store_name': sellerStoreName,
      'seller_store_image': sellerStoreImage,
    };
  }
}