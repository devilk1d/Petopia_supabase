import '../models/article_model.dart';
import 'supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArticleService {
  static final _client = SupabaseConfig.client;

  // Get all published articles
  static Future<List<ArticleModel>> getPublishedArticles({
    int page = 0,
    int limit = 20,
    String? categoryId,
  }) async {
    try {
      final query = _client
          .from('articles')
          .select('''
            *,
            article_categories!inner (
              name
            ),
            admins!inner (
              full_name
            )
          ''')
          .eq('is_published', true);
      
      final filteredQuery = categoryId != null 
          ? query.eq('category_id', categoryId)
          : query;

      final response = await filteredQuery
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return (response as List).map((json) {
        // Add joined data to the main object
        json['category_name'] = json['article_categories']?['name'];
        json['author_name'] = json['admins']?['full_name'];

        return ArticleModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch articles: $e');
    }
  }

  // Get article by ID
  static Future<ArticleModel?> getArticleById(String articleId) async {
    try {
      final response = await _client
          .from('articles')
          .select('''
            *,
            article_categories!inner (
              name
            ),
            admins!inner (
              full_name
            )
          ''')
          .eq('id', articleId)
          .single();

      if (response == null) return null;

      // Add joined data to the main object
      response['category_name'] = response['article_categories']?['name'];
      response['author_name'] = response['admins']?['full_name'];

      return ArticleModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get articles by category
  static Future<List<ArticleModel>> getArticlesByCategory(String categoryId) async {
    return getPublishedArticles(categoryId: categoryId);
  }

  // Get article categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('article_categories')
          .select()
          .order('name');

      // Explicitly cast and convert the response
      return (response as List).map((item) => 
        Map<String, dynamic>.from(item as Map)
      ).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Get featured articles
  static Future<List<ArticleModel>> getFeaturedArticles({int limit = 5}) async {
    try {
      final response = await _client
          .from('articles')
          .select('''
            *,
            article_categories!inner (
              name
            ),
            admins!inner (
              full_name
            )
          ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        json['category_name'] = json['article_categories']?['name'];
        json['author_name'] = json['admins']?['full_name'];

        return ArticleModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured articles: $e');
    }
  }

  // Search articles
  static Future<List<ArticleModel>> searchArticles(String query) async {
    try {
      final response = await _client
          .from('articles')
          .select('''
            *,
            article_categories!inner (
              name
            ),
            admins!inner (
              full_name
            )
          ''')
          .eq('is_published', true)
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        json['category_name'] = json['article_categories']?['name'];
        json['author_name'] = json['admins']?['full_name'];

        return ArticleModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search articles: $e');
    }
  }
} 