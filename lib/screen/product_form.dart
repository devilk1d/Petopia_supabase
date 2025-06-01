import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/store_service.dart';
import '../utils/colors.dart';
import '../utils/format.dart';

class ProductForm extends StatefulWidget {
  final Map<String, dynamic>? product;
  final String storeId;
  final Function() onSuccess;

  const ProductForm({
    Key? key,
    this.product,
    required this.storeId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _originalPriceController;
  late TextEditingController _variantNameController;
  late TextEditingController _variantPriceController;
  List<File> _selectedImages = [];
  List<String> _existingImages = [];
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _variants = [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _nameController = TextEditingController(text: widget.product?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.product?['description'] ?? '');
    _priceController = TextEditingController(text: widget.product?['price']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?['stock']?.toString() ?? '');
    _originalPriceController = TextEditingController(
      text: widget.product?['original_price']?.toString() ?? '',
    );
    _variantNameController = TextEditingController();
    _variantPriceController = TextEditingController();
    _existingImages = List<String>.from(widget.product?['images'] ?? []);
    _selectedCategoryId = widget.product?['category_id'];

    // Initialize variants from the existing product
    if (widget.product?['variants'] != null) {
      final variants = widget.product!['variants'] as Map<String, dynamic>;
      if (variants.containsKey('name') && variants.containsKey('price')) {
        final names = variants['name'] as List;
        final prices = variants['price'] as List;

        for (var i = 0; i < names.length; i++) {
          _variants.add({
            'name': names[i].toString(),
            'price': double.tryParse(prices[i].toString()) ?? 0.0,
          });
        }
      }
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await StoreService.supabase
          .from('product_categories')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response ?? []);
          _isLoadingCategories = false;
          // Pastikan _selectedCategoryId valid setelah kategori di-load
          if (_selectedCategoryId != null &&
              !_categories.any((cat) => cat['id'] == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [];
          _isLoadingCategories = false;
        });
        _showSnackBar('Failed to load categories: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF2D3748),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        setState(() {
          _selectedImages.add(file);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  void _addVariant() {
    if (_variantNameController.text.isEmpty || _variantPriceController.text.isEmpty) {
      _showSnackBar('Please enter both variant name and price');
      return;
    }

    setState(() {
      _variants.add({
        'name': _variantNameController.text,
        'price': double.parse(_variantPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')),
      });
      _variantNameController.clear();
      _variantPriceController.clear();
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      _showSnackBar('Please add at least one product image');
      return;
    }

    if (_categories.isEmpty) {
      _showSnackBar('No categories available. Please add categories first.');
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      _showSnackBar('Please select a category');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Calculate discount percentage if original price is provided
      double? discountPercentage;
      if (_originalPriceController.text.isNotEmpty) {
        final originalPrice = double.parse(_originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
        final price = double.parse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
        discountPercentage = ((originalPrice - price) / originalPrice) * 100;
      }

      // Upload images first
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          imageUrls = await StoreService.uploadProductImages(_selectedImages);
        } catch (uploadError) {
          throw Exception('Failed to upload images. Please check your internet connection and try again.');
        }
      }

      final allImages = [..._existingImages, ...imageUrls];

      if (allImages.isEmpty) {
        throw Exception('No images available for the product. Please add at least one image.');
      }

      // Transform variants to the correct format for database
      Map<String, List<String>>? transformedVariants;
      if (_variants.isNotEmpty) {
        transformedVariants = {
          'name': _variants.map((v) => v['name'].toString()).toList(),
          'price': _variants.map((v) => v['price'].toString()).toList(),
        };
      } else {
        transformedVariants = null;
      }

      Map<String, dynamic>? result;
      if (widget.product == null) {
        // Add new product
        result = await StoreService.addProduct(
          storeId: widget.storeId,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')),
          stock: int.parse(_stockController.text),
          categoryId: _selectedCategoryId!,
          images: allImages,
          originalPrice: _originalPriceController.text.isNotEmpty
              ? double.parse(_originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''))
              : null,
          discountPercentage: discountPercentage,
          variants: transformedVariants,
        );
      } else {
        // Update existing product
        final success = await StoreService.updateProduct(
          widget.product!['id'],
          {
            'name': _nameController.text,
            'description': _descriptionController.text,
            'price': double.parse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')),
            'stock': int.parse(_stockController.text),
            'category_id': _selectedCategoryId,
            'images': allImages,
            'original_price': _originalPriceController.text.isNotEmpty
                ? double.parse(_originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''))
                : null,
            'discount_percentage': discountPercentage ?? 0,
            'variants': transformedVariants,
          },
        );

        if (!success) {
          throw Exception('Failed to update product in database');
        }
      }

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = 'Error saving product';

      if (e.toString().contains('upload')) {
        errorMessage = 'Failed to upload images. Please check your internet connection and try again.';
      } else if (e.toString().contains('database')) {
        errorMessage = 'Failed to save product details. Please try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check your login status and try again.';
      }

      _showSnackBar(errorMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Header Section with full screen background
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 80,
                left: 24,
                right: 24,
                bottom: 32,
              ),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
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
                          widget.product == null ? 'Add Product' : 'Edit Product',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product == null ? 'Create a new product' : 'Update product details',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
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
            ),

            // Form Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Upload Section
                    _buildImageUploadCard(),
                    const SizedBox(height: 16),

                    // Basic Information
                    _buildBasicInfoCard(),
                    const SizedBox(height: 16),

                    // Pricing & Stock
                    _buildPricingCard(),
                    const SizedBox(height: 16),

                    // Variants
                    _buildVariantsCard(),
                    const SizedBox(height: 24),

                    // Save Button
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadCard() {
    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Product Images',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Add image button
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 24, color: AppColors.primaryColor),
                          const SizedBox(height: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Existing images
                  ..._existingImages.map((imageUrl) => _buildImagePreview(
                    imageUrl: imageUrl,
                    onRemove: () => setState(() => _existingImages.remove(imageUrl)),
                  )).toList(),

                  // Selected images
                  ..._selectedImages.map((file) => _buildImagePreview(
                    file: file,
                    onRemove: () => setState(() => _selectedImages.remove(file)),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview({String? imageUrl, File? file, required VoidCallback onRemove}) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: Icon(Icons.error_outline, color: Colors.grey[400]),
                ),
              )
                  : Image.file(
                file!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: Icon(Icons.error_outline, color: Colors.grey[400]),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outlined, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Product Name',
              icon: Icons.inventory_2_outlined,
              validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money_outlined, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Pricing & Stock',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _originalPriceController,
              label: 'Original Price (optional)',
              icon: Icons.money_off_outlined,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return 'Please enter a valid number';
                  // int.parse(digits); // validasi parse jika perlu
                }
                return null;
              },
              isPrice: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Selling Price',
              icon: Icons.attach_money_outlined,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter price';
                String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'Please enter a valid number';
                // int.parse(digits);
                return null;
              },
              isPrice: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _stockController,
              label: 'Stock',
              icon: Icons.inventory_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter stock';
                if (int.tryParse(value!) == null) return 'Please enter a valid number';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsCard() {
    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Product Variants',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _variantNameController,
                    style: const TextStyle(fontFamily: 'SF Pro Display'),
                    decoration: InputDecoration(
                      hintText: 'e.g., Large Size',
                      hintStyle: const TextStyle(fontFamily: 'SF Pro Display'),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _variantPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontFamily: 'SF Pro Display'),
                    decoration: InputDecoration(
                      hintText: '50000',
                      hintStyle: const TextStyle(fontFamily: 'SF Pro Display'),
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontFamily: 'SF Pro Display'),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.isEmpty) {
                        _variantPriceController.text = '';
                      } else {
                        _variantPriceController.text = formatRupiah(int.parse(digits));
                      }
                      _variantPriceController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _variantPriceController.text.length),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _addVariant,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_variants.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Added Variants:',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _variants.length,
                itemBuilder: (context, index) {
                  final variant = _variants[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant['name'],
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Rp${variant['price']}',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _removeVariant(index),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
    bool isPrice = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontFamily: 'SF Pro Display'),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
            prefixText: prefixText,
            prefixStyle: const TextStyle(fontFamily: 'SF Pro Display'),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: isPrice
              ? (value) {
                  String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) {
                    controller.text = '';
                  } else {
                    controller.text = formatRupiah(int.parse(digits));
                  }
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        if (_isLoadingCategories)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              color: Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.category_outlined,
                  color: Color(0xFF6B7280), size: 20),
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
            items: _categories.isEmpty
                ? [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'No categories available',
                        style: TextStyle(fontFamily: 'SF Pro Display'),
                      ),
                    )
                  ]
                : _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'],
                      child: Text(
                        category['name'] ?? 'Unknown Category',
                        style: const TextStyle(fontFamily: 'SF Pro Display'),
                      ),
                    );
                  }).toList(),
            onChanged: _isSubmitting || _categories.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
            validator: (value) {
              if (_categories.isEmpty) {
                return 'No categories available. Please add categories first.';
              }
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Save Product',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _originalPriceController.dispose();
    _variantNameController.dispose();
    _variantPriceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}