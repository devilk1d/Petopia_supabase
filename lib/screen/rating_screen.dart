import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingScreen extends StatefulWidget {
  final String productId;
  final String orderId;

  const RatingScreen({
    Key? key,
    required this.productId,
    required this.orderId,
  }) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 4; // Default rating
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _isUploadingImages = false;

  // Image handling
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final int _maxImages = 5; // Maximum 5 images

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // Upload single image to Supabase Storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final userId = AuthService.currentUserId;
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
      final filePath = 'reviews/$fileName'; // Store in reviews folder

      print('\n=== Review Image Upload Debug Info ===');
      print('File path: $filePath');
      print('File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      print('File extension: $fileExt');
      print('Bucket: petopia');

      // Read file as bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();
      print('File bytes length: ${fileBytes.length}');

      // Upload to Supabase Storage
      final String uploadPath = await SupabaseConfig.client.storage
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
      final String publicUrl = SupabaseConfig.client.storage
          .from('petopia')
          .getPublicUrl(filePath);

      print('Public URL generated: $publicUrl');
      print('=== Review Image Upload Complete ===\n');

      return publicUrl;

    } catch (e) {
      print('\n=== Review Image Upload Error ===');
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
  String _getContentType(String fileExt) {
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

  // Upload multiple images
  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    setState(() => _isUploadingImages = true);

    try {
      print('\n=== Multiple Review Images Upload Started ===');
      print('Number of images to upload: ${_selectedImages.length}');

      final List<String> imageUrls = [];
      final List<String> errors = [];

      for (var i = 0; i < _selectedImages.length; i++) {
        try {
          final imageFile = _selectedImages[i];
          print('\n--- Uploading image ${i + 1} of ${_selectedImages.length} ---');
          print('File path: ${imageFile.path}');

          final imageUrl = await _uploadImage(imageFile);
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
      print('Successfully uploaded: ${imageUrls.length}/${_selectedImages.length}');
      print('Errors: ${errors.length}');

      if (errors.isNotEmpty) {
        print('Error details:');
        errors.forEach((error) => print('- $error'));
      }

      print('=== Multiple Review Images Upload Complete ===\n');
      return imageUrls;

    } catch (e) {
      print('❌ Critical error in uploadImages: $e');
      return [];
    } finally {
      setState(() => _isUploadingImages = false);
    }
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Check file size
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          if (_selectedImages.length < _maxImages) {
            _selectedImages.add(imageFile);
          }
        });

        if (_selectedImages.length >= _maxImages) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum $_maxImages images allowed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
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

  // Remove selected image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Show image picker options
  void _showImagePickerOptions() {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxImages images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFFB60051),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFB60051),
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Rating',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Yeay! Header
              const Text(
                'Yeay!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Terimakasih message
              const Text(
                'Terimakasih sudah melakukan order',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Check icon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBB54), // Orange color for the circle
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFBB54).withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Rating prompt
              const Text(
                'Silahkan lakukan rating',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: index < _rating ? const Color(0xFFFFBB54) : const Color(0xFFE0E0E0),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 5),
              // Rating text
              Text(
                _getRatingText(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Review input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _reviewController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Berikan review anda',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Image upload section
              _buildImageUploadSection(),

              const SizedBox(height: 30),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isUploadingImages) ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB60051),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: (_isSubmitting || _isUploadingImages)
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Submit',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Upload Foto (Opsional)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedImages.length}/$_maxImages',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected images grid
        if (_selectedImages.isNotEmpty) ...[
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Add image button
        if (_selectedImages.length < _maxImages) ...[
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFB60051).withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFFB60051),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Foto',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB60051),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Upload progress indicator
        if (_isUploadingImages) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Mengupload foto...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _submitRating() async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to submit a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload images first if any selected
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();

        // If image upload failed but images were selected, show warning
        if (imageUrls.length != _selectedImages.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil upload ${imageUrls.length} dari ${_selectedImages.length} foto. Melanjutkan submit review...',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Submit review with images
      await ReviewService.addReview(
        productId: widget.productId,
        orderId: widget.orderId,
        rating: _rating.toDouble(),
        comment: _reviewController.text.trim(),
        images: imageUrls.isNotEmpty ? imageUrls : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terima kasih atas rating dan review Anda!',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFBF0055),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(true); // Return true to indicate successful rating
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class CheckmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    Path path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.width * 0.7);
    path.lineTo(size.width * 0.75, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}