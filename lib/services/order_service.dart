// lib/services/order_service.dart
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/cart_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'cart_service.dart';
import 'promo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../services/product_service.dart';

class OrderService {
  static final _client = SupabaseConfig.client;

  // Create order from cart
  static Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethodId,
    required String shippingMethodId,
    required List<Map<String, dynamic>> selectedItems,
    String? promoCode,
    String? notes,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Use selected items instead of all cart items
      if (selectedItems.isEmpty) throw Exception('No items selected');

      // Calculate totals
      double subtotal = 0;
      double discountAmount = 0;
      String? promoId;

      for (var item in selectedItems) {
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

      // Generate order number
      final random = Random();
      final randomNumber = random.nextInt(9000000) + 1000000; // 7 digit random
      final orderNumber = 'INV-$randomNumber';

      // Create order dengan explicit user_id
      final orderData = {
        'user_id': userId,
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'shipping_cost': shippingCost,
        'discount_amount': discountAmount,
        'payment_method_id': paymentMethodId,
        'shipping_method_id': shippingMethodId,
        'shipping_address': shippingAddress,
        'status': 'pending_payment',
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields if they exist
      if (promoId != null) orderData['promo_id'] = promoId;
      if (notes != null && notes.isNotEmpty) orderData['notes'] = notes;

      final orderResponse = await _client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Create order items and update product stock
      for (var cartItem in selectedItems) {
        // Create order item
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

        // Update product stock
        await ProductService.updateProductStock(
          cartItem['product_id'],
          cartItem['quantity'],
          variant: cartItem['variant'],
        );
      }

      // Use promo code if applied
      if (promoId != null) {
        await PromoService.usePromoCode(promoId);
      }

      // Remove only the ordered items from cart
      for (var cartItem in selectedItems) {
        await CartService.removeFromCart(cartItem['id']);
      }

      return orderResponse;
    } catch (e) {
      print('Order creation error: $e'); // For debugging

      // Handle specific database errors
      if (e.toString().contains('new row violates row-level security policy')) {
        throw Exception('Permission denied: Unable to create order. Please login again.');
      } else if (e.toString().contains('violates foreign key constraint')) {
        throw Exception('Invalid data: Some referenced data is missing.');
      } else if (e.toString().contains('violates check constraint')) {
        throw Exception('Invalid data: Please check your order details.');
      } else if (e.toString().contains('Insufficient stock')) {
        throw Exception('Some products have insufficient stock. Please check your cart.');
      } else {
        throw Exception('Failed to create order: $e');
      }
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
            payment_methods(id, name, type, logo_url),
            shipping_methods(id, name, type, logo_url),
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

  // Get order by ID with complete details
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return null;

      final response = await _client
          .from('orders')
          .select('''
            *,
            payment_methods(id, name, type, logo_url),
            shipping_methods(id, name, type, logo_url, base_cost),
            promos(id, code, title, discount_type, discount_value),
            order_items (
              *,
              products (
                id,
                name,
                price,
                images,
                description,
                seller_id,
                sellers (
                  id,
                  store_name,
                  store_image_url,
                  store_description
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
              'description': product['description'],
              'seller_id': product['seller_id'],
              'seller_store_name': seller['store_name'],
              'seller_store_image': seller['store_image_url'],
              'seller_store_description': seller['store_description'],
            },
          };
        }).toList();
      }

      return response;
    } catch (e) {
      print('Error fetching order by ID: $e');
      return null;
    }
  }

  // Update order status
  static Future<void> updateOrderStatus(String orderId, String status, String sellerId) async {
    try {
      // Get the order without joining order_items
      final order = await _client
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      if (order == null) {
        throw Exception('Order not found');
      }

      // Get order_items for this order
      final orderItems = await _client
          .from('order_items')
          .select('seller_id')
          .eq('order_id', orderId);

      bool isOrderFromSeller = (orderItems as List).any((item) => item['seller_id'] == sellerId);

      if (!isOrderFromSeller) {
        throw Exception('You are not authorized to update this order');
      }

      // Update the order status
      await _client
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Update payment status
  static Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      Map<String, dynamic> updateData = {
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If payment is confirmed, update order status to processing
      if (paymentStatus == 'paid') {
        updateData['status'] = 'processing';
      }

      await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .eq('user_id', userId);
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
        'updated_at': DateTime.now().toIso8601String(),
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
          .update({
        'status': 'delivered',
        'updated_at': DateTime.now().toIso8601String(),
      })
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

  // Get order statistics for user
  static Future<Map<String, int>> getOrderStatistics() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('orders')
          .select('status, payment_status')
          .eq('user_id', userId);

      Map<String, int> stats = {
        'total': 0,
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
      };

      for (var order in response) {
        stats['total'] = (stats['total'] ?? 0) + 1;

        final status = order['status'] as String;
        final paymentStatus = order['payment_status'] as String;

        if (paymentStatus == 'pending') {
          stats['pending'] = (stats['pending'] ?? 0) + 1;
        } else if (status == 'processing' || status == 'waiting_shipment') {
          stats['processing'] = (stats['processing'] ?? 0) + 1;
        } else if (status == 'shipped') {
          stats['shipped'] = (stats['shipped'] ?? 0) + 1;
        } else if (status == 'delivered') {
          stats['delivered'] = (stats['delivered'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
      };
    }
  }
}