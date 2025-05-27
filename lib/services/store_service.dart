import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';
import 'dart:io';
import 'dart:typed_data';

class StoreService {
  static final _client = SupabaseConfig.client;

  // Expose Supabase client for real-time subscriptions
  static SupabaseClient get supabase => _client;

  // Register a new store
  static Future<Map<String, dynamic>> registerStore({
    required String storeName,
    required String storeDescription,
    required String phone,
    required String address,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Check if user has reached store limit (max 3)
      final existingStores = await _client
          .from('sellers')
          .select()
          .eq('user_id', userId);

      if ((existingStores as List).length >= 3) {
        throw Exception('Maximum number of stores (3) reached');
      }

      // Insert new store
      final response = await _client
          .from('sellers')
          .insert({
        'user_id': userId,
        'store_name': storeName,
        'store_description': storeDescription,
        'phone': phone,
        'address': address,
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error registering store: $e');
      rethrow;
    }
  }

  // Get store by ID
  static Future<Map<String, dynamic>?> getStoreById(String storeId) async {
    try {
      final response = await _client
          .from('sellers')
          .select()
          .eq('id', storeId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching store: $e');
      return null;
    }
  }

  // Get store by user ID
  static Future<Map<String, dynamic>?> getStoreByUserId(String userId) async {
    try {
      final response = await _client
          .from('sellers')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching store: $e');
      return null;
    }
  }

  // Update store
  static Future<bool> updateStore(String storeId, Map<String, dynamic> data) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      await _client
          .from('sellers')
          .update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', storeId)
          .eq('user_id', userId); // Ensure user owns the store

      return true;
    } catch (e) {
      print('Error updating store: $e');
      return false;
    }
  }

  // Get store products
  static Future<List<Map<String, dynamic>>> getStoreProducts(String storeId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('seller_id', storeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching store products: $e');
      return [];
    }
  }

  // Add product
  static Future<Map<String, dynamic>?> addProduct({
    required String storeId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<String>? images,
    double? originalPrice,
    double? discountPercentage,
    Map<String, List<String>>? variants,
  }) async {
    try {
      final response = await _client
          .from('products')
          .insert({
        'seller_id': storeId,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'category_id': categoryId,
        'images': images ?? [],
        'original_price': originalPrice,
        'discount_percentage': discountPercentage ?? 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'variants': variants,
      })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error adding product: $e');
      return null;
    }
  }

  // Update product
  static Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _client
          .from('products')
          .update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', productId);

      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _client
          .from('products')
          .delete()
          .eq('id', productId);

      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Get store promos
  static Future<List<Map<String, dynamic>>> getStorePromos(String storeId) async {
    try {
      final response = await _client
          .from('promos')
          .select()
          .eq('seller_id', storeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching store promos: $e');
      return [];
    }
  }

  // Add promo
  static Future<Map<String, dynamic>?> addPromo({
    required String storeId,
    required String code,
    required String title,
    required String description,
    required String discountType,
    required double discountValue,
    double? minPurchase,
    double? maxDiscount,
    int? usageLimit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client
          .from('promos')
          .insert({
        'seller_id': storeId,
        'code': code,
        'title': title,
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_purchase': minPurchase ?? 0,
        'max_discount': maxDiscount,
        'usage_limit': usageLimit,
        'start_date': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error adding promo: $e');
      return null;
    }
  }

  // Update promo
  static Future<bool> updatePromo(String promoId, Map<String, dynamic> data) async {
    try {
      await _client
          .from('promos')
          .update(data)
          .eq('id', promoId);

      return true;
    } catch (e) {
      print('Error updating promo: $e');
      return false;
    }
  }

  // Delete promo
  static Future<bool> deletePromo(String promoId) async {
    try {
      await _client
          .from('promos')
          .delete()
          .eq('id', promoId);

      return true;
    } catch (e) {
      print('Error deleting promo: $e');
      return false;
    }
  }

  // Upload image to Supabase storage (Fixed Version)
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

      print('\n=== Image Upload Debug Info ===');
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
      print('=== Upload Complete ===\n');

      return publicUrl;

    } catch (e) {
      print('\n=== Upload Error ===');
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

  // Upload store image
  static Future<bool> updateStoreImage(String storeId, File imageFile) async {
    try {
      print('Updating store image for store $storeId');

      final imageUrl = await uploadImage(imageFile);
      if (imageUrl == null) {
        print('Failed to get image URL after upload');
        return false;
      }

      final success = await updateStore(storeId, {'store_image_url': imageUrl});
      print(success ? 'Store image updated successfully' : 'Failed to update store data with new image');
      return success;
    } catch (e) {
      print('Error updating store image: $e');
      return false;
    }
  }

  // Upload product images (Fixed Version)
  static Future<List<String>> uploadProductImages(List<File> imageFiles) async {
    try {
      print('\n=== Product Images Upload Started ===');
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

      print('=== Product Images Upload Complete ===\n');
      return imageUrls;

    } catch (e) {
      print('❌ Critical error in uploadProductImages: $e');
      rethrow;
    }
  }
}