import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/order_item_model.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'checkout.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];

  // Store selections tracking
  Map<String, bool> _storeSelections = {};
  // Product selections tracking
  Map<String, bool> _productSelections = {};
  // Product quantities
  Map<String, int> _quantities = {};

  // Promo code controller
  final TextEditingController _promoController = TextEditingController();

  // Stream subscription for realtime updates
  StreamSubscription<List<Map<String, dynamic>>>? _cartSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    // Initialize cart subscription for realtime updates
    CartService.initCartSubscription();

    // Load initial cart items
    await _loadCartItems();

    // Listen to cart stream for realtime updates
    _cartSubscription = CartService.cartStream?.listen(
          (items) {
        if (mounted) {
          setState(() {
            _cartItems = items;
            _updateSelectionsAndQuantities();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading cart: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _updateSelectionsAndQuantities() {
    // Update selections and quantities based on current cart items
    final newStoreSelections = <String, bool>{};
    final newProductSelections = <String, bool>{};
    final newQuantities = <String, int>{};

    for (var item in _cartItems) {
      final storeKey = item['store_name'];
      final productKey = item['id'];

      // Preserve existing selections if they exist, otherwise default to true
      newStoreSelections[storeKey] = _storeSelections[storeKey] ?? true;
      newProductSelections[productKey] = _productSelections[productKey] ?? true;
      newQuantities[productKey] = item['quantity'] ?? 1;
    }

    // Update state variables
    _storeSelections = newStoreSelections;
    _productSelections = newProductSelections;
    _quantities = newQuantities;

    // Update store selections based on product selections
    _updateStoreSelections();
  }

  void _updateStoreSelections() {
    // Group items by store and update store selection status
    Map<String, List<Map<String, dynamic>>> storeGroups = {};

    for (var item in _cartItems) {
      String storeName = item['store_name'];
      if (!storeGroups.containsKey(storeName)) {
        storeGroups[storeName] = [];
      }
      storeGroups[storeName]!.add(item);
    }

    // Update store selections based on whether all products in store are selected
    storeGroups.forEach((storeName, items) {
      bool allSelected = items.every((item) =>
      _productSelections[item['id']] == true
      );
      _storeSelections[storeName] = allSelected;
    });
  }

  Future<void> _loadCartItems() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await CartService.getCartItems();
      if (!mounted) return;

      setState(() {
        _cartItems = items;
        _updateSelectionsAndQuantities();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat keranjang'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    _cartSubscription?.cancel();
    CartService.dispose();
    super.dispose();
  }

  // Get total price of selected items
  double get _totalPrice {
    double total = 0;
    for (var item in _cartItems) {
      if (_productSelections[item['id']] == true) {
        total += item['price'] * _quantities[item['id']]!;
      }
    }
    return total;
  }

  // Get selected item count
  int get _selectedItemCount {
    return _productSelections.values.where((selected) => selected).length;
  }

  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      // Update quantity locally first for immediate UI response
      setState(() {
        _quantities[itemId] = newQuantity;
      });

      // Then update in database (realtime will sync automatically)
      await CartService.updateQuantity(itemId, newQuantity);
    } catch (e) {
      // Revert local change if API call fails
      final item = _cartItems.firstWhere((item) => item['id'] == itemId);
      setState(() {
        _quantities[itemId] = item['quantity'];
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengubah jumlah barang'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeItem(String itemId) async {
    try {
      await CartService.removeFromCart(itemId);
      // No need to manually reload - realtime subscription will handle it
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus barang'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua'),
        content: const Text('Apakah Anda yakin ingin menghapus semua barang dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CartService.clearCart();
        // No need to manually reload - realtime subscription will handle it
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus keranjang'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Silakan login terlebih dahulu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'untuk melihat keranjang belanja Anda',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Keranjang Belanja Kosong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada barang di keranjang',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Mulai Belanja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    final isLoggedIn = AuthService.getCurrentUserId() != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildLoginPrompt(),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(),
    );
  }

  Widget _buildCartContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildCartHeader(),
                ..._buildStoreGroups(),
              ],
            ),
          ),
          _buildCheckoutSection(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Keranjang',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: _cartItems.isEmpty
                ? null
                : () {
              _confirmDeleteAll();
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 24),
            tooltip: 'Hapus semua',
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '$_selectedItemCount item',
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'dipilih',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                bool allSelected = _productSelections.values.every((v) => v);
                // Toggle selection: if all are selected, unselect all; otherwise select all
                for (var key in _productSelections.keys) {
                  _productSelections[key] = !allSelected;
                }
                for (var key in _storeSelections.keys) {
                  _storeSelections[key] = !allSelected;
                }
              });
            },
            icon: Icon(
              _productSelections.values.every((v) => v)
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              size: 18,
              color: AppColors.primaryColor,
            ),
            label: Text(
              _productSelections.values.every((v) => v)
                  ? 'Batalkan Semua'
                  : 'Pilih Semua',
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStoreGroups() {
    // Group items by store
    Map<String, List<Map<String, dynamic>>> storeGroups = {};

    for (var item in _cartItems) {
      String storeName = item['store_name'];
      if (!storeGroups.containsKey(storeName)) {
        storeGroups[storeName] = [];
      }
      storeGroups[storeName]!.add(item);
    }

    List<Widget> storeWidgets = [];
    storeGroups.forEach((storeName, items) {
      storeWidgets.add(
        Column(
          children: [
            // Store header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _storeSelections[storeName] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          _storeSelections[storeName] = value ?? false;
                          // Update all products from this store
                          for (var item in items) {
                            _productSelections[item['id']] = value ?? false;
                          }
                        });
                      },
                      activeColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(items.first['storeIcon']),
                    onBackgroundImageError: (_, __) {
                      // Handle error loading store icon
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Store items
            ...items.map((item) => _buildCartItemCard(item)).toList(),
            const SizedBox(height: 8),
          ],
        ),
      );
    });

    return storeWidgets;
  }

  Widget _buildCartItemCard(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _productSelections[item['id']] ?? false,
                  onChanged: (bool? value) {
                    setState(() {
                      _productSelections[item['id']] = value ?? false;
                      // Update store selection if needed
                      bool allSelected = _cartItems
                          .where((i) => i['store_name'] == item['store_name'])
                          .every((i) => _productSelections[i['id']] ?? false);
                      _storeSelections[item['store_name']] = allSelected;
                    });
                  },
                  activeColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item['variant'] != null && item['variant'].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Variant: ${item['variant']}',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(item['price']),
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quantity controls
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            int currentQty = _quantities[item['id']] ?? 1;
                            if (currentQty > 1) {
                              _updateQuantity(item['id'], currentQty - 1);
                            }
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: (_quantities[item['id']] ?? 1) > 1
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${_quantities[item['id']] ?? 1}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            int currentQty = _quantities[item['id']] ?? 1;
                            _updateQuantity(item['id'], currentQty + 1);
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _confirmDeleteItem(item),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.primaryColor,
                          ),
                          tooltip: 'Hapus',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Barang',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus ${item['name']} dari keranjang?',
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeItem(item['id']);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Promo code input
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan kode promo',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle promo code
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Gunakan',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Total and checkout button
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formatPrice(_totalPrice),
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedItemCount > 0
                          ? () {
                                // Filter selected items
                                final selectedItems = _cartItems.where(
                                  (item) => _productSelections[item['id']] == true
                                ).toList();
                                
                                Navigator.pushNamed(
                                  context,
                                  '/checkout',
                                  arguments: {
                                    'selectedItems': selectedItems,
                                  },
                                );
                              }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Checkout ($_selectedItemCount)',
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }
}