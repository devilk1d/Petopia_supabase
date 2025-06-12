import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';
import '../widgets/product_reviews_widget.dart'; // Import widget review

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({Key? key}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  int _selectedImageIndex = 0;
  String? _selectedVariant;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isWishlistLoading = false;
  String? _error;
  ProductModel? _product;
  double _currentPrice = 0;

  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();

    // Load product data
    Future.delayed(Duration.zero, _loadProduct);
  }

  Future<void> _loadProduct() async {
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final String productId = args['productId'];

      setState(() => _isLoading = true);
      final product = await ProductService.getProductById(productId);

      if (mounted && product != null) {
        setState(() {
          _product = product;
          _currentPrice = product.price;
          _isLoading = false;
          _error = null;
        });

        // Check wishlist status if user is logged in
        await _checkWishlistStatus();
      } else if (mounted) {
        setState(() {
          _error = 'Product not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load product details';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkWishlistStatus() async {
    if (_product == null || !AuthService.isAuthenticated) return;

    try {
      final isInWishlist = await WishlistService.isInWishlist(_product!.id);
      if (mounted) {
        setState(() {
          _isFavorite = isInWishlist;
        });
      }
    } catch (e) {
      print('Error checking wishlist status: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    if (_product == null) return;

    // Check if user is logged in
    if (!AuthService.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    if (_isWishlistLoading) return;

    setState(() => _isWishlistLoading = true);

    try {
      final newWishlistStatus = await WishlistService.toggleWishlist(_product!.id);

      if (mounted) {
        setState(() {
          _isFavorite = newWishlistStatus;
          _isWishlistLoading = false;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newWishlistStatus
                  ? 'Added to wishlist!'
                  : 'Removed from wishlist!',
            ),
            backgroundColor: newWishlistStatus
                ? AppColors.success
                : AppColors.warning,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWishlistLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wishlist: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Login Required',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Please login to add products to your wishlist.',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSelectedVariant(String variantName, double variantPrice) {
    setState(() {
      _selectedVariant = variantName;
      _currentPrice = variantPrice;
    });
  }

  // Format price with dots as thousand separators
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toInt()).replaceAll(',', '.');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
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

    if (_product == null) {
      return const Scaffold(
        body: Center(
          child: Text('Product not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom navigation controls at the top
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: _buildTopNavigation(),
                  ),
                ),

                // Image carousel with page indicator
                SliverToBoxAdapter(
                  child: _buildImageCarousel(),
                ),

                // Product info
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: child,
                    ),
                    child: _buildProductInfo(),
                  ),
                ),

                // Product Reviews Section
                SliverToBoxAdapter(
                  child: ProductReviewsWidget(
                    productId: _product!.id,
                  ),
                ),

                // Extra space for bottom buttons
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),

            // Bottom action buttons (fixed)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),

          // Share button
          GestureDetector(
            onTap: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.share_outlined,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        // Main image with PageView for swiping
        SizedBox(
          width: double.infinity,
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _product!.images.length,
            onPageChanged: (index) => setState(() => _selectedImageIndex = index),
            itemBuilder: (context, index) {
              return Hero(
                tag: 'product_image_${_product!.images[index]}',
                child: Image.network(
                  _product!.images[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primaryColor,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Enhanced Favorite button with wishlist functionality
        Positioned(
          top: 20,
          right: 20,
          child: GestureDetector(
            onTap: _toggleWishlist,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isWishlistLoading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              )
                  : AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(_isFavorite),
                  color: _isFavorite ? AppColors.primaryColor : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // Page indicator dots
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _product!.images.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _pageController.animateToPage(
                  entry.key,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  width: _selectedImageIndex == entry.key ? 12 : 8,
                  height: _selectedImageIndex == entry.key ? 12 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedImageIndex == entry.key
                        ? AppColors.primaryColor
                        : Colors.grey.withOpacity(0.3),
                    border: _selectedImageIndex == entry.key
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store info with verification badge
          _buildStoreInfo(),
          const SizedBox(height: 16),

          // Product title with improved typography
          Text(
            _product!.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Rating and review count
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                      (index) => Icon(
                    index < _product!.rating.floor()
                        ? Icons.star
                        : (index < _product!.rating && index >= _product!.rating.floor()
                        ? Icons.star_half
                        : Icons.star_border),
                    color: const Color(0xFFFFA000),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_product!.reviewCount} reviews)',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Variants section if available
          Builder(
            builder: (context) {
              if (_product!.variants != null && _product!.variants is Map<String, dynamic>) {
                final variants = _product!.variants as Map<String, dynamic>;
                if (variants.containsKey('name') &&
                    variants.containsKey('price') &&
                    variants['name'] is List &&
                    variants['price'] is List &&
                    (variants['name'] as List).isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Variant',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: (variants['name'] as List).length,
                          itemBuilder: (context, index) {
                            final variantName = (variants['name'] as List)[index].toString();
                            final variantPrice = double.tryParse((variants['price'] as List)[index].toString()) ?? 0.0;

                            return Padding(
                              padding: EdgeInsets.only(right: index == (variants['name'] as List).length - 1 ? 0 : 12),
                              child: GestureDetector(
                                onTap: () => _updateSelectedVariant(variantName, variantPrice),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedVariant == variantName
                                        ? AppColors.primaryColor.withOpacity(0.1)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedVariant == variantName
                                          ? AppColors.primaryColor
                                          : Colors.grey[300]!,
                                      width: _selectedVariant == variantName ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    variantName,
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 14,
                                      fontWeight: _selectedVariant == variantName
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: _selectedVariant == variantName
                                          ? AppColors.primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // Price section
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_product!.originalPrice != null)
                      Text(
                        'Rp${_formatPrice(_product!.originalPrice!)}',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[500],
                        ),
                      ),
                    Text(
                      'Rp${_formatPrice(_currentPrice)}',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF108F6A),
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                      color: _quantity > 1 ? Colors.black : Colors.grey,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_quantity < _product!.stock) {
                          setState(() => _quantity++);
                        }
                      },
                      color: _quantity < _product!.stock ? Colors.black : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Divider
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _product!.description ?? 'No description available',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // Stock info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  'Stock: ${_product!.stock} units',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/store',
          arguments: {'storeId': _product!.sellerId},
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              _product!.sellerStoreImage ?? 'assets/images/icons/store_placeholder.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 30,
                height: 30,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.store,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _product!.sellerStoreName ?? 'Unknown Store',
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.verified,
            size: 16,
            color: Colors.blue,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 14,
                  color: Color(0xFFFFA000),
                ),
                const SizedBox(width: 2),
                Text(
                  _product!.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wishlist button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFavorite ? AppColors.primaryColor : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _isFavorite ? AppColors.primaryColor.withOpacity(0.1) : Colors.white,
            ),
            child: IconButton(
              icon: _isWishlistLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              )
                  : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AppColors.primaryColor : Colors.grey[600],
              ),
              onPressed: _toggleWishlist,
            ),
          ),
          const SizedBox(width: 12),

          // Chat button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chat_outlined,
                color: AppColors.primaryColor,
              ),
              onPressed: () {
                // TODO: Implement chat with seller
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Add to cart button
          Expanded(
            child: ElevatedButton(
              onPressed: _product!.stock > 0 &&
                  (_product!.variants == null ||
                      !(_product!.variants is Map) ||
                      _selectedVariant != null)
                  ? () async {
                if (!AuthService.isAuthenticated) {
                  _showLoginDialog();
                  return;
                }

                try {
                  await CartService.addToCart(
                    productId: _product!.id,
                    quantity: _quantity,
                    variant: _selectedVariant,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to cart!'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add to cart: ${e.toString()}'),
                        backgroundColor: AppColors.primaryColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _product!.stock > 0
                    ? (_product!.variants != null &&
                    _product!.variants is Map &&
                    _selectedVariant == null)
                    ? 'Select a variant'
                    : 'Add to Cart - Rp${_formatPrice(_currentPrice * _quantity)}'
                    : 'Out of Stock',
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}