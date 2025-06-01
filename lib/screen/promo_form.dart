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
      _showSnackBar('Error saving promo: $e');
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
              onSurface: const Color(0xFF1E293B),
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
                          widget.promo == null ? 'Add Promo' : 'Edit Promo',
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
                          widget.promo == null ? 'Create a new promotional offer' : 'Update promo details',
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
              controller: _codeController,
              label: 'Promo Code',
              icon: Icons.local_offer_outlined,
              validator: (value) => value?.isEmpty ?? true ? 'Please enter promo code' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              icon: Icons.title_outlined,
              validator: (value) => value?.isEmpty ?? true ? 'Please enter title' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
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
                Icon(Icons.discount_outlined, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Discount Details',
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
            _buildDiscountTypeDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _discountValueController,
              label: 'Discount Value',
              icon: Icons.money_outlined,
              suffixText: _discountType == 'percentage' ? '%' : 'Rp',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter discount value';
                String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.isEmpty) return 'Please enter a valid number';
                if (_discountType == 'percentage' && double.parse(digits) > 100) {
                  return 'Percentage cannot be more than 100';
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
                  'Conditions (Optional)',
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
              controller: _minPurchaseController,
              label: 'Minimum Purchase (optional)',
              icon: Icons.shopping_cart_outlined,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return 'Please enter a valid number';
                }
                return null;
              },
              isPrice: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _maxDiscountController,
              label: 'Maximum Discount (optional)',
              icon: Icons.money_off_outlined,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) return 'Please enter a valid number';
                }
                return null;
              },
              isPrice: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _usageLimitController,
              label: 'Usage Limit (optional)',
              icon: Icons.people_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                  return 'Please enter a valid number';
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
                Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Validity Period',
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
            _buildDatePicker(
              label: 'Start Date',
              icon: Icons.calendar_today_outlined,
              selectedDate: _startDate,
              isStartDate: true,
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              label: 'End Date (optional)',
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
            suffixText: suffixText,
            suffixStyle: const TextStyle(fontFamily: 'SF Pro Display'),
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

  Widget _buildDiscountTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount Type',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _discountType,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.discount_outlined,
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
          items: [
            DropdownMenuItem(
              value: 'percentage',
              child: Text(
                'Percentage',
                style: const TextStyle(fontFamily: 'SF Pro Display'),
              ),
            ),
            DropdownMenuItem(
              value: 'fixed',
              child: Text(
                'Fixed Amount',
                style: const TextStyle(fontFamily: 'SF Pro Display'),
              ),
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
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _isSubmitting ? null : () => _selectDate(context, isStartDate),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6B7280), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? (isOptional ? 'Select Date (optional)' : 'Select Date')
                        : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      color: selectedDate == null
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
              ],
            ),
          ),
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
          'Save Promo',
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