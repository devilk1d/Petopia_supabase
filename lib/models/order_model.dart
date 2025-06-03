// File: lib/models/order_item_model.dart
class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String sellerId;
  final int quantity;
  final double price;
  final String variant;
  final DateTime createdAt;

  // Additional product information
  final String? productName;
  final String? productImage;
  final String? productDescription;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.sellerId,
    required this.quantity,
    required this.price,
    required this.variant,
    required this.createdAt,
    this.productName,
    this.productImage,
    this.productDescription,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return OrderItemModel(
        id: json['id'] as String? ?? '',
        orderId: json['order_id'] as String? ?? '',
        productId: json['product_id'] as String? ?? '',
        sellerId: json['seller_id'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        price: ((json['price'] as num?) ?? 0).toDouble(),
        variant: json['variant'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        productName: json['product_name'] as String?,
        productImage: json['product_image'] as String?,
        productDescription: json['product_description'] as String?,
      );
    } catch (e) {
      print('Error parsing OrderItemModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
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
      'product_description': productDescription,
    };
  }
}

// File: lib/models/order_model.dart
class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final double totalAmount;
  final double shippingCost;
  final double discountAmount;
  final String status;
  final String paymentStatus;
  final String? trackingNumber;
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
    required this.status,
    required this.paymentStatus,
    this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing OrderModel from JSON...');
      print('Order ID: ${json['id']}');
      print('Order Items Count: ${(json['order_items'] as List?)?.length ?? 0}');

      // Parse order items
      List<OrderItemModel> orderItems = [];
      if (json['order_items'] != null) {
        final itemsList = json['order_items'] as List;
        print('Processing ${itemsList.length} items');

        for (var i = 0; i < itemsList.length; i++) {
          try {
            final item = itemsList[i] as Map<String, dynamic>;
            print('Processing item $i: ${item['product_name']}');
            orderItems.add(OrderItemModel.fromJson(item));
          } catch (e) {
            print('Error parsing item $i: $e');
            print('Item data: ${itemsList[i]}');
            // Continue processing other items instead of failing completely
          }
        }
      }

      print('Successfully parsed ${orderItems.length} items');

      return OrderModel(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        orderNumber: json['order_number'] as String? ?? '',
        totalAmount: ((json['total_amount'] as num?) ?? 0).toDouble(),
        shippingCost: ((json['shipping_cost'] as num?) ?? 0).toDouble(),
        discountAmount: ((json['discount_amount'] as num?) ?? 0).toDouble(),
        status: json['status'] as String? ?? 'unknown',
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        trackingNumber: json['tracking_number'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        items: orderItems,
      );
    } catch (e) {
      print('Error parsing OrderModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'total_amount': totalAmount,
      'shipping_cost': shippingCost,
      'discount_amount': discountAmount,
      'status': status,
      'payment_status': paymentStatus,
      'tracking_number': trackingNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'order_items': items.map((item) => item.toJson()).toList(),
    };
  }
}