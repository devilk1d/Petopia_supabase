import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/store_service.dart';
import '../utils/colors.dart';

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

      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      print('Opening image picker...');
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('Image selected:');
        print('- Path: ${image.path}');
        print('- Name: ${image.name}');
        
        final file = File(image.path);
        final size = await file.length();
        print('- Size: ${size / 1024} KB');
        
        setState(() {
          _selectedImages.add(file);
        });
        print('Image added to selected images list');
        print('- Total selected images: ${_selectedImages.length}');
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addVariant() {
    if (_variantNameController.text.isEmpty || _variantPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both variant name and price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _variants.add({
        'name': _variantNameController.text,
        'price': double.parse(_variantPriceController.text),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Calculate discount percentage if original price is provided
      double? discountPercentage;
      if (_originalPriceController.text.isNotEmpty) {
        final originalPrice = double.parse(_originalPriceController.text);
        final price = double.parse(_priceController.text);
        discountPercentage = ((originalPrice - price) / originalPrice) * 100;
      }

      // Upload images first
      print('\nStarting form submission process...');
      print('Selected images count: ${_selectedImages.length}');
      print('Existing images count: ${_existingImages.length}');
      
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          imageUrls = await StoreService.uploadProductImages(_selectedImages);
          print('Image upload completed');
          print('Successfully uploaded URLs: ${imageUrls.length}');
          print('URLs: $imageUrls');
        } catch (uploadError) {
          print('Error during image upload: $uploadError');
          throw Exception('Failed to upload images. Please check your internet connection and try again.');
        }
      }

      final allImages = [..._existingImages, ...imageUrls];
      print('Total images for product: ${allImages.length}');

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
      }

      Map<String, dynamic>? result;
      if (widget.product == null) {
        // Add new product
        print('Adding new product with images');
        result = await StoreService.addProduct(
          storeId: widget.storeId,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          categoryId: _selectedCategoryId!,
          images: allImages,
          originalPrice: _originalPriceController.text.isNotEmpty
              ? double.parse(_originalPriceController.text)
              : null,
          discountPercentage: discountPercentage,
          variants: transformedVariants,
        );
        
        print('Product added successfully: ${result?['id']}');
      } else {
        // Update existing product
        print('Updating existing product: ${widget.product!['id']}');
        final success = await StoreService.updateProduct(
          widget.product!['id'],
          {
            'name': _nameController.text,
            'description': _descriptionController.text,
            'price': double.parse(_priceController.text),
            'stock': int.parse(_stockController.text),
            'category_id': _selectedCategoryId,
            'images': allImages,
            'original_price': _originalPriceController.text.isNotEmpty
                ? double.parse(_originalPriceController.text)
                : null,
            'discount_percentage': discountPercentage ?? 0,
            'variants': transformedVariants,
          },
        );
        
        print('Product update status: $success');
        if (!success) {
          throw Exception('Failed to update product in database');
        }
      }

      widget.onSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error in form submission: $e');
      if (mounted) {
        String errorMessage = 'Error saving product';
        
        // Provide more specific error messages
        if (e.toString().contains('upload')) {
          errorMessage = 'Failed to upload images. Please check your internet connection and try again.';
        } else if (e.toString().contains('database')) {
          errorMessage = 'Failed to save product details. Please try again.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please check your login status and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Add image button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
                      const SizedBox(height: 4),
                      Text(
                        'Add Image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Existing images
              ..._existingImages.map((imageUrl) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.error, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _existingImages.remove(imageUrl);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )).toList(),
              
              // Selected images
              ..._selectedImages.map((file) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.error, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImages.remove(file);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          prefixText: prefixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          filled: true,
          fillColor: AppColors.greyColor,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Variants',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _variantNameController,
                decoration: const InputDecoration(
                  labelText: 'Variant Name',
                  hintText: 'e.g., Large Size',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _variantPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g., 50000',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addVariant,
              icon: const Icon(Icons.add_circle),
              color: AppColors.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_variants.isNotEmpty) ...[
          const Text(
            'Added Variants:',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            itemBuilder: (context, index) {
              final variant = _variants[index];
              return Card(
                child: ListTile(
                  title: Text(variant['name']),
                  subtitle: Text('Rp${variant['price']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeVariant(index),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.backgroundColor),
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.product == null ? 'Add Product' : 'Edit Product',
                style: const TextStyle(
                  color: AppColors.backgroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradient(AppColors.primaryColor),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _buildFormSection(
                      title: 'Basic Information',
                      icon: Icons.info_outline,
                      children: [
                        _buildTextFormField(
                          controller: _nameController,
                          labelText: 'Product Name',
                          icon: Icons.inventory_2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter product name';
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          controller: _descriptionController,
                          labelText: 'Description',
                          icon: Icons.description,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter description';
                            }
                            return null;
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category, color: AppColors.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                              ),
                              filled: true,
                              fillColor: AppColors.greyColor,
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                            ),
                            items: _isLoadingCategories
                                ? [const DropdownMenuItem<String>(value: null, child: Text('Loading...'))]
                                : _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category['id'],
                                child: Text(category['name']),
                              );
                            }).toList(),
                            onChanged: _isLoadingCategories || _isSubmitting
                                ? null
                                : (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    _buildFormSection(
                      title: 'Pricing & Stock',
                      icon: Icons.attach_money,
                      children: [
                        _buildTextFormField(
                          controller: _originalPriceController,
                          labelText: 'Original Price (optional)',
                          icon: Icons.money_off,
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          controller: _priceController,
                          labelText: 'Selling Price',
                          icon: Icons.attach_money,
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          controller: _stockController,
                          labelText: 'Stock',
                          icon: Icons.inventory,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter stock';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildVariantSection(),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient(AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.backgroundColor,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Save Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.backgroundColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
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