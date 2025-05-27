// lib/services/cart_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';
import 'dart:async';

class CartService {
  static final _client = SupabaseConfig.client;
  static StreamController<List<Map<String, dynamic>>>? _cartController;
  static RealtimeChannel? _cartSubscription;

  // Initialize real-time subscription
  static void initCartSubscription() {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) return;

    // Create stream controller if not exists
    _cartController ??= StreamController<List<Map<String, dynamic>>>.broadcast();

    // Cancel existing subscription if any
    _cartSubscription?.unsubscribe();

    // Subscribe to cart changes
    _cartSubscription = _client
        .channel('public:carts')
        .onPostgresChanges(
          schema: 'public',
          table: 'carts',
          event: PostgresChangeEvent.all,
          callback: (payload) async {
            final items = await getCartItems();
            _cartController?.add(items);
          },
        )
        ..subscribe();
  }

  // Get cart stream
  static Stream<List<Map<String, dynamic>>>? get cartStream => _cartController?.stream;

  // Dispose subscription
  static void dispose() {
    _cartSubscription?.unsubscribe();
    _cartController?.close();
    _cartController = null;
    _cartSubscription = null;
  }

  // Get cart items for current user
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('carts')
          .select('''
            *,
            products (
              id,
              name,
              price,
              images,
              seller_id,
              variants,
              sellers (
                id,
                store_name,
                store_image_url
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final items = (response as List).map((item) {
        final product = item['products'];
        final seller = product['sellers'];
        final variants = product['variants'];
        
        // Calculate the price based on variant if it exists
        double price = product['price'].toDouble();
        if (item['variant'] != null && 
            item['variant'].isNotEmpty && 
            variants != null &&
            variants is Map<String, dynamic> &&
            variants.containsKey('name') &&
            variants.containsKey('price')) {
          final variantNames = variants['name'] as List;
          final variantPrices = variants['price'] as List;
          final variantIndex = variantNames.indexOf(item['variant']);
          if (variantIndex != -1) {
            price = double.parse(variantPrices[variantIndex].toString());
          }
        }
        
        return {
          'id': item['id'],
          'product_id': product['id'],
          'seller_id': product['seller_id'],
          'name': product['name'],
          'price': price,
          'image': product['images'] != null && (product['images'] as List).isNotEmpty 
              ? product['images'][0] 
              : null,
          'quantity': item['quantity'],
          'variant': item['variant'] ?? '',
          'store_name': seller['store_name'],
          'storeIcon': seller['store_image_url'],
        };
      }).toList();

      // Update stream with new items
      _cartController?.add(items);
      return items;
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  // Add item to cart
  static Future<void> addToCart({
    required String productId,
    required int quantity,
    String? variant,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Check if item already exists in cart
      final existing = await _client
          .from('carts')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('variant', variant ?? '')
          .maybeSingle();

      if (existing != null) {
        // Update quantity if item exists
        await _client
            .from('carts')
            .update({
              'quantity': existing['quantity'] + quantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Add new item if it doesn't exist
        await _client.from('carts').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'variant': variant ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Refresh cart items after adding
      await getCartItems();
    } catch (e) {
      print('Error adding item to cart: $e');
      rethrow;
    }
  }

  // Update cart item quantity
  static Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      await _client
          .from('carts')
          .update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', itemId);
    } catch (e) {
      print('Error updating cart item quantity: $e');
      rethrow;
    }
  }

  // Remove item from cart
  static Future<void> removeFromCart(String itemId) async {
    try {
      await _client
          .from('carts')
          .delete()
          .eq('id', itemId);
    } catch (e) {
      print('Error removing item from cart: $e');
      rethrow;
    }
  }

  // Clear cart
  static Future<void> clearCart() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      await _client
          .from('carts')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  // Get cart item count
  static Future<int> getCartItemCount() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return 0;

      final response = await _client
          .from('carts')
          .select('quantity')
          .eq('user_id', userId);

      int totalCount = 0;
      for (var item in response) {
        totalCount += item['quantity'] as int;
      }

      return totalCount;
    } catch (e) {
      return 0;
    }
  }

  // Calculate cart total
  static Future<Map<String, double>> getCartTotal() async {
    try {
      final cartItems = await getCartItems();

      double subtotal = 0;
      double totalDiscount = 0;

      for (var item in cartItems) {
        if (item['price'] != null) {
          final price = item['price'] as double;
          final quantity = item['quantity'] as int;
          subtotal += price * quantity;
        }
      }

      return {
        'subtotal': subtotal,
        'discount': totalDiscount,
        'total': subtotal,
      };
    } catch (e) {
      return {
        'subtotal': 0,
        'discount': 0,
        'total': 0,
      };
    }
  }
}