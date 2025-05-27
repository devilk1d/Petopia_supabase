import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  /// Pick an image from gallery or camera
  static Future<File?> pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Upload an image to Supabase storage and return the public URL
  static Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      final fileExt = path.extension(imageFile.path); // e.g., .jpg
      final fileName = '${_uuid.v4()}$fileExt'; // Generate unique filename
      
      // Upload the file to Supabase storage
      final response = await _supabase.storage
          .from(folder)
          .upload(fileName, imageFile);

      if (response.isEmpty) {
        throw Exception('Failed to upload image');
      }

      // Get the public URL
      final imageUrl = _supabase.storage
          .from(folder)
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete an image from Supabase storage
  static Future<bool> deleteImage(String imageUrl, String folder) async {
    try {
      final uri = Uri.parse(imageUrl);
      final fileName = path.basename(uri.path);

      await _supabase.storage
          .from(folder)
          .remove([fileName]);

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
} 