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
import '../services/wishlist_service.dart';
import '../models/category_model.dart';
import '../models/promo_model.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/format.dart';
import '../services/notification_service.dart';

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
  int _notificationCount = 0;
  StreamSubscription? _notificationCountSubscription;

  // Data states
  List<CategoryModel> _categories = [];
  List<PromoModel> _promos = [];
  List<ProductModel> _recommendedProducts = [];
  Set<String> _wishlistProductIds = {}; // Track wishlist items
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;

  // Real-time subscriptions
  StreamSubscription? _userSubscription;
  StreamSubscription? _productsSubscription;
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _promosSubscription;
  StreamSubscription? _wishlistSubscription;

  // Banner auto-scroll timer
  Timer? _bannerTimer;

  // Check if user is logged in
  bool get _isLoggedIn => AuthService.getCurrentUserId() != null;

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

    // Initial data load
    _loadData();

    // Setup real-time subscriptions
    _setupRealTimeSubscriptions();

    _subscribeToNotificationCount();

    // Setup timer to auto-scroll banner
    Future.delayed(Duration.zero, () {
      _autoScrollBanner();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _animationController.dispose();
    _bannerTimer?.cancel(); // Cancel timer saat dispose

    // Cancel all subscriptions
    _userSubscription?.cancel();
    _productsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _promosSubscription?.cancel();
    _wishlistSubscription?.cancel();
    _notificationCountSubscription?.cancel();

    super.dispose();
  }

  void _subscribeToNotificationCount() {
    if (!_isLoggedIn) return;

    try {
      _notificationCountSubscription = NotificationService.subscribeToUnreadCount().listen(
            (count) {
          if (mounted) {
            setState(() {
              _notificationCount = count;
            });
          }
        },
        onError: (error) {
          print('Error in notification count subscription: $error');
        },
      );
    } catch (e) {
      print('Error setting up notification count subscription: $e');
    }
  }

// Tambahkan method untuk load notification count
  Future<void> _loadNotificationCount() async {
    if (!_isLoggedIn) return;

    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  void _setupRealTimeSubscriptions() {
    // Subscribe to user profile changes (only if logged in)
    if (_isLoggedIn) {
      _subscribeToUserProfile();
      _subscribeToWishlistChanges();
      _subscribeToNotificationCount();
    }

    // Subscribe to products changes
    _subscribeToProductsChanges();

    // Subscribe to categories changes
    _subscribeToCategoriesChanges();

    // Subscribe to promos changes
    _subscribeToPromosChanges();
  }

  void _subscribeToUserProfile() {
    try {
      if (!_isLoggedIn) {
        print('User not logged in, skipping profile subscription');
        return;
      }

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

  void _subscribeToProductsChanges() {
    try {
      _productsSubscription = ProductService.supabase
          .from('products')
          .stream(primaryKey: ['id'])
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(4)
          .listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          _handleProductsUpdate(data);
        }
      });
    } catch (e) {
      print('Error setting up products subscription: $e');
    }
  }

  void _subscribeToCategoriesChanges() {
    try {
      _categoriesSubscription = ProductService.supabase
          .from('product_categories')
          .stream(primaryKey: ['id'])
          .order('name')
          .listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          _handleCategoriesUpdate(data);
        }
      });
    } catch (e) {
      print('Error setting up categories subscription: $e');
    }
  }

  void _subscribeToPromosChanges() {
    try {
      _promosSubscription = ProductService.supabase
          .from('promos')
          .stream(primaryKey: ['id'])
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .listen((List<Map<String, dynamic>> data) {
        // Filter out expired promos locally
        final now = DateTime.now();
        final activePromos = data.where((promo) {
          final endDate = DateTime.parse(promo['end_date']);
          return endDate.isAfter(now);
        }).toList();

        if (mounted) {
          _handlePromosUpdate(activePromos);
        }
      });
    } catch (e) {
      print('Error setting up promos subscription: $e');
    }
  }

  void _subscribeToWishlistChanges() {
    if (!_isLoggedIn) return;

    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return;

      _wishlistSubscription = WishlistService.supabase
          .from('wishlists')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((List<Map<String, dynamic>> data) {
        if (mounted) {
          _handleWishlistUpdate(data);
        }
      });
    } catch (e) {
      print('Error setting up wishlist subscription: $e');
    }
  }

  Future<void> _handleProductsUpdate(List<Map<String, dynamic>> data) async {
    try {
      print('Products updated via real-time: ${data.length} items');

      // Process the raw data to include joined information
      List<ProductModel> updatedProducts = [];

      for (var productData in data) {
        // Get additional data for each product (category and seller info)
        final productWithDetails = await ProductService.getProductById(productData['id']);
        if (productWithDetails != null) {
          updatedProducts.add(productWithDetails);
        }
      }

      setState(() {
        _recommendedProducts = updatedProducts;
      });

      // Update wishlist status for new products
      if (_isLoggedIn) {
        _updateWishlistStatus();
      }
    } catch (e) {
      print('Error handling products update: $e');
    }
  }

  void _handleCategoriesUpdate(List<Map<String, dynamic>> data) {
    try {
      print('Categories updated via real-time: ${data.length} items');

      final updatedCategories = data
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      setState(() {
        _categories = updatedCategories;
      });
    } catch (e) {
      print('Error handling categories update: $e');
    }
  }

  void _handlePromosUpdate(List<Map<String, dynamic>> data) {
    try {
      print('Promos updated via real-time: [38;5;2m${data.length} items[0m');
      final updatedPromos = data.map((json) => PromoModel.fromJson(json)).toList();
      setState(() {
        _promos = updatedPromos;
      });
      if (_promos.isNotEmpty) {
        _autoScrollBanner();
      } else {
        _bannerTimer?.cancel();
      }
    } catch (e) {
      print('Error handling promos update: $e');
    }
  }

  void _handleWishlistUpdate(List<Map<String, dynamic>> data) {
    try {
      print('Wishlist updated via real-time: ${data.length} items');

      final wishlistProductIds = data
          .map((item) => item['product_id'] as String)
          .toSet();

      setState(() {
        _wishlistProductIds = wishlistProductIds;
      });
    } catch (e) {
      print('Error handling wishlist update: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading home page data...');

      // Load all data in parallel with individual try-catch blocks
      final List<Future> futures = [
        _loadCategories(),
        _loadPromos(),
        _loadProducts(),
        if (_isLoggedIn) _loadUserData(),
        if (_isLoggedIn) _loadWishlistStatus(),
        if (_isLoggedIn) _loadNotificationCount(),
      ];

      // Wait for all to complete, but don't fail if one fails
      await Future.wait(futures, eagerError: false);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      print('Home page data loaded successfully');
    } catch (e) {
      print('General error loading home page data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Please check your internet connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      print('Loading categories...');
      final categories = await CategoryService.getProductCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
      print('Categories loaded: ${categories.length} items');
    } catch (e) {
      print('Category loading error: $e');
    }
  }

  Future<void> _loadPromos() async {
    try {
      print('Loading promos...');
      final promos = await PromoService.getActivePromos();
      if (mounted) {
        setState(() {
          _promos = promos;
        });
        if (_promos.isNotEmpty) {
          _autoScrollBanner();
        } else {
          _bannerTimer?.cancel();
        }
      }
      print('Promos loaded: ${promos.length} items');
    } catch (e) {
      print('Promo loading error: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      print('Loading recommended products...');
      final products = await ProductService.getRecommendedProducts(limit: 4);
      if (mounted) {
        setState(() {
          _recommendedProducts = products;
        });
      }
      print('Recommended products loaded: ${products.length} items');
    } catch (e) {
      print('Product loading error: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      if (!_isLoggedIn) return;

      print('Loading user data...');
      final userData = await UserService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
      print('User data loaded');
    } catch (e) {
      print('User data loading error: $e');
    }
  }

  Future<void> _loadWishlistStatus() async {
    if (!_isLoggedIn || _recommendedProducts.isEmpty) return;

    try {
      await _updateWishlistStatus();
    } catch (e) {
      print('Error loading wishlist status: $e');
    }
  }

  Future<void> _updateWishlistStatus() async {
    if (!_isLoggedIn || _recommendedProducts.isEmpty) return;

    try {
      final wishlistIds = <String>{};
      for (final product in _recommendedProducts) {
        final isInWishlist = await WishlistService.isInWishlist(product.id);
        if (isInWishlist) {
          wishlistIds.add(product.id);
        }
      }

      if (mounted) {
        setState(() {
          _wishlistProductIds = wishlistIds;
        });
      }
    } catch (e) {
      print('Error updating wishlist status: $e');
    }
  }

  Future<void> _toggleWishlist(String productId) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    try {
      final isNowInWishlist = await WishlistService.toggleWishlist(productId);

      if (mounted) {
        setState(() {
          if (isNowInWishlist) {
            _wishlistProductIds.add(productId);
          } else {
            _wishlistProductIds.remove(productId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNowInWishlist
                ? 'Added to wishlist!'
                : 'Removed from wishlist!'),
            backgroundColor: isNowInWishlist
                ? AppColors.success
                : AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wishlist: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please login to add items to wishlist'),
        action: SnackBarAction(
          label: 'Login',
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _autoScrollBanner() {
    _bannerTimer?.cancel(); // Cancel timer lama jika ada
    if (!mounted || _promos.isEmpty) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _promos.isEmpty) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentBannerIndex < _promos.length - 1) {
          _currentBannerIndex++;
        } else {
          _currentBannerIndex = 0;
        }
        if (_bannerController.hasClients) {
          _bannerController.animateToPage(
            _currentBannerIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
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

  // Handle refresh manually
  Future<void> _handleRefresh() async {
    print('Manual refresh triggered');
    await _loadData();
  }

  // Get user display name
  String get _userDisplayName {
    if (!_isLoggedIn || _userData == null) return 'Guest';

    return _userData!['full_name'] ??
        _userData!['username'] ??
        _userData!['email']?.split('@')[0] ??
        'Guest';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primaryColor,
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
                              'Hello, $_userDisplayName',
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
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Notification icon with badge
                      Stack(
                        children: [
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
                                if (_isLoggedIn) {
                                  Navigator.pushNamed(context, '/notif');
                                } else {
                                  Navigator.pushNamed(context, '/login');
                                }
                              },
                            ),
                          ),
                          if (_isLoggedIn && _notificationCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  _notificationCount > 99 ? '99+' : '$_notificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
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
                          if (_isLoggedIn) {
                            Navigator.of(context).pushNamed('/wishlist');
                          } else {
                            Navigator.pushNamed(context, '/login');
                          }
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
                                    : '${formatRupiah(promo.discountValue)} OFF',
                                description: promo.description ?? '',
                                promoCode: promo.code,
                                backgroundColor: index % 4 == 0
                                    ? AppColors.purpleBanner
                                    : index % 4 == 1
                                    ? AppColors.orangeBanner
                                    : index % 4 == 2
                                    ? AppColors.greenBanner
                                    : AppColors.redBanner,
                                imagePath: 'assets/images/banners/promo_${index % 4 + 1}.png',
                                minPurchase: promo.minPurchase,
                                startDate: promo.startDate,
                                endDate: promo.endDate,
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
                                // Navigate to all products or search page
                                Navigator.of(context).pushNamed('/category-products', arguments: {
                                  'category': 'All Products',
                                  'categoryId': null,
                                });
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
                        final isInWishlist = _wishlistProductIds.contains(product.id);

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
                          isFavorite: isInWishlist,
                          id: product.id,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/product-detail',
                              arguments: {'productId': product.id},
                            );
                          },
                          onFavoriteTap: () {
                            _toggleWishlist(product.id);
                          },
                        );
                      },
                      childCount: _recommendedProducts.length,
                    ),
                  ),
                ),

              // Empty state if no data
              if (_categories.isEmpty && _promos.isEmpty && _recommendedProducts.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Welcome to Petopia!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your one-stop shop for all pet needs',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
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