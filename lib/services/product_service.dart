// lib/services/product_service.dart
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/auth_service.dart';

class ProductService {
  static final _client = SupabaseConfig.client;

  // Expose Supabase client for real-time subscriptions
  static SupabaseClient get supabase => _client;

  // Get all active products with pagination
  static Future<List<ProductModel>> getProducts({
    int page = 0,
    int limit = 20,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from('products')
          .select('''
            *,
            product_categories!inner (
              name
            ),
            sellers!inner (
              store_name,
              store_image_url
            )
          ''');

      // Add filters after select
      query = query.eq('is_active', true);

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      // Add ordering and pagination last
      final response = await query
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      if (response == null) return [];

      return (response as List).map((json) {
        // Add joined data to the main object
        json['category_name'] = json['product_categories']?['name'];
        json['seller_store_name'] = json['sellers']?['store_name'];
        json['seller_store_image'] = json['sellers']?['store_image_url'];

        return ProductModel.fromJson(json);
      }).toList();
    } catch (e) {
      print('ProductService error: $e');
      return [];
    }
  }

  // Get product by ID
  static Future<ProductModel?> getProductById(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select('''
            *,
            product_categories!inner (
              name
            ),
            sellers!inner (
              store_name,
              store_image_url
            )
          ''')
          .eq('id', productId)
          .eq('is_active', true)
          .single();

      if (response == null) return null;

      // Add joined data to the main object
      response['category_name'] = response['product_categories']?['name'];
      response['seller_store_name'] = response['sellers']?['store_name'];
      response['seller_store_image'] = response['sellers']?['store_image_url'];

      return ProductModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  static Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    return getProducts(categoryId: categoryId);
  }

  // Get categories
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('product_categories')
          .select()
          .order('name');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Get recommended products (top rated or recent)
  static Future<List<ProductModel>> getRecommendedProducts({int limit = 10}) async {
    try {
      final response = await _client
          .from('products')
          .select('''
            *,
            product_categories!inner (
              name
            ),
            sellers!inner (
              store_name,
              store_image_url
            )
          ''')
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(limit);

      if (response == null) return [];

      return (response as List).map((json) {
        json['category_name'] = json['product_categories']?['name'];
        json['seller_store_name'] = json['sellers']?['store_name'];
        json['seller_store_image'] = json['sellers']?['store_image_url'];

        return ProductModel.fromJson(json);
      }).toList();
    } catch (e) {
      print('ProductService error: $e');
      return [];
    }
  }

  // Search products
  static Future<List<ProductModel>> searchProducts(String query) async {
    return getProducts(searchQuery: query);
  }

  // Add product (for sellers)
  static Future<ProductModel> addProduct(ProductModel product) async {
    try {
      final response = await _client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product (for sellers)
  static Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await _client
          .from('products')
          .update(product.toJson())
          .filter('id', 'eq', product.id)
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (for sellers)
  static Future<void> deleteProduct(String productId) async {
    try {
      await _client
          .from('products')
          .update({'is_active': false})
          .filter('id', 'eq', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get products by seller
  static Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    try {
      final response = await _client
          .from('products')
          .select('''
            *,
            product_categories!inner (
              name
            ),
            sellers!inner (
              store_name,
              store_image_url
            )
          ''')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        json['category_name'] = json['product_categories']?['name'];
        json['seller_store_name'] = json['sellers']?['store_name'];
        json['seller_store_image'] = json['sellers']?['store_image_url'];

        return ProductModel.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch seller products: $e');
    }
  }

  // Upload image to Supabase storage (Same as store_service)
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Validate file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image size must be less than 5MB');
      }

      // Validate file extension
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
        throw Exception('Only JPG, PNG, GIF and WebP images are allowed');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${userId.substring(0, 8)}.$fileExt';
      final filePath = 'product_images/$fileName';

      print('\n=== Product Image Upload Debug Info ===');
      print('File path: $filePath');
      print('File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      print('File extension: $fileExt');
      print('Bucket: petopia');

      // Read file as bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();
      print('File bytes length: ${fileBytes.length}');

      // Upload to Supabase Storage
      final String uploadPath = await _client.storage
          .from('petopia')
          .uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(fileExt),
          upsert: false,
        ),
      );

      print('Upload successful, path: $uploadPath');

      // Get public URL
      final String publicUrl = _client.storage
          .from('petopia')
          .getPublicUrl(filePath);

      print('Public URL generated: $publicUrl');
      print('=== Product Image Upload Complete ===\n');

      return publicUrl;

    } catch (e) {
      print('\n=== Product Image Upload Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      if (e is StorageException) {
        print('Storage Exception Details:');
        print('- Status: ${e.statusCode}');
        print('- Error: ${e.error}');
        print('- Message: ${e.message}');
      }
      print('=== End Error ===\n');

      rethrow;
    }
  }

  // Get content type based on file extension
  static String _getContentType(String fileExt) {
    switch (fileExt.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Upload multiple product images
  static Future<List<String>> uploadProductImages(List<File> imageFiles) async {
    try {
      print('\n=== Multiple Product Images Upload Started ===');
      print('Number of images to upload: ${imageFiles.length}');

      final List<String> imageUrls = [];
      final List<String> errors = [];

      for (var i = 0; i < imageFiles.length; i++) {
        try {
          final imageFile = imageFiles[i];
          print('\n--- Uploading image ${i + 1} of ${imageFiles.length} ---');
          print('File path: ${imageFile.path}');

          final imageUrl = await uploadImage(imageFile);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            imageUrls.add(imageUrl);
            print('✅ Successfully uploaded image ${i + 1}');
            print('URL: $imageUrl');
          } else {
            throw Exception('Failed to get URL for uploaded image');
          }
        } catch (e) {
          print('❌ Error uploading image ${i + 1}: $e');
          errors.add('Image ${i + 1}: $e');
          // Continue with other images instead of failing completely
        }
      }

      print('\n=== Upload Summary ===');
      print('Successfully uploaded: ${imageUrls.length}/${imageFiles.length}');
      print('Errors: ${errors.length}');

      if (errors.isNotEmpty) {
        print('Error details:');
        errors.forEach((error) => print('- $error'));
      }

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload any images. Please check your internet connection and try again.');
      }

      print('=== Multiple Product Images Upload Complete ===\n');
      return imageUrls;

    } catch (e) {
      print('❌ Critical error in uploadProductImages: $e');
      rethrow;
    }
  }

  // Update product with new images
  static Future<bool> updateProductImages(String productId, List<File> imageFiles) async {
    try {
      print('Updating product images for product $productId');

      final imageUrls = await uploadProductImages(imageFiles);
      if (imageUrls.isEmpty) {
        print('Failed to get image URLs after upload');
        return false;
      }

      // Update product with new image URLs
      await _client
          .from('products')
          .update({
        'images': imageUrls,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', productId);

      print('Product images updated successfully');
      return true;
    } catch (e) {
      print('Error updating product images: $e');
      return false;
    }
  }

  // Add single image to existing product images
  static Future<bool> addProductImage(String productId, File imageFile) async {
    try {
      print('Adding image to product $productId');

      // Get current product data
      final productData = await _client
          .from('products')
          .select('images')
          .eq('id', productId)
          .single();

      List<String> currentImages = [];
      if (productData['images'] != null) {
        currentImages = List<String>.from(productData['images']);
      }

      // Upload new image
      final newImageUrl = await uploadImage(imageFile);
      if (newImageUrl == null) {
        print('Failed to upload new image');
        return false;
      }

      // Add new image to existing images
      currentImages.add(newImageUrl);

      // Update product with updated image list
      await _client
          .from('products')
          .update({
        'images': currentImages,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', productId);

      print('Product image added successfully');
      return true;
    } catch (e) {
      print('Error adding product image: $e');
      return false;
    }
  }

  // Remove specific image from product
  static Future<bool> removeProductImage(String productId, String imageUrl) async {
    try {
      print('Removing image from product $productId');

      // Get current product data
      final productData = await _client
          .from('products')
          .select('images')
          .eq('id', productId)
          .single();

      List<String> currentImages = [];
      if (productData['images'] != null) {
        currentImages = List<String>.from(productData['images']);
      }

      // Remove the specified image
      currentImages.remove(imageUrl);

      // Update product with updated image list
      await _client
          .from('products')
          .update({
        'images': currentImages,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', productId);

      print('Product image removed successfully');
      return true;
    } catch (e) {
      print('Error removing product image: $e');
      return false;
    }
  }

  // Get product images
  static Future<List<String>> getProductImages(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select('images')
          .eq('id', productId)
          .single();

      if (response['images'] != null) {
        return List<String>.from(response['images']);
      }
      return [];
    } catch (e) {
      print('Error fetching product images: $e');
      return [];
    }
  }
}