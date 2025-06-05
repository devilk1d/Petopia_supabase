import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';
import '../utils/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'product_form.dart';
import 'promo_form.dart';
import '../services/order_service.dart';
import '../utils/format.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreManagementScreen extends StatefulWidget {
  final String storeId;
  static String? activeStoreId;
  const StoreManagementScreen({Key? key, required this.storeId}) : super(key: key);

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _promos = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  // Add this variable to track expanded orders
  Map<String, bool> _expandedOrders = {};

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadStoreData();
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _storeNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeFormControllers() {
    if (_storeData != null) {
      _storeNameController.text = _storeData!['store_name'] ?? '';
      _descriptionController.text = _storeData!['store_description'] ?? '';
      _phoneController.text = _storeData!['phone'] ?? '';
      _addressController.text = _storeData!['address'] ?? '';
    }
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final store = await StoreService.getStoreById(widget.storeId);
      if (store == null) {
        _showSnackBar('Store not found');
        Navigator.pop(context);
        return;
      }

      final products = await StoreService.getStoreProducts(store['id']);
      final promos = await StoreService.getStorePromos(store['id']);
      final orderModels = await OrderService.getOrdersBySeller(store['id']);

      // Fixed: Properly convert OrderModel to Map with correct item processing
      final orders = orderModels.map((order) {
        print('Processing order: ${order.id} with ${order.items.length} items');

        return {
          'id': order.id,
          'order_number': order.orderNumber,
          'status': order.status,
          'created_at': order.createdAt.toIso8601String(),
          'order_items': order.items.map((item) {
            print('Processing item: ${item.id} - ${item.productName}');

            return {
              'id': item.id,
              'product_id': item.productId,
              'quantity': item.quantity,
              'price': item.price,
              'variant': item.variant ?? '',
              'products': {
                'name': item.productName ?? 'Unknown Product',
                'images': item.productImage != null ? [item.productImage] : [],
              },
            };
          }).toList(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _storeData = store;
          _products = products;
          _promos = promos;
          _orders = orders;
          _isLoading = false;
        });
        _initializeFormControllers();

        print('Loaded ${_orders.length} orders');
        for (var order in _orders) {
          print('Order ${order['order_number']}: ${(order['order_items'] as List).length} items');
        }
      }
    } catch (e) {
      print('Error loading store data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.primaryColor,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8F9FA),
                      Colors.white,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildModernStoreAvatar(),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _storeData?['store_name'] ?? 'Toko Saya',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Store Management',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: AppColors.primaryColor,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Products'),
                    Tab(text: 'Promos'),
                    Tab(text: 'Orders'),
                  ],
                ),
              ),
            ),
          ),
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModernStoreProfileTab(),
                _buildModernProductsTab(),
                _buildModernPromosTab(),
                _buildModernOrdersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildModernFAB() {
    if (_tabController.index == 0 || _tabController.index == 3) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 1) {
            _showAddProductDialog();
          } else {
            _showAddPromoDialog();
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildModernStoreProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernStatsCards(),
          const SizedBox(height: 20),
          _buildModernProfileForm(),
        ],
      ),
    );
  }

  Widget _buildStoreInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModernStoreAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _storeData?['store_name'] ?? 'Toko Saya',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola toko Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStoreAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        image: _storeData?['store_image_url'] != null
            ? DecorationImage(
          image: NetworkImage(_storeData!['store_image_url']),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: _storeData?['store_image_url'] == null
          ? Icon(Icons.store_rounded, size: 28, color: Colors.grey.shade500)
          : null,
    );
  }

  Widget _buildModernStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Produk',
            value: _products.length.toString(),
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.local_offer_outlined,
            label: 'Promo',
            value: _promos.length.toString(),
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.shopping_bag_outlined,
            label: 'Pesanan',
            value: _orders.length.toString(),
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfileForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Toko',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildModernImageUpload(),
            const SizedBox(height: 20),
            _buildModernTextField(_storeNameController, 'Nama Toko', Icons.store_outlined),
            const SizedBox(height: 16),
            _buildModernTextField(_descriptionController, 'Deskripsi', Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 16),
            _buildModernTextField(_phoneController, 'Nomor Telepon', Icons.phone_outlined),
            const SizedBox(height: 16),
            _buildModernTextField(_addressController, 'Alamat', Icons.location_on_outlined, maxLines: 2),
            const SizedBox(height: 24),
            _buildModernSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernImageUpload() {
    return Center(
      child: GestureDetector(
        onTap: _updateStoreImage,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            image: _storeData?['store_image_url'] != null
                ? DecorationImage(
              image: NetworkImage(_storeData!['store_image_url']),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: _storeData?['store_image_url'] == null
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, size: 24, color: Colors.grey.shade500),
              const SizedBox(height: 4),
              Text(
                'Unggah',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
              : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withOpacity(0.4),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => value?.isEmpty ?? true ? '$label harus diisi' : null,
        ),
      ],
    );
  }

  Widget _buildModernSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _updateStoreProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Simpan Perubahan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProductsTab() {
    return _products.isEmpty
        ? _buildModernEmptyState('Belum ada produk', 'Tambahkan produk pertama Anda!', Icons.inventory_2_outlined)
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildModernProductCard(_products[index]),
    );
  }

  Widget _buildModernPromosTab() {
    return _promos.isEmpty
        ? _buildModernEmptyState('Belum ada promo', 'Buat penawaran promosi pertama Anda!', Icons.local_offer_outlined)
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _promos.length,
      itemBuilder: (context, index) => _buildModernPromoCard(_promos[index]),
    );
  }

  Widget _buildModernOrdersTab() {
    if (_orders.isEmpty) {
      return _buildModernEmptyState(
        'Belum Ada Pesanan',
        'Anda belum menerima pesanan apapun',
        Icons.shopping_bag_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];

        // Safe casting with null check
        final orderItemsList = order['order_items'];
        final orderItems = orderItemsList is List ? orderItemsList : <Map<String, dynamic>>[];

        final status = order['status'] as String? ?? 'unknown';
        final orderNumber = order['order_number'] as String? ?? 'Unknown';
        final orderId = order['id'] as String? ?? '';

        DateTime orderDate;
        try {
          orderDate = DateTime.parse(order['created_at'] as String);
        } catch (e) {
          orderDate = DateTime.now();
        }

        final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year}';
        final isExpanded = _expandedOrders[orderId] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Order Header
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedOrders[orderId] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pesanan #$orderNumber',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Order Summary - Fixed to show correct item count
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                              color: AppColors.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${orderItems.length} item${orderItems.length > 1 ? '' : ''}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isExpanded ? 'Tutup detail' : 'Lihat detail',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Order Items
              if (isExpanded) ...[
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Item Pesanan:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Order Items List - Fixed processing
                      ...orderItems.map<Widget>((item) {
                        final products = item['products'] as Map<String, dynamic>? ?? {};
                        final quantity = item['quantity'] as int? ?? 0;
                        final price = ((item['price'] as num?) ?? 0).toDouble();
                        final variant = (item['variant'] as String?) ?? '';
                        final totalItemPrice = quantity * price;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Product Image
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _buildProductImage(products),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      products['name'] as String? ?? 'Produk Tidak Diketahui',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (variant.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Varian: $variant',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Qty: $quantity',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          ' × ${formatRupiah(price)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Item Total Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatRupiah(totalItemPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // Action Button
                      if (status == 'processing' || status == 'waiting_shipment') ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [AppColors.primaryColor, AppColors.primaryDark],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _updateOrderStatus(orderId, 'shipped'),
                            icon: const Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Kirimkan Barang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Helper method to build product image with proper error handling
  Widget _buildProductImage(Map<String, dynamic> products) {
    final imagesList = products['images'];

    if (imagesList is List && imagesList.isNotEmpty) {
      final imageUrl = imagesList[0] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey,
            );
          },
        );
      }
    }

    return const Icon(
      Icons.image_not_supported_outlined,
      color: Colors.grey,
    );
  }

  Widget _buildModernEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProductCard(Map<String, dynamic> product) {
    final hasImage = product['images'] != null && (product['images'] as List).isNotEmpty;
    final imageUrl = hasImage ? product['images'][0] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF8F9FA),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                image: imageUrl != null ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: imageUrl == null
                  ? Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Produk Tanpa Nama',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildModernChip(
                        'Stok: ${product['stock']}',
                        AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        formatRupiah(product['price']),
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              children: [
                _buildActionButton(
                  Icons.edit_outlined,
                  Colors.grey.shade600,
                      () => _showEditProductDialog(product),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.delete_outline,
                  const Color(0xFFEF4444),
                      () => _showDeleteProductDialog(product['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPromoCard(Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_offer_outlined,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo['title'] ?? 'Promo Tanpa Nama',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernChip(
                        'Kode: ${promo['code']}',
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 4),
                      _buildModernChip(
                        'Diskon: ${promo['discount_value']}${promo['discount_type'] == 'percentage' ? '%' : ' Rp'}',
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              children: [
                _buildActionButton(
                  Icons.edit_outlined,
                  Colors.grey.shade600,
                      () => _showEditPromoDialog(promo),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.delete_outline,
                  const Color(0xFFEF4444),
                      () => _showDeletePromoDialog(promo['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  Widget _buildModernChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting_shipment':
        return const Color(0xFFF59E0B);
      case 'shipped':
        return const Color(0xFF3B82F6);
      case 'delivered':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting_shipment':
        return 'Menunggu Pengiriman';
      case 'shipped':
        return 'Dalam Perjalanan';
      case 'delivered':
        return 'Selesai';
      default:
        return status;
    }
  }

  // Dialog Methods
  void _showDeleteDialog(String title, String content, String id, Future<bool> Function(String) deleteFunction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  final success = await deleteFunction(id);
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  _showSnackBar(success
                      ? '${title.split(' ')[1]} berhasil dihapus'
                      : 'Gagal menghapus ${title.toLowerCase().split(' ')[1]}');
                  if (success) _loadStoreData();
                } catch (e) {
                  if (!mounted) return;
                  setState(() => _isLoading = false);
                  _showSnackBar('Error menghapus ${title.toLowerCase().split(' ')[1]}: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Existing methods with same functionality
  Future<void> _updateStoreImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        final file = File(image.path);

        final success = await StoreService.updateStoreImage(
          _storeData!['id'],
          file,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (success) {
          _showSnackBar('Gambar toko berhasil diperbarui');
          _loadStoreData();
        } else {
          _showSnackBar('Gagal memperbarui gambar toko');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error memperbarui gambar toko: $e');
    }
  }

  Future<void> _updateStoreProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final success = await StoreService.updateStore(_storeData!['id'], {
        'store_name': _storeNameController.text,
        'store_description': _descriptionController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(success ? 'Profil toko berhasil diperbarui' : 'Gagal memperbarui profil toko');
      if (success) _loadStoreData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error memperbarui profil toko: $e');
    }
  }

  void _showAddProductDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductForm(
          storeId: _storeData!['id'],
          onSuccess: () {
            _loadStoreData();
            _showSnackBar('Produk berhasil ditambahkan');
            Navigator.pop(context);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductForm(
          product: product,
          storeId: _storeData!['id'],
          onSuccess: () {
            _loadStoreData();
            _showSnackBar('Produk berhasil diperbarui');
            Navigator.pop(context);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showAddPromoDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromoForm(
          storeId: _storeData!['id'],
          onSuccess: () {
            _loadStoreData();
            _showSnackBar('Promo berhasil ditambahkan');
            Navigator.pop(context);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showEditPromoDialog(Map<String, dynamic> promo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromoForm(
          promo: promo,
          storeId: _storeData!['id'],
          onSuccess: () {
            _loadStoreData();
            _showSnackBar('Promo berhasil diperbarui');
            Navigator.pop(context);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showDeleteProductDialog(String productId) =>
      _showDeleteDialog('Hapus Produk', 'Apakah Anda yakin ingin menghapus produk ini?', productId, StoreService.deleteProduct);
  void _showDeletePromoDialog(String promoId) =>
      _showDeleteDialog('Hapus Promo', 'Apakah Anda yakin ingin menghapus promo ini?', promoId, StoreService.deletePromo);

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await OrderService.updateOrderStatus(orderId, status, widget.storeId);
      await _loadStoreData();
      _showSnackBar('Status pesanan berhasil diperbarui');
    } catch (e) {
      _showSnackBar('Error memperbarui status pesanan: $e');
    }
  }
}