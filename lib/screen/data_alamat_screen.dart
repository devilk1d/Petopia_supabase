import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';

class AddressFormScreen extends StatefulWidget {
  final AddressModel? address;

  const AddressFormScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedCity = '';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<String> _cities = [
    'Jakarta Pusat', 'Jakarta Utara', 'Jakarta Selatan', 'Jakarta Timur', 'Jakarta Barat',
    'Bandung', 'Surabaya', 'Medan', 'Makassar', 'Semarang', 'Yogyakarta', 'Palembang',
    'Tangerang', 'Depok', 'Bekasi', 'Bogor', 'Malang', 'Solo', 'Balikpapan', 'Banjarmasin'
  ];

  final List<Map<String, dynamic>> _labelOptions = [
    {'label': 'Rumah', 'icon': Icons.home_rounded},
    {'label': 'Kantor', 'icon': Icons.work_rounded},
    {'label': 'Apartemen', 'icon': Icons.apartment_rounded},
    {'label': 'Kos', 'icon': Icons.bed_rounded},
    {'label': 'Lainnya', 'icon': Icons.location_on_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final address = widget.address!;
    _labelController.text = address.label;
    _nameController.text = address.recipientName;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    _postalCodeController.text = address.postalCode;
    _selectedCity = address.city;
    _isDefault = address.isDefault;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kota terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final addressData = AddressModel(
        id: widget.address?.id ?? '',
        userId: userId,
        label: _labelController.text.trim(),
        recipientName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity,
        postalCode: _postalCodeController.text.trim(),
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.address != null) {
        await AddressService.updateAddress(addressData);
      } else {
        await AddressService.addAddress(addressData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.address != null
                    ? 'Alamat berhasil diperbarui'
                    : 'Alamat berhasil ditambahkan'
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.address != null ? 'Edit Alamat' : 'Tambah Alamat',
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label selection
                    _buildSectionTitle('Label Alamat'),
                    const SizedBox(height: 8),
                    _buildLabelSelection(),

                    const SizedBox(height: 24),

                    // Recipient info
                    _buildSectionTitle('Informasi Penerima'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Penerima',
                      hint: 'Masukkan nama lengkap',
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Nama tidak boleh kosong';
                        if (value!.length < 2) return 'Nama minimal 2 karakter';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Nomor Telepon',
                      hint: '08xxxxxxxxxx',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Nomor telepon tidak boleh kosong';
                        // Fixed regex pattern - added missing $
                        if (!RegExp(r'^08[0-9]{8,11}$').hasMatch(value!)) {
                          return 'Format nomor telepon tidak valid (08xxxxxxxxxx)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Address details
                    _buildSectionTitle('Detail Alamat'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCityDropdown(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _postalCodeController,
                            label: 'Kode Pos',
                            hint: '12345',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Kode pos wajib diisi';
                              if (value!.length != 5) return 'Kode pos harus 5 digit';
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Kode pos hanya boleh angka';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Alamat Lengkap',
                      hint: 'Jalan, nomor rumah, RT/RW, kelurahan...',
                      maxLines: 4,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Alamat tidak boleh kosong';
                        if (value!.length < 10) return 'Alamat terlalu pendek';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Default address option
                    _buildDefaultOption(),

                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveAddress,
        backgroundColor: _isLoading ? Colors.grey : AppColors.primaryColor,
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isLoading ? 'Menyimpan...' : 'Simpan Alamat',
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLabelSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom label input
          TextFormField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Label Alamat',
              hintText: 'atau pilih dari opsi di bawah',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              labelStyle: TextStyle(
                fontFamily: 'SF Pro Display',
                color: Colors.grey[600],
              ),
              hintStyle: TextStyle(
                fontFamily: 'SF Pro Display',
                color: Colors.grey[400],
              ),
            ),
            style: const TextStyle(fontFamily: 'SF Pro Display'),
            validator: (value) => value?.isEmpty == true ? 'Label alamat tidak boleh kosong' : null,
          ),

          const SizedBox(height: 16),

          // Predefined labels
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _labelOptions.map((option) {
              final isSelected = _labelController.text == option['label'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _labelController.text = option['label'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option['label'],
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            fontFamily: 'SF Pro Display',
            color: Colors.grey[600],
          ),
          hintStyle: TextStyle(
            fontFamily: 'SF Pro Display',
            color: Colors.grey[400],
          ),
        ),
        style: const TextStyle(fontFamily: 'SF Pro Display'),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCity.isEmpty ? null : _selectedCity,
        decoration: InputDecoration(
          labelText: 'Kota',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            fontFamily: 'SF Pro Display',
            color: Colors.grey[600],
          ),
        ),
        hint: const Text(
          'Pilih kota',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            color: Colors.grey,
          ),
        ),
        items: _cities.map((city) {
          return DropdownMenuItem(
            value: city,
            child: Text(
              city,
              style: const TextStyle(fontFamily: 'SF Pro Display'),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCity = value ?? '';
          });
        },
        validator: (value) => value == null ? 'Pilih kota' : null,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        isExpanded: true,
      ),
    );
  }

  Widget _buildDefaultOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.star_rounded,
              color: _isDefault ? AppColors.primaryColor : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jadikan alamat utama',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Alamat ini akan diprioritaskan saat checkout',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDefault,
            onChanged: (value) {
              setState(() {
                _isDefault = value;
              });
            },
            activeColor: AppColors.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}