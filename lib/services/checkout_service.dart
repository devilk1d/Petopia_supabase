import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'supabase_config.dart';

class CheckoutService {
  static final _client = SupabaseConfig.client;

  // Get payment methods
  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _client
          .from('payment_methods')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List).map((item) => 
        Map<String, dynamic>.from(item as Map)
      ).toList();
    } catch (e) {
      print('Error fetching payment methods: $e');
      return [];
    }
  }

  // Get user's default shipping address
  static Future<Map<String, dynamic>?> getDefaultShippingAddress(String userId) async {
    try {
      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .single();

      return response != null ? Map<String, dynamic>.from(response as Map) : null;
    } catch (e) {
      print('Error fetching default address: $e');
      return null;
    }
  }

  // Calculate shipping cost (dummy implementation for now)
  static Future<double> calculateShippingCost(List<OrderItemModel> items) async {
    // In a real implementation, this would calculate based on:
    // - Item weight
    // - Shipping distance
    // - Selected courier
    // For now, return a fixed cost
    return 23000.0;
  }

  // Create new order
  static Future<OrderModel> createOrder({
    required String userId,
    required List<OrderItemModel> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethodId,
    String? promoId,
    String? notes,
  }) async {
    try {
      // Calculate totals
      double subtotal = items.fold(0, (sum, item) => sum + (item.price * item.quantity));
      double shippingCost = await calculateShippingCost(items);
      double discountAmount = 0; // Implement promo calculation if needed
      double totalAmount = subtotal + shippingCost - discountAmount;

      // Generate order number (simple implementation)
      String orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      // Create order in database
      final response = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'order_number': orderNumber,
            'total_amount': totalAmount,
            'shipping_cost': shippingCost,
            'discount_amount': discountAmount,
            'promo_id': promoId,
            'payment_method_id': paymentMethodId,
            'shipping_address': shippingAddress,
            'status': 'pending_payment',
            'payment_status': 'pending',
            'notes': notes,
          })
          .select()
          .single();

      // Create order items
      final orderItems = await Future.wait(
        items.map((item) async {
          final itemResponse = await _client
              .from('order_items')
              .insert({
                'order_id': response['id'],
                'product_id': item.productId,
                'seller_id': item.sellerId,
                'quantity': item.quantity,
                'price': item.price,
                'variant': item.variant,
              })
              .select()
              .single();

          return OrderItemModel.fromJson(itemResponse);
        }),
      );

      // Return complete order model
      return OrderModel.fromJson({
        ...response,
        'items': orderItems.map((item) => item.toJson()).toList(),
      });
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            items:order_items (
              *,
              product:products (
                name,
                image_url
              ),
              seller:sellers (
                store_name
              )
            )
          ''')
          .eq('id', orderId)
          .single();

      if (response == null) return null;

      // Process joined data
      if (response['items'] != null) {
        for (var item in response['items']) {
          item['product_name'] = item['product']?['name'];
          item['product_image'] = item['product']?['image_url'];
          item['store_name'] = item['seller']?['store_name'];
        }
      }

      return OrderModel.fromJson(response);
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }
} 