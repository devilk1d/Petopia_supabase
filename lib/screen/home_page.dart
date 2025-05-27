import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/category_item.dart';
import '../widgets/promo_banner.dart';
import '../widgets/search_bar.dart';
import '../widgets/product_card.dart';
import '../services/category_service.dart';
import '../services/promo_service.dart';
import '../services/product_service.dart';
import '../models/category_model.dart';
import '../models/promo_model.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentBannerIndex = 0;
  late PageController _bannerController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Data states
  List<CategoryModel> _categories = [];
  List<PromoModel> _promos = [];
  List<ProductModel> _recommendedProducts = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();

    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Load data
    _loadData();
    _subscribeToUserProfile();

    // Setup timer to auto-scroll banner
    Future.delayed(Duration.zero, () {
      _autoScrollBanner();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _animationController.dispose();
    _userSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToUserProfile() {
    try {
      _userSubscription = UserService.subscribeToUserProfile().listen(
        (userData) {
          if (mounted) {
            setState(() {
              _userData = userData;
            });
          }
        },
        onError: (error) {
          print('Error in user subscription: $error');
        },
      );
    } catch (e) {
      print('Error setting up user subscription: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all data in parallel with individual try-catch blocks
      List<dynamic> results = [];
      String? specificError;

      try {
        final categories = await CategoryService.getProductCategories();
        results.add(categories);
      } catch (e) {
        print('Category error: $e');
      }

      try {
        final promos = await PromoService.getActivePromos();
        results.add(promos);
      } catch (e) {
        print('Promo error: $e');
      }

      try {
        final products = await ProductService.getRecommendedProducts(limit: 4);
        results.add(products);
      } catch (e) {
        print('Product error: $e');
      }

      try {
        final userData = await UserService.getCurrentUserProfile();
        setState(() {
          _userData = userData;
        });
      } catch (e) {
        print('User data error: $e');
      }

      if (mounted) {
        setState(() {
          _categories = results.length > 0 ? (results[0] as List<CategoryModel>) : [];
          _promos = results.length > 1 ? (results[1] as List<PromoModel>) : [];
          _recommendedProducts = results.length > 2 ? (results[2] as List<ProductModel>) : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('General error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please check your internet connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _autoScrollBanner() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        if (_currentBannerIndex < _promos.length - 1) {
          _currentBannerIndex++;
        } else {
          _currentBannerIndex = 0;
        }

        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );

        _autoScrollBanner();
      }
    });
  }

  void _navigateToCategoryProducts(CategoryModel category) {
    Navigator.of(context).pushNamed(
      '/category-products',
      arguments: {
        'category': category.name,
        'categoryId': category.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _recommendedProducts.isEmpty && _categories.isEmpty && _promos.isEmpty
          ? const Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Add top spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),
                  
                  // App header with consistent padding
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        children: [
                          // Welcome text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${_userData?['full_name'] ?? _userData?['username'] ?? 'Guest'}',
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Find Your Pet Needs',
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Notification icon with badge
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.greyColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/notif');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search bar with consistent styling
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: CustomSearchBar(),
                          ),
                          const SizedBox(width: 12),
                          // Promo button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed('/promos');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.greyColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/icons/promo_icon.png',
                                    width: 20,
                                    height: 20,
                                    color: AppColors.primaryColor,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.local_offer,
                                        size: 20,
                                        color: AppColors.primaryColor,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Promo',
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Wishlist button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed('/wishlist');
                            },
                            child: Container(
                              height: 46,
                              width: 46,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.greyColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.favorite_border,
                                size: 20,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Promo banner carousel
                  if (_promos.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Special Offers',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Banner carousel
                            SizedBox(
                              height: 180,
                              child: PageView.builder(
                                controller: _bannerController,
                                itemCount: _promos.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentBannerIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final promo = _promos[index];
                                  return PromoBanner(
                                    title: promo.title,
                                    subtitle: promo.discountType == 'percentage'
                                        ? '${promo.discountValue.toStringAsFixed(0)}% OFF'
                                        : 'Rp${promo.discountValue.toStringAsFixed(0)} OFF',
                                    description: promo.description ?? '',
                                    buttonText: 'Use Code: ${promo.code}',
                                    backgroundColor: index % 4 == 0
                                        ? AppColors.purpleBanner
                                        : index % 4 == 1
                                            ? AppColors.orangeBanner
                                            : index % 4 == 2
                                                ? AppColors.greenBanner
                                                : AppColors.redBanner,
                                    imagePath: 'assets/images/banners/promo_${index % 4 + 1}.png',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Carousel indicator with improved styling
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: _promos.asMap().entries.map((entry) {
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentBannerIndex == entry.key
                                          ? AppColors.primaryColor
                                          : Colors.grey.withOpacity(0.3),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categories carousel
                  if (_categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Categories',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Categories horizontal list
                            SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: CategoryItem(
                                      iconPath: category.iconUrl ?? 'assets/images/categories/default_icon.png',
                                      name: category.name,
                                      backgroundColor: _getCategoryColor(category.color),
                                      onTap: () => _navigateToCategoryProducts(category),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Product recommendations
                  if (_recommendedProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recommendation',
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // Handle see all
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      'See All',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                  // Product grid
                  if (_recommendedProducts.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _recommendedProducts[index];
                            return ProductCard(
                              imagePath: product.images.isNotEmpty
                                  ? product.images.first
                                  : 'assets/images/products/placeholder.png',
                              name: product.name,
                              price: product.price,
                              originalPrice: product.originalPrice,
                              discountPercentage: product.discountPercentage,
                              rating: product.rating,
                              reviewCount: product.reviewCount,
                              storeName: product.sellerStoreName ?? '',
                              storeLogoPath: product.sellerStoreImage ?? 'assets/images/icons/store_placeholder.png',
                              isFavorite: false, // TODO: Implement wishlist check
                              id: product.id,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  '/product-detail',
                                  arguments: {'productId': product.id},
                                );
                              },
                              onFavoriteTap: () {
                                // TODO: Implement wishlist toggle
                              },
                            );
                          },
                          childCount: _recommendedProducts.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Color _getCategoryColor(String? colorString) {
    if (colorString == null) return Colors.grey[200]!;
    try {
      // Remove '#' and add alpha channel
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      print('Error parsing color: $colorString - $e');
      return Colors.grey[200]!;
    }
  }
}