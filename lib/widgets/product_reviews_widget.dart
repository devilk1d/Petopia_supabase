// lib/widgets/product_reviews_widget.dart
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../utils/colors.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProductReviewsWidget extends StatefulWidget {
  final String productId;

  const ProductReviewsWidget({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  List<ReviewModel> _reviews = [];
  List<ReviewModel> _filteredReviews = [];
  Map<String, dynamic> _ratingSummary = {};
  bool _isLoading = true;
  String? _error;
  int _selectedStarFilter = 0; // 0 = all, 1-5 = specific stars
  int _currentPage = 0;
  final int _reviewsPerPage = 5;
  bool _hasMoreReviews = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadRatingSummary();
  }

  Future<void> _loadReviews({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final reviews = await ReviewService.getProductReviews(
        widget.productId,
        page: loadMore ? _currentPage + 1 : 0,
        limit: _reviewsPerPage,
        sortBy: 'created_at',
        ascending: false,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _reviews.addAll(reviews);
            _currentPage++;
            _hasMoreReviews = reviews.length == _reviewsPerPage;
            _isLoadingMore = false;
          } else {
            _reviews = reviews;
            _currentPage = 0;
            _hasMoreReviews = reviews.length == _reviewsPerPage;
            _isLoading = false;
          }
          _applyStarFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reviews: $e';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadRatingSummary() async {
    try {
      final summary = await ReviewService.getProductRatingSummary(widget.productId);
      if (mounted) {
        setState(() {
          _ratingSummary = summary;
        });
      }
    } catch (e) {
      print('Error loading rating summary: $e');
    }
  }

  void _applyStarFilter() {
    if (_selectedStarFilter == 0) {
      _filteredReviews = List.from(_reviews);
    } else {
      _filteredReviews = _reviews
          .where((review) => review.rating.toInt() == _selectedStarFilter)
          .toList();
    }
  }

  void _onStarFilterChanged(int stars) {
    setState(() {
      _selectedStarFilter = stars;
      _applyStarFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with rating summary
          _buildReviewHeader(),

          // Star filter
          _buildStarFilter(),

          // Reviews list
          _buildReviewsList(),

          // Load more button
          if (_hasMoreReviews && !_isLoading) _buildLoadMoreButton(),
        ],
      ),
    );
  }

  Widget _buildReviewHeader() {
    final averageRating = _ratingSummary['average_rating'] ?? 0.0;
    final totalReviews = _ratingSummary['total_reviews'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reviews',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          if (totalReviews > 0) ...[
            Row(
              children: [
                // Average rating display
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalReviews reviews',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating distribution
                Expanded(
                  flex: 3,
                  child: _buildRatingDistribution(),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final distribution = _ratingSummary['rating_distribution'] ?? {};
    final totalReviews = _ratingSummary['total_reviews'] ?? 0;

    return Column(
      children: [
        for (int i = 5; i >= 1; i--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '$i',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.star,
                  color: Colors.amber[600],
                  size: 12,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: totalReviews > 0
                          ? (distribution[i.toString()] ?? 0) / totalReviews
                          : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber[600],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${distribution[i.toString()] ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStarFilter() {
    if ((_ratingSummary['total_reviews'] ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by rating',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', 0),
                const SizedBox(width: 8),
                for (int i = 5; i >= 1; i--) ...[
                  _buildFilterChip('$i ⭐', i),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value) {
    final isSelected = _selectedStarFilter == value;

    return GestureDetector(
      onTap: () => _onStarFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.primaryColor
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadReviews(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredReviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                _selectedStarFilter == 0
                    ? 'No reviews yet'
                    : 'No $_selectedStarFilter star reviews',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _filteredReviews.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        return _buildReviewItem(_filteredReviews[index]);
      },
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                backgroundImage: review.userAvatar != null && review.userAvatar!.isNotEmpty
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null || review.userAvatar!.isEmpty
                    ? Text(
                  review.userFullName?.isNotEmpty == true
                      ? review.userFullName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userFullName ?? 'Anonymous User',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Star rating
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating.floor()
                                  ? Icons.star
                                  : (index < review.rating && index >= review.rating.floor()
                                  ? Icons.star_half
                                  : Icons.star_border),
                              color: Colors.amber[600],
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            review.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[700],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(review.createdAt),
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Review text/comment - Enhanced styling
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Review',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.comment!,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Review images - Enhanced layout
          if (review.images != null && review.images!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Photos (${review.images!.length})',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.images!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _showImageDialog(review.images!, index),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  review.images![index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              // Overlay icon untuk menandakan bisa di-tap
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],

          // Add helpful/like button (optional)
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement helpful/like functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feature coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  label: Text(
                    'Helpful',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(
          color: AppColors.primaryColor,
        )
            : OutlinedButton(
          onPressed: () => _loadReviews(loadMore: true),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text(
            'Load More Reviews',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: images.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}