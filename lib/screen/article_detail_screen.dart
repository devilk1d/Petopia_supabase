import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article_model.dart';
import '../services/article_service.dart';
import '../utils/colors.dart';

class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({Key? key}) : super(key: key);

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  ArticleModel? article;
  bool isLoading = true;
  String? error;
  String? articleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get articleId from route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    articleId = arguments?['articleId'] as String?;

    if (articleId != null) {
      _loadArticle();
    } else {
      setState(() {
        error = 'Article ID not provided';
        isLoading = false;
      });
    }
  }

  Future<void> _loadArticle() async {
    if (articleId == null) return;

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final loadedArticle = await ArticleService.getArticleById(articleId!);

      if (mounted) {
        setState(() {
          article = loadedArticle;
          isLoading = false;
          if (loadedArticle == null) {
            error = 'Article not found';
          }
        });
      }
    } catch (e) {
      print('Error loading article: $e');
      if (mounted) {
        setState(() {
          error = 'Failed to load article: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArticle,
              child: const Text('Coba Lagi'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    }

    if (article == null) {
      return const Center(
        child: Text('Article not found'),
      );
    }

    return Stack(
      children: [
        // Scrollable content
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image
              _buildHeroImage(),

              // Category pill
              _buildCategoryPill(),

              // Article title
              _buildTitle(),

              // Author information
              _buildAuthorInfo(),

              const SizedBox(height: 20),

              // Article content
              _buildContent(),
            ],
          ),
        ),

        // Back button
        _buildBackButton(),
      ],
    );
  }

  Widget _buildHeroImage() {
    return Stack(
      children: [
        // Article image
        SizedBox(
          width: double.infinity,
          height: 350,
          child: article!.imageUrl != null
              ? Image.network(
            article!.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          )
              : Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey,
              ),
            ),
          ),
        ),

        // White curved overlay at the bottom of the image
        Positioned(
          bottom: -7,
          left: 0,
          right: 0,
          child: Container(
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          article!.categoryName ?? 'Uncategorized',
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 15, 30, 10),
      child: Text(
        article!.title,
        style: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildAuthorInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          // Author avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: article!.authorImageUrl != null
                  ? Image.network(
                article!.authorImageUrl!,
                width: 28,
                height: 28,
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
          Text(
            article!.authorName ?? 'Unknown Author',
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 16,
        color: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parse dan tampilkan konten artikel
          _parseAndDisplayContent(article!.content ?? ''),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _parseAndDisplayContent(String content) {
    if (content.isEmpty) {
      return const Text(
        'No content available',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.grey,
          height: 1.5,
        ),
      );
    }

    // Simple content parser - split by double newlines for paragraphs
    List<String> paragraphs = content.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        paragraph = paragraph.trim();
        if (paragraph.isEmpty) return const SizedBox.shrink();

        // Check if it's a heading (starts with #)
        if (paragraph.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15, top: 20),
            child: Text(
              paragraph.substring(2),
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          );
        }

        // Check if it's a bullet point (starts with -)
        if (paragraph.startsWith('- ')) {
          return _buildBulletPoint(paragraph.substring(2));
        }

        // Regular paragraph
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            paragraph,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}