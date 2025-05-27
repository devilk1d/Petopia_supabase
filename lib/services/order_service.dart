// lib/services/order_service.dart
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/cart_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'cart_service.dart';
import 'promo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  static final _client = SupabaseConfig.client;

  // Create order from cart
  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethodId,
    required String shippingMethodId,
    String? promoCode,
    String? notes,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Get cart items
      final cartItems = await CartService.getCartItems();
      if (cartItems.isEmpty) throw Exception('Cart is empty');

      // Calculate totals
      double subtotal = 0;
      double discountAmount = 0;
      String? promoId;

      for (var item in cartItems) {
        final price = item['price'] as double;
        final quantity = item['quantity'] as int;
        subtotal += price * quantity;
      }

      // Apply promo if provided
      if (promoCode != null && promoCode.isNotEmpty) {
        final promo = await PromoService.validatePromoCode(promoCode, subtotal);
        if (promo != null) {
          discountAmount = promo.calculateDiscount(subtotal);
          promoId = promo.id;
        }
      }

      // Get shipping cost
      final shippingCost = await _getShippingCost(shippingMethodId);

      final totalAmount = subtotal - discountAmount + shippingCost;

      // Create order
      final orderResponse = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'total_amount': totalAmount,
            'shipping_cost': shippingCost,
            'discount_amount': discountAmount,
            'promo_id': promoId,
            'payment_method_id': paymentMethodId,
            'shipping_method_id': shippingMethodId,
            'shipping_address': shippingAddress,
            'notes': notes,
            'status': 'pending_payment',
            'payment_status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Create order items
      for (var cartItem in cartItems) {
        await _client
            .from('order_items')
            .insert({
              'order_id': orderId,
              'product_id': cartItem['product_id'],
              'seller_id': cartItem['seller_id'],
              'quantity': cartItem['quantity'],
              'price': cartItem['price'],
              'variant': cartItem['variant'] ?? '',
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      // Use promo code if applied
      if (promoId != null) {
        await PromoService.usePromoCode(promoId);
      }

      // Clear cart after successful order
      await CartService.clearCart();

      return orderResponse;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get user orders
  static Future<List<Map<String, dynamic>>> getUserOrders({
    String? status,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      var query = _client
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              products (
                id,
                name,
                price,
                images,
                seller_id,
                sellers (
                  id,
                  store_name,
                  store_image_url
                )
              )
            )
          ''')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final List<dynamic> response = await query
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return response.map((order) {
        if (order['order_items'] != null) {
          order['order_items'] = (order['order_items'] as List).map((item) {
            final product = item['products'];
            final seller = product['sellers'];
            
            return {
              'id': item['id'],
              'order_id': item['order_id'],
              'product_id': item['product_id'],
              'seller_id': item['seller_id'],
              'quantity': item['quantity'],
              'price': (item['price'] as num).toDouble(),
              'variant': item['variant'] ?? '',
              'product': {
                'id': product['id'],
                'name': product['name'],
                'price': (product['price'] as num).toDouble(),
                'image_url': (product['images'] as List).isNotEmpty ? product['images'][0] : null,
                'seller_id': product['seller_id'],
                'seller_store_name': seller['store_name'],
                'seller_store_image': seller['store_image_url'],
              },
            };
          }).toList();
        }
        return order as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return null;

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              products (
                id,
                name,
                price,
                images,
                seller_id,
                sellers (
                  id,
                  store_name,
                  store_image_url
                )
              )
            )
          ''')
          .eq('id', orderId)
          .eq('user_id', userId)
          .single();

      if (response == null) return null;

      // Process order items
      if (response['order_items'] != null) {
        response['order_items'] = (response['order_items'] as List).map((item) {
          final product = item['products'];
          final seller = product['sellers'];
          
          return {
            'id': item['id'],
            'order_id': item['order_id'],
            'product_id': item['product_id'],
            'seller_id': item['seller_id'],
            'quantity': item['quantity'],
            'price': (item['price'] as num).toDouble(),
            'variant': item['variant'] ?? '',
            'product': {
              'id': product['id'],
              'name': product['name'],
              'price': (product['price'] as num).toDouble(),
              'image_url': (product['images'] as List).isNotEmpty ? product['images'][0] : null,
              'seller_id': product['seller_id'],
              'seller_store_name': seller['store_name'],
              'seller_store_image': seller['store_image_url'],
            },
          };
        }).toList();
      }

      return response;
    } catch (e) {
      return null;
    }
  }

  // Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _client
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Update payment status
  static Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      Map<String, dynamic> updateData = {'payment_status': paymentStatus};

      // If payment is confirmed, update order status to processing
      if (paymentStatus == 'paid') {
        updateData['status'] = 'processing';
      }

      await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Add tracking number
  static Future<void> addTrackingNumber(String orderId, String trackingNumber) async {
    try {
      await _client
          .from('orders')
          .update({
            'tracking_number': trackingNumber,
            'status': 'shipped',
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to add tracking number: $e');
    }
  }

  // Confirm order received
  static Future<void> confirmOrderReceived(String orderId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      await _client
          .from('orders')
          .update({'status': 'delivered'})
          .eq('id', orderId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to confirm order received: $e');
    }
  }

  // Get orders by seller
  static Future<List<OrderModel>> getOrdersBySeller(String sellerId) async {
    try {
      final response = await _client
          .from('order_items')
          .select('''
            *,
            orders!inner(*),
            products(*)
          ''')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      // Group by order_id and convert to OrderModel
      Map<String, Map<String, dynamic>> ordersMap = {};

      for (var item in response) {
        final orderId = item['orders']['id'];
        if (!ordersMap.containsKey(orderId)) {
          ordersMap[orderId] = {
            ...item['orders'],
            'order_items': [],
          };
        }
        ordersMap[orderId]!['order_items'].add(item);
      }

      return ordersMap.values
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch seller orders: $e');
    }
  }

  // Get payment methods
  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _client
          .from('payment_methods')
          .select()
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch payment methods: $e');
    }
  }

  // Get shipping methods
  static Future<List<Map<String, dynamic>>> getShippingMethods() async {
    try {
      final response = await _client
          .from('shipping_methods')
          .select()
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch shipping methods: $e');
    }
  }

  // Get shipping cost from shipping_methods table
  static Future<double> _getShippingCost(String shippingMethodId) async {
    try {
      final response = await _client
          .from('shipping_methods')
          .select('base_cost')
          .eq('id', shippingMethodId)
          .single();
      
      return (response['base_cost'] as num).toDouble();
    } catch (e) {
      return 15000.0; // Default shipping cost if error
    }
  }
}