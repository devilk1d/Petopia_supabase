// lib/services/wishlist_service.dart
import '../models/product_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistService {
  static final _client = SupabaseConfig.client;
  static SupabaseClient get supabase => _client;

  // Get user's wishlist items
  static Future<List<ProductModel>> getWishlistItems() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('wishlists')
          .select('''
            *,
            products (
              *,
              product_categories (
                name
              ),
              sellers (
                store_name,
                store_image_url
              )
            )
          ''')
          .filter('user_id', 'eq', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final productData = json['products'];

        // Process joined product data
        productData['category_name'] = productData['product_categories']?['name'];
        productData['seller_store_name'] = productData['sellers']?['store_name'];
        productData['seller_store_image'] = productData['sellers']?['store_image_url'];

        return ProductModel.fromJson(productData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch wishlist items: $e');
    }
  }

  // Add item to wishlist
  static Future<void> addToWishlist(String productId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Check if item already exists in wishlist
      final existingItem = await _client
          .from('wishlists')
          .select()
          .filter('user_id', 'eq', userId)
          .filter('product_id', 'eq', productId)
          .maybeSingle();

      if (existingItem == null) {
        await _client
            .from('wishlists')
            .insert({
              'user_id': userId,
              'product_id': productId,
            });
      }
    } catch (e) {
      throw Exception('Failed to add item to wishlist: $e');
    }
  }

  // Remove item from wishlist
  static Future<void> removeFromWishlist(String productId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('wishlists')
          .delete()
          .filter('user_id', 'eq', userId)
          .filter('product_id', 'eq', productId);
    } catch (e) {
      throw Exception('Failed to remove item from wishlist: $e');
    }
  }

  // Check if product is in wishlist
  static Future<bool> isInWishlist(String productId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return false;

      final response = await _client
          .from('wishlists')
          .select()
          .filter('user_id', 'eq', userId)
          .filter('product_id', 'eq', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Toggle wishlist status
  static Future<bool> toggleWishlist(String productId) async {
    final isCurrentlyInWishlist = await isInWishlist(productId);

    if (isCurrentlyInWishlist) {
      await removeFromWishlist(productId);
      return false;
    } else {
      await addToWishlist(productId);
      return true;
    }
  }

  // Get wishlist count
  static Future<int> getWishlistCount() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return 0;

      final response = await _client
          .from('wishlists')
          .select('id')
          .filter('user_id', 'eq', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}