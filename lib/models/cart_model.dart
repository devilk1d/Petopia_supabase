import 'product_model.dart';

class CartModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final String? variant;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined product data
  final ProductModel? product;

  CartModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.variant,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      variant: json['variant'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'variant': variant,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}