import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/store_service.dart';
import '../utils/colors.dart';
import '../utils/format.dart';

class PromoForm extends StatefulWidget {
  final Map<String, dynamic>? promo;
  final String storeId;
  final Function() onSuccess;

  const PromoForm({
    Key? key,
    this.promo,
    required this.storeId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _PromoFormState createState() => _PromoFormState();
}

class _PromoFormState extends State<PromoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _minPurchaseController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _usageLimitController;
  late String _discountType;
  DateTime? _startDate;
  DateTime? _endDate;
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

    _codeController = TextEditingController(text: widget.promo?['code'] ?? '');
    _titleController = TextEditingController(text: widget.promo?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.promo?['description'] ?? '');
    _discountValueController = TextEditingController(
      text: widget.promo?['discount_value']?.toString() ?? '',
    );
    _minPurchaseController = TextEditingController(
      text: widget.promo?['min_purchase']?.toString() ?? '',
    );
    _maxDiscountController = TextEditingController(
      text: widget.promo?['max_discount']?.toString() ?? '',
    );
    _usageLimitController = TextEditingController(
      text: widget.promo?['usage_limit']?.toString() ?? '',
    );
    _discountType = widget.promo?['discount_type'] ?? 'percentage';
    _startDate = widget.promo?['start_date'] != null
        ? DateTime.parse(widget.promo?['start_date'])
        : DateTime.now();
    _endDate = widget.promo?['end_date'] != null
        ? DateTime.parse(widget.promo?['end_date'])
        : null;
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.primaryColor,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final promoData = {
        'code': _codeController.text,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'discount_type': _discountType,
        'discount_value': double.parse(_discountValueController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'min_purchase': _minPurchaseController.text.isNotEmpty
            ? double.parse(_minPurchaseController.text.replaceAll(RegExp(r'[^0-9]'), ''))
            : null,
        'max_discount': _maxDiscountController.text.isNotEmpty
            ? double.parse(_maxDiscountController.text.replaceAll(RegExp(r'[^0-9]'), ''))
            : null,
        'usage_limit': _usageLimitController.text.isNotEmpty
            ? int.parse(_usageLimitController.text.replaceAll(RegExp(r'[^0-9]'), ''))
            : null,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      };

      if (widget.promo == null) {
        await StoreService.addPromo(
          storeId: widget.storeId,
          code: _codeController.text,
          title: _titleController.text,
          description: _descriptionController.text,
          discountType: _discountType,
          discountValue: double.parse(_discountValueController.text.replaceAll(RegExp(r'[^0-9]'), '')),
          minPurchase: _minPurchaseController.text.isNotEmpty
              ? double.parse(_minPurchaseController.text.replaceAll(RegExp(r'[^0-9]'), ''))
              : null,
          maxDiscount: _maxDiscountController.text.isNotEmpty
              ? double.parse(_maxDiscountController.text.replaceAll(RegExp(r'[^0-9]'), ''))
              : null,
          usageLimit: _usageLimitController.text.isNotEmpty
              ? int.parse(_usageLimitController.text.replaceAll(RegExp(r'[^0-9]'), ''))
              : null,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        await StoreService.updatePromo(
          widget.promo!['id'],
          promoData,
        );
      }

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error menyimpan promo: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildModernAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            // Form Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Basic Information
                    _buildBasicInfoCard(),
                    const SizedBox(height: 16),

                    // Discount Details
                    _buildDiscountCard(),
                    const SizedBox(height: 16),

                    // Conditions
                    _buildConditionsCard(),
                    const SizedBox(height: 16),

                    // Validity Period
                    _buildValidityCard(),
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

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      title: Text(
        widget.promo == null ? 'Tambah Promo' : 'Edit Promo',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.local_offer_outlined,
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
                  widget.promo == null ? 'Tambah Promo' : 'Edit Promo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.promo == null ? 'Buat penawaran promosi baru' : 'Perbarui detail promo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outlined, size: 20, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Dasar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _codeController,
              label: 'Kode Promo',
              icon: Icons.local_offer_outlined,
              validator: (value) => value?.isEmpty ?? true ? 'Mohon masukkan kode promo' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: 'Judul',
              icon: Icons.title_outlined,
              validator: (value) => value?.isEmpty ?? true ? 'Mohon masukkan judul' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Deskripsi',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Mohon masukkan deskripsi' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.discount_outlined, size: 20, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Detail Diskon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDiscountTypeDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _discountValueController,
              label: 'Nilai Diskon',
              icon: Icons.money_outlined,
              suffixText: _discountType == 'percentage' ? '%' : 'Rp',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Mohon masukkan nilai diskon';
                String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'Mohon masukkan angka yang valid';
                if (_discountType == 'percentage' && double.parse(digits) > 100) {
                  return 'Persentase tidak boleh lebih dari 100';
                }
                return null;
              },
              isPrice: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_outlined, size: 20, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Syarat & Ketentuan (Opsional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _minPurchaseController,
              label: 'Pembelian Minimum (opsional)',
              icon: Icons.shopping_cart_outlined,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return 'Mohon masukkan angka yang valid';
                }
                return null;
              },
              isPrice: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _maxDiscountController,
              label: 'Diskon Maksimum (opsional)',
              icon: Icons.money_off_outlined,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return 'Mohon masukkan angka yang valid';
                }
                return null;
              },
              isPrice: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _usageLimitController,
              label: 'Batas Penggunaan (opsional)',
              icon: Icons.people_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                  return 'Mohon masukkan angka yang valid';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Periode Berlaku',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDatePicker(
              label: 'Tanggal Mulai',
              icon: Icons.calendar_today_outlined,
              selectedDate: _startDate,
              isStartDate: true,
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              label: 'Tanggal Berakhir (opsional)',
              icon: Icons.event_outlined,
              selectedDate: _endDate,
              isStartDate: false,
              isOptional: true,
            ),
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
    String? suffixText,
    bool isPrice = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            prefixText: prefixText,
            suffixText: suffixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildDiscountTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Diskon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _discountType,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.discount_outlined,
                color: Colors.grey.shade500, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: const [
            DropdownMenuItem(
              value: 'percentage',
              child: Text('Persentase'),
            ),
            DropdownMenuItem(
              value: 'fixed',
              child: Text('Jumlah Tetap'),
            ),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) {
            setState(() {
              _discountType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required bool isStartDate,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSubmitting ? null : () => _selectDate(context, isStartDate),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? (isOptional ? 'Pilih Tanggal (opsional)' : 'Pilih Tanggal')
                        : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDate == null
                          ? Colors.grey.shade500
                          : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
          'Simpan Promo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }
}