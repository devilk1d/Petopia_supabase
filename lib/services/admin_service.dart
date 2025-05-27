import '../models/article_model.dart';
import '../models/shipping_method_model.dart';
import '../models/payment_method_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';

class AdminService {
  static final _client = SupabaseConfig.client;

  // Check if user is admin
  static Future<bool> isAdmin(String email, String password) async {
    try {
      final response = await _client
          .from('admins')
          .select()
          .eq('email', email)
          .single();

      // In a real app, you should properly hash and verify the password
      // This is just for demonstration
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Article Management
  static Future<ArticleModel> createArticle({
    required String title,
    required String content,
    required String categoryId,
    String? imageUrl,
    bool isPublished = false,
  }) async {
    try {
      final adminId = AuthService.currentUserId;
      if (adminId == null) throw Exception('Not authenticated as admin');

      final response = await _client
          .from('articles')
          .insert({
            'admin_id': adminId,
            'category_id': categoryId,
            'title': title,
            'content': content,
            'image_url': imageUrl,
            'is_published': isPublished,
          })
          .select()
          .single();

      return ArticleModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create article: $e');
    }
  }

  static Future<ArticleModel> updateArticle(ArticleModel article) async {
    try {
      final response = await _client
          .from('articles')
          .update(article.toJson())
          .eq('id', article.id)
          .select()
          .single();

      return ArticleModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update article: $e');
    }
  }

  static Future<void> deleteArticle(String articleId) async {
    try {
      await _client
          .from('articles')
          .delete()
          .eq('id', articleId);
    } catch (e) {
      throw Exception('Failed to delete article: $e');
    }
  }

  // Payment Method Management
  static Future<PaymentMethodModel> addPaymentMethod({
    required String name,
    required String type,
    String? logoUrl,
  }) async {
    try {
      final response = await _client
          .from('payment_methods')
          .insert({
            'name': name,
            'type': type,
            'logo_url': logoUrl,
            'is_active': true,
          })
          .select()
          .single();

      return PaymentMethodModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  static Future<void> updatePaymentMethod(PaymentMethodModel method) async {
    try {
      await _client
          .from('payment_methods')
          .update(method.toJson())
          .eq('id', method.id);
    } catch (e) {
      throw Exception('Failed to update payment method: $e');
    }
  }

  static Future<void> deletePaymentMethod(String methodId) async {
    try {
      await _client
          .from('payment_methods')
          .update({'is_active': false})
          .eq('id', methodId);
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  // Shipping Method Management
  static Future<ShippingMethodModel> addShippingMethod({
    required String name,
    required String type,
    String? logoUrl,
    required double baseCost,
  }) async {
    try {
      final response = await _client
          .from('shipping_methods')
          .insert({
            'name': name,
            'type': type,
            'logo_url': logoUrl,
            'base_cost': baseCost,
            'is_active': true,
          })
          .select()
          .single();

      return ShippingMethodModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add shipping method: $e');
    }
  }

  static Future<void> updateShippingMethod(ShippingMethodModel method) async {
    try {
      await _client
          .from('shipping_methods')
          .update(method.toJson())
          .eq('id', method.id);
    } catch (e) {
      throw Exception('Failed to update shipping method: $e');
    }
  }

  static Future<void> deleteShippingMethod(String methodId) async {
    try {
      await _client
          .from('shipping_methods')
          .update({'is_active': false})
          .eq('id', methodId);
    } catch (e) {
      throw Exception('Failed to delete shipping method: $e');
    }
  }
} 