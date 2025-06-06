import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/product_service.dart';
import '../services/wishlist_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _searchResults = [];
  Set<String> _wishlistProductIds = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentQuery = '';

  // Recent searches (you could store this in SharedPreferences)
  List<String> _recentSearches = [];

  // Popular searches (you could fetch this from your backend)
  final List<String> _popularSearches = [
    'Makanan kucing',
    'Dog food',
    'Vitamin anjing',
    'Mainan kucing',
    'Kandang burung',
    'Aksesoris anjing',
  ];

  bool get _isLoggedIn => AuthService.getCurrentUserId() != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _loadWishlistStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWishlistStatus() async {
    if (!_isLoggedIn) return;

    try {
      // Load wishlist status for current results
      final wishlistIds = <String>{};
      for (final product in _searchResults) {
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
      print('Error loading wishlist status: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _currentQuery = query.trim();
    });

    try {
      final results = await ProductService.searchProducts(query.trim());

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _hasSearched = true;
        });

        // Add to recent searches
        if (!_recentSearches.contains(query.trim())) {
          _recentSearches.insert(0, query.trim());
          if (_recentSearches.length > 5) {
            _recentSearches = _recentSearches.take(5).toList();
          }
        }

        // Load wishlist status for new results
        await _loadWishlistStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomSearchBar(
          controller: _searchController,
          hintText: 'Cari produk...',
          enabled: true,
          onChanged: (value) {
            // Optional: implement real-time search with debouncing
            if (value.isEmpty) {
              setState(() {
                _searchResults = [];
                _hasSearched = false;
                _currentQuery = '';
              });
            }
          },
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              _performSearch(_searchController.text);
            },
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _hasSearched = false;
                  _currentQuery = '';
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search suggestions when not searching
          if (!_hasSearched && _currentQuery.isEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent searches
                    if (_recentSearches.isNotEmpty) ...[
                      const Text(
                        'Pencarian Terkini',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_recentSearches.length, (index) {
                        final search = _recentSearches[index];
                        return ListTile(
                          leading: const Icon(Icons.history, color: Colors.grey),
                          title: Text(
                            search,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.call_made, color: Colors.grey),
                            onPressed: () => _selectSuggestion(search),
                          ),
                          onTap: () => _selectSuggestion(search),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Popular searches
                    const Text(
                      'Pencarian Populer',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularSearches.map((search) {
                        return GestureDetector(
                          onTap: () => _selectSuggestion(search),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greyColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              search,
                              style: const TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          // Search results
          if (_hasSearched)
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
                  : _searchResults.isEmpty
                  ? _buildEmptyResults()
                  : _buildSearchResults(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ditemukan hasil untuk "$_currentQuery"',
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba kata kunci lain atau periksa ejaan',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Hasil pencarian untuk "$_currentQuery" (${_searchResults.length} produk)',
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),

        // Results grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
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
                storeLogoPath: product.sellerStoreImage ??
                    'assets/images/icons/store_placeholder.png',
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
          ),
        ),
      ],
    );
  }
}