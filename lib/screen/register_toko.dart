import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/store_service.dart';

class RegisterTokoScreen extends StatefulWidget {
  const RegisterTokoScreen({Key? key}) : super(key: key);

  @override
  State<RegisterTokoScreen> createState() => _RegisterTokoScreenState();
}

class _RegisterTokoScreenState extends State<RegisterTokoScreen> {
  final _formFields = <String, TextEditingController>{
    'Nama Toko': TextEditingController(),
    'Deskripsi': TextEditingController(),
    'No. HP': TextEditingController(),
    'Alamat Toko': TextEditingController(),
  };

  final Map<String, TextInputType> _keyboardTypes = {
    'No. HP': TextInputType.phone,
    'Alamat Toko': TextInputType.streetAddress,
    'Deskripsi': TextInputType.multiline,
  };

  final Map<String, IconData> _fieldIcons = {
    'Nama Toko': Icons.store,
    'Deskripsi': Icons.description,
    'No. HP': Icons.phone,
    'Alamat Toko': Icons.location_on,
  };

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _formFields.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Widget _buildTextField(String label, {int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: _formFields[label],
        keyboardType: _keyboardTypes[label] ?? TextInputType.text,
        maxLines: maxLines ?? 1,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.grey[100],
          hintText: label,
          hintStyle: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: Colors.grey[600],
          ),
          prefixIcon: Icon(
              _fieldIcons[label],
              size: 18,
              color: const Color(0xFFBF0055)
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate fields
      for (var entry in _formFields.entries) {
        if (entry.value.text.trim().isEmpty) {
          throw Exception('${entry.key} tidak boleh kosong');
        }
      }

      // Register store
      await StoreService.registerStore(
        storeName: _formFields['Nama Toko']!.text.trim(),
        storeDescription: _formFields['Deskripsi']!.text.trim(),
        phone: _formFields['No. HP']!.text.trim(),
        address: _formFields['Alamat Toko']!.text.trim(),
      );

      if (mounted) {
        _showRegistrationSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRegistrationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBF0055).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFFBF0055),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                // Success message
                const Text(
                  'Pendaftaran Berhasil!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Toko Anda telah berhasil didaftarkan. Silahkan tunggu verifikasi dari tim kami.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                // OK button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBF0055),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFFBF0055),
                          size: 20
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Header with icon and title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBF0055).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 30,
                          color: Color(0xFFBF0055),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Daftarkan Toko',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Isi data toko Anda dengan lengkap',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Form fields
                  _buildTextField('Nama Toko'),
                  _buildTextField('Deskripsi', maxLines: 3),
                  _buildTextField('No. HP'),
                  _buildTextField('Alamat Toko', maxLines: 2),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBF0055),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: const Color(0xFFBF0055).withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Daftarkan Toko',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}