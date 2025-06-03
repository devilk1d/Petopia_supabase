import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/colors.dart';
import '../services/article_service.dart';
import '../models/article_model.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({Key? key}) : super(key: key);

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _categories = [];
  List<ArticleModel> _articles = [];
  bool _isLoading = true;
  String? _error;
  RealtimeChannel? _articlesSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _articlesSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load categories and articles in parallel
      final categoriesFuture = ArticleService.getCategories();
      final articlesFuture = ArticleService.getPublishedArticles();

      final results = await Future.wait([categoriesFuture, articlesFuture]);

      if (mounted) {
        setState(() {
          // Explicitly cast the categories result to List<Map<String, dynamic>>
          final categoriesResult = (results[0] as List).map((item) =>
          Map<String, dynamic>.from(item as Map)).toList();

          _categories = [
            {'id': 'all', 'name': 'All'},
            ...categoriesResult,
          ];
          _articles = results[1] as List<ArticleModel>;
          _isLoading = false;

          // Debug: Print articles with their category names
          print('Loaded ${_articles.length} articles:');
          for (final article in _articles) {
            print('- ${article.title}: category = "${article.categoryName}"');
          }

          print('Available categories:');
          for (final category in _categories) {
            print('- ${category['name']}');
          }
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load articles. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    _articlesSubscription = Supabase.instance.client
        .channel('articles_changes')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'articles',
      callback: (payload) {
        print('Articles realtime change: ${payload.eventType}');
        _handleRealtimeChange(payload);
      },
    )
        .subscribe();
  }

  void _handleRealtimeChange(PostgresChangePayload payload) {
    if (!mounted) return;

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleInsert(payload.newRecord);
      case PostgresChangeEvent.update:
        _handleUpdate(payload.newRecord);
      case PostgresChangeEvent.delete:
        _handleDelete(payload.oldRecord);
      case PostgresChangeEvent.all:
      // Handle all events if needed
        break;
    }
  }

  void _handleInsert(Map<String, dynamic> newRecord) {
    // Hanya tambahkan jika artikel published
    if (newRecord['is_published'] == true) {
      _refreshSingleArticle(newRecord['id']);
    }
  }

  void _handleUpdate(Map<String, dynamic> updatedRecord) {
    final articleId = updatedRecord['id'];
    final isPublished = updatedRecord['is_published'] == true;

    if (isPublished) {
      // Refresh artikel yang sudah ada atau tambahkan yang baru
      _refreshSingleArticle(articleId);
    } else {
      // Hapus artikel jika tidak published lagi
      setState(() {
        _articles.removeWhere((article) => article.id == articleId);
      });
    }
  }

  void _handleDelete(Map<String, dynamic> deletedRecord) {
    final articleId = deletedRecord['id'];
    setState(() {
      _articles.removeWhere((article) => article.id == articleId);
    });
  }

  Future<void> _refreshSingleArticle(String articleId) async {
    try {
      final article = await ArticleService.getArticleById(articleId);
      if (article != null && article.isPublished && mounted) {
        setState(() {
          // Hapus artikel lama jika ada
          _articles.removeWhere((a) => a.id == articleId);
          // Tambahkan artikel baru di posisi yang benar (berdasarkan created_at)
          _articles.add(article);
          // Sort ulang berdasarkan created_at descending
          _articles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      }
    } catch (e) {
      print('Error refreshing single article: $e');
    }
  }

  List<ArticleModel> get _filteredArticles {
    print('Filtering articles for category: $_selectedCategory');
    if (_selectedCategory == 'All') {
      print('Showing all ${_articles.length} articles');
      return _articles;
    }

    final filtered = _articles.where((article) {
      final matches = article.categoryName == _selectedCategory;
      print('Article "${article.title}" - category: "${article.categoryName}" - matches: $matches');
      return matches;
    }).toList();

    print('Found ${filtered.length} articles for category $_selectedCategory');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with decoration
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'Articles',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category tabs with animated selection indicator
                  if (_categories.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final categoryName = category['name'] as String;
                          final isSelected = categoryName == _selectedCategory;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = categoryName;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(color: AppColors.primaryColor, width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? AppColors.primaryColor : Colors.grey[500],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Articles list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
                  : _filteredArticles.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredArticles.length,
                itemBuilder: (context, index) => _buildArticleCard(_filteredArticles[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different category',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/article-detail',
          arguments: {'articleId': article.id},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with category badge and favorite button
            Stack(
              children: [
                // Image with gradient overlay
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      article.imageUrl != null
                          ? Image.network(
                        article.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.image_not_supported)),
                          );
                        },
                      )
                          : Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
                      // Gradient overlay for better text visibility
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category badge
                if (article.categoryName != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.categoryName!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                // Title at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            // Author info and Read More button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Author info section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ditulis oleh',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Author profile image
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: article.authorImageUrl != null
                                    ? Image.network(
                                  article.authorImageUrl!,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar();
                                  },
                                )
                                    : _buildDefaultAvatar(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Author name
                            Expanded(
                              child: Text(
                                article.authorName ?? 'Unknown author',
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Read more button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/article-detail',
                        arguments: {'articleId': article.id},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Read',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 18,
        color: AppColors.primaryColor,
      ),
    );
  }
}