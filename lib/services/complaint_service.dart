// lib/services/complaint_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintService {
  static final _client = SupabaseConfig.client;
  static const _uuid = Uuid();

  // Submit complaint with image upload
  static Future<bool> submitComplaint({
    required String orderId,
    required String reason,
    required String description,
    File? imageFile,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      print('Submitting complaint for order: $orderId');
      print('Reason: $reason');
      print('Description: $description');
      print('Has image: ${imageFile != null}');

      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadComplaintImage(imageFile);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
        print('Image uploaded successfully: $imageUrl');
      }

      // Create images array - ensure it's always List<String>
      final List<String> imagesArray = imageUrl != null ? [imageUrl] : [];

      // Create complaint data with explicit types
      final Map<String, dynamic> complaintData = <String, dynamic>{
        'user_id': userId,
        'order_id': orderId,
        'reason': reason,
        'description': description,
        'images': imagesArray,  // This is explicitly List<String>
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Inserting complaint data: $complaintData');
      print('Images array type: ${imagesArray.runtimeType}');
      print('Images array content: $imagesArray');

      // Insert complaint to database
      final response = await _client
          .from('complaints')
          .insert(complaintData)
          .select()
          .single();

      print('Complaint submitted successfully: ${response['id']}');
      return true;
    } catch (e) {
      print('Error submitting complaint: $e');
      print('Error type: ${e.runtimeType}');

      // Handle specific errors
      if (e.toString().contains('violates foreign key constraint')) {
        throw Exception('Order tidak ditemukan atau tidak valid');
      } else if (e.toString().contains('violates row-level security policy')) {
        throw Exception('Anda tidak memiliki izin untuk membuat complaint pada order ini');
      } else if (e.toString().contains('column "images"')) {
        throw Exception('Error pada format gambar. Silakan coba lagi.');
      } else {
        throw Exception('Gagal mengirim complaint: $e');
      }
    }
  }

  // Upload complaint image to Supabase storage
  static Future<String?> _uploadComplaintImage(File imageFile) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Validate file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Ukuran gambar maksimal 5MB');
      }

      // Validate file extension
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
        throw Exception('Format gambar harus JPG, PNG, GIF atau WebP');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = _uuid.v4().substring(0, 8);
      final fileName = '${timestamp}_${uniqueId}.$fileExt';
      final filePath = 'complaints/$fileName';

      print('Uploading complaint image: $filePath');
      print('File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Read file as bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();

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

      print('Public URL: $publicUrl');
      return publicUrl;

    } catch (e) {
      print('Error uploading complaint image: $e');

      if (e is StorageException) {
        print('Storage Exception Details:');
        print('- Status: ${e.statusCode}');
        print('- Error: ${e.error}');
        print('- Message: ${e.message}');
      }

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

  // Get user complaints
  static Future<List<Map<String, dynamic>>> getUserComplaints() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('complaints')
          .select('''
            *,
            orders (
              order_number,
              order_items (
                products (
                  name,
                  images
                )
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user complaints: $e');
      throw Exception('Gagal memuat data complaint: $e');
    }
  }

  // Get complaint by ID
  static Future<Map<String, dynamic>?> getComplaintById(String complaintId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return null;

      final response = await _client
          .from('complaints')
          .select('''
            *,
            orders (
              order_number,
              order_items (
                products (
                  name,
                  images
                )
              )
            )
          ''')
          .eq('id', complaintId)
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching complaint by ID: $e');
      return null;
    }
  }

  // Update complaint status (for admin use)
  static Future<void> updateComplaintStatus(
      String complaintId,
      String status,
      String? adminResponse
      ) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminResponse != null && adminResponse.isNotEmpty) {
        updateData['admin_response'] = adminResponse;
      }

      await _client
          .from('complaints')
          .update(updateData)
          .eq('id', complaintId);

    } catch (e) {
      print('Error updating complaint status: $e');
      throw Exception('Gagal mengupdate status complaint: $e');
    }
  }

  // Get complaint statistics for user
  static Future<Map<String, int>> getComplaintStatistics() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('complaints')
          .select('status')
          .eq('user_id', userId);

      Map<String, int> stats = {
        'total': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (var complaint in response) {
        stats['total'] = (stats['total'] ?? 0) + 1;
        final status = complaint['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error fetching complaint statistics: $e');
      return {
        'total': 0,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
      };
    }
  }
}