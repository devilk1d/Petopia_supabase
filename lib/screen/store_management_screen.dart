import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';
import '../utils/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'product_form.dart';
import 'promo_form.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({Key? key}) : super(key: key);

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _promos = [];
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadStoreData();
  }

  void _handleTabChange() {
    // Force rebuild when tab changes to update FAB
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
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        _showSnackBar('Please login first');
        Navigator.pop(context);
        return;
      }

      final store = await StoreService.getStoreByUserId(userId);
      if (store == null) {
        _showSnackBar('Store not found');
        Navigator.pop(context);
        return;
      }

      final products = await StoreService.getStoreProducts(store['id']);
      final promos = await StoreService.getStorePromos(store['id']);

      if (mounted) {
        setState(() {
          _storeData = store;
          _products = products;
          _promos = promos;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildStoreAvatar(),
                      const SizedBox(height: 12),
                      Text(
                        _storeData?['store_name'] ?? 'Store Management',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your store efficiently',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: AppColors.primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Profile', icon: Icon(Icons.store, size: 20)),
                    Tab(text: 'Products', icon: Icon(Icons.inventory, size: 20)),
                    Tab(text: 'Promos', icon: Icon(Icons.local_offer, size: 20)),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStoreProfileTab(),
            _buildProductsTab(),
            _buildPromosTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildStoreAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        image: _storeData?['store_image_url'] != null
            ? DecorationImage(
          image: NetworkImage(_storeData!['store_image_url']),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: _storeData?['store_image_url'] == null
          ? const Icon(Icons.store, size: 40, color: Colors.white)
          : null,
    );
  }

  Widget _buildFAB() {
    // Hide FAB on Profile tab
    if (_tabController.index == 0) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () {
        if (_tabController.index == 1) {
          _showAddProductDialog();
        } else {
          _showAddPromoDialog();
        }
      },
      backgroundColor: AppColors.primaryColor,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        _tabController.index == 1 ? 'Add Product' : 'Add Promo',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStoreProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildProfileForm(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2,
            label: 'Products',
            value: _products.length.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_offer,
            label: 'Active Promos',
            value: _promos.length.toString(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
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
            Row(
              children: [
                Icon(Icons.edit, color: AppColors.primaryColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Store Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildImageUploadSection(),
            const SizedBox(height: 24),
            _buildTextField(_storeNameController, 'Store Name', Icons.store),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Description', Icons.description, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, 'Phone', Icons.phone),
            const SizedBox(height: 16),
            _buildTextField(_addressController, 'Address', Icons.location_on, maxLines: 2),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Center(
      child: GestureDetector(
        onTap: _updateStoreImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300, width: 2),
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
              Icon(Icons.camera_alt, size: 32, color: Colors.grey.shade500),
              const SizedBox(height: 8),
              Text(
                'Upload Image',
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
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.3),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) => value?.isEmpty ?? true ? '$label is required' : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateStoreProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return _products.isEmpty
        ? _buildEmptyState('No products yet', 'Add your first product!', Icons.inventory_2_outlined)
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductCard(_products[index]),
    );
  }

  Widget _buildPromosTab() {
    return _promos.isEmpty
        ? _buildEmptyState('No promos yet', 'Create your first promo!', Icons.local_offer_outlined)
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _promos.length,
      itemBuilder: (context, index) => _buildPromoCard(_promos[index]),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final hasImage = product['images'] != null && (product['images'] as List).isNotEmpty;
    final imageUrl = hasImage ? product['images'][0] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Hero(
          tag: 'product_${product['id']}',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
              image: imageUrl != null ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: imageUrl == null
                ? Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24)
                : null,
          ),
        ),
        title: Text(
          product['name'] ?? 'Unnamed Product',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildChip('Stock: ${product['stock']}', Colors.orange),
              const SizedBox(width: 8),
              _buildChip('Rp${product['price']}', Colors.green),
            ],
          ),
        ),
        trailing: _buildPopupMenu('product', product),
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.local_offer, color: Colors.red.shade400, size: 28),
        ),
        title: Text(
          promo['title'] ?? 'Unnamed Promo',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChip('Code: ${promo['code']}', AppColors.info),
              const SizedBox(height: 4),
              _buildChip(
                'Discount: ${promo['discount_value']}${promo['discount_type'] == 'percentage' ? '%' : ' Rp'}',
                Colors.purple,
              ),
            ],
          ),
        ),
        trailing: _buildPopupMenu('promo', promo),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == Colors.orange ? Colors.orange.shade700 :
          color == Colors.green ? Colors.green.shade700 :
          color == AppColors.info ? AppColors.info :
          color == Colors.purple ? Colors.purple.shade700 :
          color == Colors.red ? Colors.red.shade700 : color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(String type, Map<String, dynamic> item) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          type == 'product' ? _showEditProductDialog(item) : _showEditPromoDialog(item);
        } else if (value == 'delete') {
          type == 'product' ? _showDeleteProductDialog(item['id']) : _showDeletePromoDialog(item['id']);
        }
      },
    );
  }

  // Dialog Methods (unchanged functionality)
  void _showDeleteDialog(String title, String content, String id, Future<bool> Function(String) deleteFunction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
          _loadStoreData(); // Reload store data to show new image
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
}