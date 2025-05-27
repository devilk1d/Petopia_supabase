import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/product_card.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({Key? key}) : super(key: key);

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;
  int _page = 0;
  static const int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, _loadProducts);
  }

  void _onScroll() {
    if (!_isLoading && _hasMore &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String categoryId = args['categoryId'];

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await ProductService.getProducts(
        page: _page,
        limit: _limit,
        categoryId: categoryId,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _hasMore = products.length == _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load products. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!mounted || _isLoading || !_hasMore) return;

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String categoryId = args['categoryId'];

    try {
      setState(() => _isLoading = true);

      final nextPage = _page + 1;
      final moreProducts = await ProductService.getProducts(
        page: nextPage,
        limit: _limit,
        categoryId: categoryId,
      );

      if (mounted) {
        setState(() {
          _products.addAll(moreProducts);
          _page = nextPage;
          _isLoading = false;
          _hasMore = moreProducts.length == _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load more products. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    _page = 0;
    _hasMore = true;
    await _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String categoryName = args['category'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          categoryName,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.black),
            onPressed: () {
              // TODO: Implement sort functionality
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category description
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Showing ${_products.length} products in $categoryName',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  // Products grid
                  Expanded(
                    child: _isLoading && _products.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _products.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/icons/empty_box.png',
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[400],
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.inventory_2_outlined,
                                          size: 100,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No products found in this category',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                child: GridView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.6,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _products.length + (_hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _products.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final product = _products[index];
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
                                ),
                              ),
                  ),
                ],
              ),
      ),
    );
  }
}