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
    if (userId == null) {
      print('Cannot init cart subscription: user not logged in');
      return;
    }

    print('Initializing cart subscription for user: $userId');

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
        print('Cart change detected: ${payload.eventType}');
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
    print('Disposing cart subscription');
    _cartSubscription?.unsubscribe();
    _cartController?.close();
    _cartController = null;
    _cartSubscription = null;
  }

  // Get cart items for current user
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        print('Cannot get cart items: user not logged in');
        return [];
      }

      print('Fetching cart items for user: $userId');

      final response = await _client
          .from('carts')
          .select('''
            *,
            products!left (
              id,
              name,
              price,
              images,
              seller_id,
              variants,
              sellers!left (
                id,
                store_name,
                store_image_url
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Cart query response: ${response?.length ?? 0} items');

      if (response == null || (response as List).isEmpty) {
        print('No cart items found');
        return [];
      }

      final items = (response as List).map((item) {
        final product = item['products'];
        if (product == null) {
          print('Warning: Product not found for cart item ${item['id']}');
          return null;
        }

        final seller = product['sellers'];
        final variants = product['variants'];

        // Calculate the price based on variant if it exists
        double price = 0.0;
        try {
          price = (product['price'] as num).toDouble();
        } catch (e) {
          print('Error parsing product price: $e');
        }

        // Handle variant pricing
        if (item['variant'] != null &&
            item['variant'].toString().isNotEmpty &&
            variants != null &&
            variants is Map<String, dynamic>) {

          try {
            if (variants.containsKey('name') && variants.containsKey('price')) {
              final variantNames = variants['name'] as List;
              final variantPrices = variants['price'] as List;
              final variantIndex = variantNames.indexOf(item['variant']);
              if (variantIndex != -1 && variantIndex < variantPrices.length) {
                price = double.parse(variantPrices[variantIndex].toString());
              }
            }
          } catch (e) {
            print('Error parsing variant price: $e');
          }
        }

        // Get product images
        String? productImage;
        try {
          final images = product['images'];
          if (images != null && images is List && images.isNotEmpty) {
            productImage = images[0].toString();
          }
        } catch (e) {
          print('Error parsing product images: $e');
        }

        // Get store info
        String storeName = 'Unknown Store';
        String? storeImage;

        try {
          if (seller != null) {
            storeName = seller['store_name']?.toString() ?? 'Unknown Store';
            storeImage = seller['store_image_url']?.toString();
          }
        } catch (e) {
          print('Error parsing seller info: $e');
        }

        return {
          'id': item['id']?.toString() ?? '',
          'product_id': product['id']?.toString() ?? '',
          'seller_id': product['seller_id']?.toString() ?? '',
          'name': product['name']?.toString() ?? 'Unknown Product',
          'price': price,
          'image': productImage,
          'quantity': item['quantity'] ?? 1,
          'variant': item['variant']?.toString() ?? '',
          'store_name': storeName,
          'storeIcon': storeImage,
        };
      }).where((item) => item != null).cast<Map<String, dynamic>>().toList();

      print('Processed ${items.length} cart items successfully');

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

      print('Adding to cart: productId=$productId, quantity=$quantity, variant=$variant');

      // Check if item already exists in cart
      final existing = await _client
          .from('carts')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('variant', variant ?? '')
          .maybeSingle();

      if (existing != null) {
        print('Item exists in cart, updating quantity');
        // Update quantity if item exists
        await _client
            .from('carts')
            .update({
          'quantity': existing['quantity'] + quantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('id', existing['id']);
      } else {
        print('Adding new item to cart');
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

      print('Successfully added to cart');

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
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      print('Updating cart item quantity: itemId=$itemId, quantity=$quantity');

      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        await removeFromCart(itemId);
        return;
      }

      await _client
          .from('carts')
          .update({
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', itemId);

      print('Successfully updated cart item quantity');

      // Refresh cart items
      await getCartItems();
    } catch (e) {
      print('Error updating cart item quantity: $e');
      rethrow;
    }
  }

  // Remove item from cart
  static Future<void> removeFromCart(String itemId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      print('Removing item from cart: itemId=$itemId');

      await _client
          .from('carts')
          .delete()
          .eq('id', itemId);

      print('Successfully removed item from cart');

      // Refresh cart items
      await getCartItems();
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

      print('Clearing cart for user: $userId');

      await _client
          .from('carts')
          .delete()
          .eq('user_id', userId);

      print('Successfully cleared cart');

      // Update stream
      _cartController?.add([]);
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  // Get cart item count
  static Future<int> getCartItemCount() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return 0;

      final response = await _client
          .from('carts')
          .select('quantity')
          .eq('user_id', userId);

      int totalCount = 0;
      for (var item in response) {
        totalCount += (item['quantity'] as int? ?? 0);
      }

      return totalCount;
    } catch (e) {
      print('Error getting cart item count: $e');
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
        final price = item['price'] as double? ?? 0.0;
        final quantity = item['quantity'] as int? ?? 0;
        subtotal += price * quantity;
      }

      return {
        'subtotal': subtotal,
        'discount': totalDiscount,
        'total': subtotal,
      };
    } catch (e) {
      print('Error calculating cart total: $e');
      return {
        'subtotal': 0,
        'discount': 0,
        'total': 0,
      };
    }
  }

  // Check if product is in cart
  static Future<bool> isInCart(String productId, {String? variant}) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return false;

      final response = await _client
          .from('carts')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('variant', variant ?? '')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if product is in cart: $e');
      return false;
    }
  }

  // Get cart item by product ID and variant
  static Future<Map<String, dynamic>?> getCartItem(String productId, {String? variant}) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return null;

      final response = await _client
          .from('carts')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('variant', variant ?? '')
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting cart item: $e');
      return null;
    }
  }
}