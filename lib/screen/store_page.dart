import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../utils/colors.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/product_card.dart';

class StorePage extends StatefulWidget {
  final String storeId;

  const StorePage({Key? key, required this.storeId}) : super(key: key);

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final store = await StoreService.getStoreById(widget.storeId);
      if (store == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final products = await StoreService.getStoreProducts(store['id']);
      if (mounted) {
        setState(() {
          _storeData = store;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Minimal App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black87),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.black87),
                onPressed: () {},
              ),
            ],
          ),

          // Store Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Store Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.primaryColor.withOpacity(0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _storeData?['store_image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.store_rounded,
                              color: AppColors.primaryColor,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Store Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _storeData?['store_name'] ?? 'Unnamed Store',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _storeData?['store_description'] ?? 'No description',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Store Stats
                  Row(
                    children: [
                      _buildStat('4.8', 'Rating', Icons.star),
                      _buildStat('${_products.length}', 'Products', Icons.inventory_2),
                      _buildStat('Jakarta', 'Location', Icons.location_on),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Products Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Products (${_products.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Products Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = _products[index];
                  return ProductCard(
                    imagePath: (product['images'] as List?)?.first ?? '',
                    name: product['name'] ?? 'Unnamed Product',
                    price: (product['price'] as num?)?.toDouble() ?? 0.0,
                    originalPrice: (product['original_price'] as num?)?.toDouble(),
                    discountPercentage: (product['discount_percentage'] as num?)?.toDouble() ?? 0.0,
                    rating: (product['rating'] as num?)?.toDouble() ?? 0.0,
                    reviewCount: (product['review_count'] as num?)?.toInt() ?? 0,
                    storeName: _storeData?['store_name'] ?? 'Unknown Store',
                    storeLogoPath: _storeData?['store_image_url'] ?? '',
                    isFavorite: false,
                    id: product['id'],
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/product-detail',
                        arguments: {'productId': product['id']},
                      );
                    },
                    onFavoriteTap: () {},
                  );
                },
                childCount: _products.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}