import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final double totalAmount;
  final double shippingCost;
  final double discountAmount;
  final String? promoId;
  final String? paymentMethodId;
  final String? shippingMethodId;
  final Map<String, dynamic> shippingAddress;
  final String status;
  final String paymentStatus;
  final String? trackingNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.totalAmount,
    required this.shippingCost,
    required this.discountAmount,
    this.promoId,
    this.paymentMethodId,
    this.shippingMethodId,
    required this.shippingAddress,
    required this.status,
    required this.paymentStatus,
    this.trackingNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderNumber: json['order_number'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      shippingCost: (json['shipping_cost'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      promoId: json['promo_id'] as String?,
      paymentMethodId: json['payment_method_id'] as String?,
      shippingMethodId: json['shipping_method_id'] as String?,
      shippingAddress: json['shipping_address'] as Map<String, dynamic>,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      trackingNumber: json['tracking_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'total_amount': totalAmount,
      'shipping_cost': shippingCost,
      'discount_amount': discountAmount,
      'promo_id': promoId,
      'payment_method_id': paymentMethodId,
      'shipping_method_id': shippingMethodId,
      'shipping_address': shippingAddress,
      'status': status,
      'payment_status': paymentStatus,
      'tracking_number': trackingNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String getStatusText() {
    switch (status) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'processing':
        return 'Dalam Proses';
      case 'waiting_shipment':
        return 'Menunggu Barang Dikirim';
      case 'shipped':
        return 'Sedang Dikirim';
      case 'delivered':
        return 'Diterima';
      default:
        return status;
    }
  }
}

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