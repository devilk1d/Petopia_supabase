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

      final orders = orderModels.map((order) => {
        'id': order.id,
        'order_number': order.orderNumber,
        'status': order.status,
        'created_at': order.createdAt.toIso8601String(),
        'order_items': order.items.map((item) => {
          'id': item.id,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.price,
          'variant': item.variant,
          'products': {
            'name': item.productName,
            'images': [item.productImage],
          },
        }).toList(),
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
      }
    } catch (e) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF2D3748),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8FAFC),
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
                                    _storeData?['store_name'] ?? 'My Store',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
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

  Widget _buildModernFAB() {
    if (_tabController.index == 0 || _tabController.index == 3) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 1) {
          _showAddProductDialog();
        } else {
          _showAddPromoDialog();
        }
      },
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 24),
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

  Widget _buildModernStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            value: _products.length.toString(),
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.local_offer_outlined,
            label: 'Promos',
            value: _promos.length.toString(),
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernStatCard(
            icon: Icons.shopping_bag_outlined,
            label: 'Orders',
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
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
              'Store Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            _buildModernImageUpload(),
            const SizedBox(height: 20),
            _buildModernTextField(_storeNameController, 'Store Name', Icons.store_outlined),
            const SizedBox(height: 16),
            _buildModernTextField(_descriptionController, 'Description', Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 16),
            _buildModernTextField(_phoneController, 'Phone', Icons.phone_outlined),
            const SizedBox(height: 16),
            _buildModernTextField(_addressController, 'Address', Icons.location_on_outlined, maxLines: 2),
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
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
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
                'Upload',
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
              borderRadius: BorderRadius.circular(12),
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
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value?.isEmpty ?? true ? '$label is required' : null,
        ),
      ],
    );
  }

  Widget _buildModernSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateStoreProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProductsTab() {
    return _products.isEmpty
        ? _buildModernEmptyState('No products yet', 'Add your first product to get started!', Icons.inventory_2_outlined)
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildModernProductCard(_products[index]),
    );
  }

  Widget _buildModernPromosTab() {
    return _promos.isEmpty
        ? _buildModernEmptyState('No promos yet', 'Create your first promotional offer!', Icons.local_offer_outlined)
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _promos.length,
      itemBuilder: (context, index) => _buildModernPromoCard(_promos[index]),
    );
  }

  Widget _buildModernOrdersTab() {
    if (_orders.isEmpty) {
      return _buildModernEmptyState(
        'No Orders Yet',
        'You haven\'t received any orders yet',
        Icons.shopping_bag_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final orderItems = order['order_items'] as List;
        final status = order['status'] as String;
        final orderNumber = order['order_number'] as String;
        final orderDate = DateTime.parse(order['created_at'] as String);
        final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #$orderNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...orderItems.map((item) {
                  final product = item['products'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product['images'][0] ?? '',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Unknown Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${item['quantity']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 12),
                if (status == 'processing' || status == 'waiting_shipment')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'shipped'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Kirimkan Barang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (status == 'shipped')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'delivered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Terima',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    product['name'] ?? 'Unnamed Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildModernChip(
                        'Stock: ${product['stock']}',
                        const Color(0xFF3B82F6),
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
            // Direct Edit and Delete buttons
            Row(
              children: [
                InkWell(
                  onTap: () => _showEditProductDialog(product),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showDeleteProductDialog(product['id']),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                  ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                    promo['title'] ?? 'Unnamed Promo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernChip(
                        'Code: ${promo['code']}',
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 4),
                      _buildModernChip(
                        'Discount: ${promo['discount_value']}${promo['discount_type'] == 'percentage' ? '%' : ' Rp'}',
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Direct Edit and Delete buttons
            Row(
              children: [
                InkWell(
                  onTap: () => _showEditPromoDialog(promo),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showDeletePromoDialog(promo['id']),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final success = await deleteFunction(id);
                if (!mounted) return;
                setState(() => _isLoading = false);
                _showSnackBar(success
                    ? '${title.split(' ')[1]} deleted successfully'
                    : 'Failed to delete ${title.toLowerCase().split(' ')[1]}');
                if (success) _loadStoreData();
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
                _showSnackBar('Error deleting ${title.toLowerCase().split(' ')[1]}: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w600,
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
          _showSnackBar('Store image updated successfully');
          _loadStoreData();
        } else {
          _showSnackBar('Failed to update store image');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error updating store image: $e');
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
      _showSnackBar(success ? 'Store profile updated successfully' : 'Failed to update store profile');
      if (success) _loadStoreData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error updating store profile: $e');
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => ProductForm(
        storeId: _storeData!['id'],
        onSuccess: () {
          _loadStoreData();
          _showSnackBar('Product added successfully');
        },
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => ProductForm(
        product: product,
        storeId: _storeData!['id'],
        onSuccess: () {
          _loadStoreData();
          _showSnackBar('Product updated successfully');
        },
      ),
    );
  }

  void _showAddPromoDialog() {
    showDialog(
      context: context,
      builder: (context) => PromoForm(
        storeId: _storeData!['id'],
        onSuccess: () {
          _loadStoreData();
          _showSnackBar('Promo added successfully');
        },
      ),
    );
  }

  void _showEditPromoDialog(Map<String, dynamic> promo) {
    showDialog(
      context: context,
      builder: (context) => PromoForm(
        promo: promo,
        storeId: _storeData!['id'],
        onSuccess: () {
          _loadStoreData();
          _showSnackBar('Promo updated successfully');
        },
      ),
    );
  }

  void _showDeleteProductDialog(String productId) =>
      _showDeleteDialog('Delete Product', 'Are you sure you want to delete this product?', productId, StoreService.deleteProduct);
  void _showDeletePromoDialog(String promoId) =>
      _showDeleteDialog('Delete Promo', 'Are you sure you want to delete this promo?', promoId, StoreService.deletePromo);

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await OrderService.updateOrderStatus(orderId, status, widget.storeId);
      await _loadStoreData();
      _showSnackBar('Order status updated successfully');
    } catch (e) {
      _showSnackBar('Error updating order status: $e');
    }
  }
}