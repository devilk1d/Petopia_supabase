import '../models/review_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  static final _client = SupabaseConfig.client;
  static SupabaseClient get supabase => _client;

  // Get product reviews
  static Future<List<ReviewModel>> getProductReviews(
    String productId, {
    int page = 0,
    int limit = 10,
    String? sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final response = await _client
          .from('product_reviews')
          .select('''
            *,
            users (
              full_name,
              profile_image_url
            )
          ''')
          .eq('product_id', productId)
          .order(sortBy ?? 'created_at', ascending: ascending)
          .range(page * limit, (page + 1) * limit - 1);

      return ReviewModel.fromJsonList(response);
    } catch (e) {
      throw Exception('Failed to fetch product reviews: $e');
    }
  }

  // Get user reviews
  static Future<List<ReviewModel>> getUserReviews({
    int page = 0,
    int limit = 10,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('product_reviews')
          .select('''
            *,
            users (
              full_name,
              profile_image_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return ReviewModel.fromJsonList(response);
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  // Add review
  static Future<ReviewModel> addReview({
    required String productId,
    required String orderId,
    required double rating,
    String? comment,
    List<String>? images,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user has already reviewed this product for this order
      final existingReview = await _client
          .from('product_reviews')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('order_item_id', orderId)
          .maybeSingle();

      if (existingReview != null) {
        throw Exception('You have already reviewed this product for this order');
      }

      final response = await _client
          .from('product_reviews')
          .insert({
            'user_id': userId,
            'product_id': productId,
            'order_item_id': orderId,
            'rating': rating.toInt(),
            'review_text': comment,
            'images': images ?? [],
          })
          .select('''
            *,
            users (
              full_name,
              profile_image_url
            )
          ''')
          .single();

      return ReviewModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Update review
  static Future<ReviewModel> updateReview({
    required String reviewId,
    double? rating,
    String? comment,
    List<String>? images,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final updateData = {
        if (rating != null) 'rating': rating.toInt(),
        if (comment != null) 'review_text': comment,
        if (images != null) 'images': images,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('product_reviews')
          .update(updateData)
          .eq('id', reviewId)
          .eq('user_id', userId)
          .select('''
            *,
            users (
              full_name,
              profile_image_url
            )
          ''')
          .single();

      return ReviewModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete review
  static Future<void> deleteReview(String reviewId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('product_reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get product rating summary
  static Future<Map<String, dynamic>> getProductRatingSummary(String productId) async {
    try {
      final response = await _client
          .from('product_reviews')
          .select('rating')
          .eq('product_id', productId);

      final reviews = response as List;
      if (reviews.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_reviews': 0,
          'rating_distribution': {
            '5': 0,
            '4': 0,
            '3': 0,
            '2': 0,
            '1': 0,
          },
        };
      }

      // Calculate average rating
      double sum = 0;
      Map<String, int> distribution = {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };

      for (var review in reviews) {
        final rating = (review['rating'] as num).toDouble();
        sum += rating;
        distribution[rating.toInt().toString()] = 
            (distribution[rating.toInt().toString()] ?? 0) + 1;
      }

      return {
        'average_rating': sum / reviews.length,
        'total_reviews': reviews.length,
        'rating_distribution': distribution,
      };
    } catch (e) {
      throw Exception('Failed to get product rating summary: $e');
    }
  }
} 