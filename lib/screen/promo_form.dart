import 'package:flutter/material.dart';
import '../services/store_service.dart';

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final promoData = {
        'code': _codeController.text,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'discount_type': _discountType,
        'discount_value': double.parse(_discountValueController.text),
        'min_purchase': _minPurchaseController.text.isNotEmpty
            ? double.parse(_minPurchaseController.text)
            : null,
        'max_discount': _maxDiscountController.text.isNotEmpty
            ? double.parse(_maxDiscountController.text)
            : null,
        'usage_limit': _usageLimitController.text.isNotEmpty
            ? int.parse(_usageLimitController.text)
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
          discountValue: double.parse(_discountValueController.text),
          minPurchase: _minPurchaseController.text.isNotEmpty
              ? double.parse(_minPurchaseController.text)
              : null,
          maxDiscount: _maxDiscountController.text.isNotEmpty
              ? double.parse(_maxDiscountController.text)
              : null,
          usageLimit: _usageLimitController.text.isNotEmpty
              ? int.parse(_usageLimitController.text)
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving promo: $e')),
      );
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.promo == null ? 'Add Promo' : 'Edit Promo',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Promo Code',
                  prefixIcon: const Icon(Icons.local_offer),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter promo code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: InputDecoration(
                  labelText: 'Discount Type',
                  prefixIcon: const Icon(Icons.discount),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage'),
                  ),
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Fixed Amount'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: 'Discount Value',
                  prefixIcon: const Icon(Icons.money),
                  suffixText: _discountType == 'percentage' ? '%' : 'Rp',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter discount value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (_discountType == 'percentage' && double.parse(value) > 100) {
                    return 'Percentage cannot be more than 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minPurchaseController,
                decoration: InputDecoration(
                  labelText: 'Minimum Purchase (optional)',
                  prefixIcon: const Icon(Icons.shopping_cart),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxDiscountController,
                decoration: InputDecoration(
                  labelText: 'Maximum Discount (optional)',
                  prefixIcon: const Icon(Icons.money_off),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _usageLimitController,
                decoration: InputDecoration(
                  labelText: 'Usage Limit (optional)',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _startDate == null
                      ? 'Select Start Date'
                      : 'Start Date: ${_startDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _isSubmitting ? null : () => _selectDate(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _endDate == null
                      ? 'Select End Date (optional)'
                      : 'End Date: ${_endDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _isSubmitting ? null : () => _selectDate(context, false),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Save Promo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}