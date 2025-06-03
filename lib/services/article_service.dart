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
            article_categories (
              name
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
        // author_name sudah ada di json langsung dari tabel articles
        // Tidak perlu ambil dari tabel admins

        return ArticleModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch articles: $e');
    }
  }

  // Get article by ID with full data for realtime updates
  static Future<ArticleModel?> getArticleById(String articleId) async {
    try {
      final response = await _client
          .from('articles')
          .select('''
            *,
            article_categories (
              name
            )
          ''')
          .eq('id', articleId)
          .maybeSingle(); // Use maybeSingle instead of single to avoid exception

      if (response == null) return null;

      // Add joined data to the main object
      response['category_name'] = response['article_categories']?['name'];
      // author_name sudah ada di response langsung

      return ArticleModel.fromJson(response);
    } catch (e) {
      print('Error fetching article by ID: $e');
      return null;
    }
  }

  // Stream for realtime articles (alternative approach)
  static Stream<List<ArticleModel>> getArticlesStream() {
    return _client
        .from('articles')
        .stream(primaryKey: ['id'])
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .map((data) {
      return data.map((json) {
        // Note: Stream doesn't support joins, so category_name will be null
        // You might need to fetch categories separately
        return ArticleModel.fromJson(json);
      }).toList();
    });
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
            article_categories (
              name
            )
          ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        json['category_name'] = json['article_categories']?['name'];
        // author_name sudah tersedia langsung dari json

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
            article_categories (
              name
            )
          ''')
          .eq('is_published', true)
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        json['category_name'] = json['article_categories']?['name'];
        // author_name sudah tersedia langsung

        return ArticleModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search articles: $e');
    }
  }
}