import '../models/category_model.dart';
import 'supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  static final _client = SupabaseConfig.client;

  // Get product categories
  static Future<List<CategoryModel>> getProductCategories() async {
    try {
      print('Fetching categories from database...');
      final response = await _client
          .from('product_categories')
          .select()
          .order('name');

      print('Response from database: $response');
      
      if (response == null) {
        print('No response from database');
        return [];
      }

      final categories = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
      
      print('Parsed ${categories.length} categories');
      return categories;
    } catch (e) {
      print('CategoryService error: $e');
      return [];
    }
  }

  // Get article categories
  static Future<List<CategoryModel>> getArticleCategories() async {
    try {
      final response = await _client
          .from('article_categories')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch article categories: $e');
    }
  }

  // Get category by ID
  static Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final response = await _client
          .from('product_categories')
          .select()
          .eq('id', categoryId)
          .single();

      if (response == null) return null;
      return CategoryModel.fromJson(response);
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  // Get category by name
  static Future<CategoryModel?> getCategoryByName(String name) async {
    try {
      final response = await _client
          .from('product_categories')
          .select()
          .eq('name', name)
          .single();

      if (response == null) return null;
      return CategoryModel.fromJson(response);
    } catch (e) {
      print('Error getting category by name: $e');
      return null;
    }
  }

  // Admin methods

  // Create category
  static Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final table = type == 'product' ? 'product_categories' : 'article_categories';
      
      final response = await _client
          .from(table)
          .insert({
            'name': name,
            'description': description,
            'image_url': imageUrl,
            'is_active': true,
          })
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update category
  static Future<CategoryModel> updateCategory({
    required String categoryId,
    required String type,
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      final table = type == 'product' ? 'product_categories' : 'article_categories';
      
      final updateData = {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        if (isActive != null) 'is_active': isActive,
      };

      final response = await _client
          .from(table)
          .update(updateData)
          .eq('id', categoryId)
          .select()
          .single();

      return CategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category (soft delete)
  static Future<void> deleteCategory(String categoryId, String type) async {
    try {
      final table = type == 'product' ? 'product_categories' : 'article_categories';
      
      await _client
          .from(table)
          .update({'is_active': false})
          .eq('id', categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Get category statistics
  static Future<Map<String, dynamic>> getCategoryStatistics(String categoryId, String type) async {
    try {
      if (type == 'product') {
        final response = await _client
            .from('products')
            .select('id')
            .eq('category_id', categoryId)
            .eq('is_active', true);

        return {
          'total_items': (response as List).length,
        };
      } else {
        final response = await _client
            .from('articles')
            .select('id')
            .eq('category_id', categoryId)
            .eq('is_published', true);

        return {
          'total_items': (response as List).length,
        };
      }
    } catch (e) {
      throw Exception('Failed to get category statistics: $e');
    }
  }
} 