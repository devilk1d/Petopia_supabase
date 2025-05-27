import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String sellerId;
  final int quantity;
  final double price;
  final String? variant;
  final DateTime createdAt;
  final String? productName;
  final String? productImage;
  final String? storeName;

  // Joined data
  final ProductModel? product;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.sellerId,
    required this.quantity,
    required this.price,
    this.variant,
    required this.createdAt,
    this.productName,
    this.productImage,
    this.storeName,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      sellerId: json['seller_id'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      variant: json['variant'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      productName: json['product_name'] as String?,
      productImage: json['product_image'] as String?,
      storeName: json['store_name'] as String?,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'seller_id': sellerId,
      'quantity': quantity,
      'price': price,
      'variant': variant,
      'created_at': createdAt.toIso8601String(),
      'product_name': productName,
      'product_image': productImage,
      'store_name': storeName,
    };
  }
}