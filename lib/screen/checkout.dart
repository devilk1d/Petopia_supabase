import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/checkout_service.dart';
import '../services/auth_service.dart';
import '../services/address_service.dart';
import '../models/address_model.dart';
import '../utils/colors.dart';
import '../widgets/order_item.dart';
import '../widgets/payment_method.dart';
import 'dart:async';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

Map<String, Map<String, dynamic>?> _storeShippingMethods = {}; // Track shipping per store
Map<String, double> _storeShippingCosts = {}; // Track shipping costs per store

class StoreShippingOptionsBottomSheet extends StatefulWidget {
  final String storeId;
  final String storeName;
  final Function(Map<String, dynamic>)? onShippingMethodSelected;

  const StoreShippingOptionsBottomSheet({
    Key? key,
    required this.storeId,
    required this.storeName,
    this.onShippingMethodSelected,
  }) : super(key: key);

  @override
  _StoreShippingOptionsBottomSheetState createState() => _StoreShippingOptionsBottomSheetState();
}

class _StoreShippingOptionsBottomSheetState extends State<StoreShippingOptionsBottomSheet> {
  List<Map<String, dynamic>> _shippingMethods = [];
  Map<String, dynamic>? _selectedMethod;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShippingMethods();
  }

  Future<void> _loadShippingMethods() async {
    try {
      final methods = await OrderService.getShippingMethods();
      setState(() {
        _shippingMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading shipping methods: $e')),
      );
    }
  }

  // Group shipping methods by courier
  Map<String, List<Map<String, dynamic>>> get _groupedMethods {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var method in _shippingMethods) {
      String methodName = method['name'] ?? '';
      String courierName = _extractCourierName(methodName);

      if (!grouped.containsKey(courierName)) {
        grouped[courierName] = [];
      }
      grouped[courierName]!.add(method);
    }

    return grouped;
  }

  String _extractCourierName(String methodName) {
    String lowerName = methodName.toLowerCase();
    if (lowerName.contains('jne')) return 'JNE';
    if (lowerName.contains('sicepat')) return 'SiCepat';
    if (lowerName.contains('j&t')) return 'J&T';
    if (lowerName.contains('anteraja')) return 'AnterAja';
    return 'Lainnya';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Pengiriman',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.store_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.storeName,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  ..._groupedMethods.entries.map((courierEntry) {
                    final courierName = courierEntry.key;
                    final methods = courierEntry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Courier header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _getCourierIcon(courierName),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                courierName,
                                style: const TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Methods for this courier
                        ...methods.map((method) {
                          final isSelected = _selectedMethod == method;
                          final serviceName = _extractServiceName(method['name']);
                          final baseCost = (method['base_cost'] as num?)?.toDouble() ?? 0;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMethod = method;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: isSelected
                                    ? AppColors.primaryColor.withOpacity(0.05)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  // Radio button
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Center(
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    )
                                        : null,
                                  ),

                                  const SizedBox(width: 12),

                                  // Service details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Service name and estimated days
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                serviceName,
                                                style: const TextStyle(
                                                  fontFamily: 'SF Pro Display',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _getEstimatedDays(method['type']),
                                              style: TextStyle(
                                                fontFamily: 'SF Pro Display',
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // Price
                                        Text(
                                          'Rp ${baseCost.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontFamily: 'SF Pro Display',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),

            // Confirm button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod != null
                      ? () {
                    if (widget.onShippingMethodSelected != null) {
                      widget.onShippingMethodSelected!(_selectedMethod!);
                    }
                    Navigator.of(context).pop();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Konfirmasi Pengiriman',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getCourierIcon(String courierName) {
    IconData icon;
    switch (courierName.toLowerCase()) {
      case 'jne':
        icon = Icons.local_shipping;
        break;
      case 'sicepat':
        icon = Icons.speed;
        break;
      case 'j&t':
        icon = Icons.delivery_dining;
        break;
      case 'anteraja':
        icon = Icons.motorcycle;
        break;
      default:
        icon = Icons.local_shipping;
    }

    return Icon(
      icon,
      color: AppColors.primaryColor,
      size: 18,
    );
  }

  String _extractServiceName(String fullName) {
    if (fullName.toLowerCase().contains('regular') || fullName.toLowerCase().contains('reg')) {
      return 'REG (Reguler)';
    } else if (fullName.toLowerCase().contains('yes')) {
      return 'YES (Yakin Esok Sampai)';
    } else if (fullName.toLowerCase().contains('best')) {
      return 'BEST (Besok Sampai)';
    } else if (fullName.toLowerCase().contains('ekonomi')) {
      return 'Ekonomi';
    } else if (fullName.toLowerCase().contains('express')) {
      return 'Express';
    } else if (fullName.toLowerCase().contains('next day')) {
      return 'Next Day';
    } else {
      List<String> parts = fullName.split(' ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ');
      }
      return fullName;
    }
  }

  String _getEstimatedDays(String? type) {
    switch (type?.toLowerCase()) {
      case 'express':
        return 'Estimasi 1 hari';
      case 'standard':
        return 'Estimasi 2-3 hari';
      case 'economy':
        return 'Estimasi 3-4 hari';
      default:
        return 'Estimasi 2-3 hari';
    }
  }
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  Map<String, dynamic>? _selectedPaymentMethod;
  Map<String, dynamic>? _selectedShippingMethod;
  AddressModel? _selectedAddress;
  String? _promoCode;
  double _shippingCost = 0;
  double _discountAmount = 0;
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _initializeCheckout() async {
    setState(() => _isLoading = true);
    try {
      // Load cart items
      final items = await CartService.getCartItems();

      // Load payment methods
      final paymentMethods = await CheckoutService.getPaymentMethods();

      // Load default address
      final defaultAddress = await AddressService.getDefaultAddress();

      if (mounted) {
        setState(() {
          _cartItems = items;
          _paymentMethods = paymentMethods;
          _selectedAddress = defaultAddress;

          if (_paymentMethods.isNotEmpty) {
            _selectedPaymentMethod = _paymentMethods.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading checkout data: $e')),
        );
      }
    }
  }

  // Calculate subtotal
  double get _subtotal {
    return _cartItems.fold(0, (sum, item) =>
    sum + (item['price'] as double) * (item['quantity'] as int));
  }

  // Calculate total
  double get _total {
    return _subtotal + _shippingCost - _discountAmount;
  }

  Future<void> _selectAddress() async {
    final selectedAddress = await Navigator.pushNamed(context, '/address-list');
    if (selectedAddress is AddressModel) {
      setState(() {
        _selectedAddress = selectedAddress;
      });
    }
  }

  Future<void> _applyPromoCode() async {
    final promoCode = _promoController.text.trim();
    if (promoCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode promo terlebih dahulu')),
      );
      return;
    }

    try {
      final promoResult = await CheckoutService.applyPromoCode(promoCode, _subtotal);

      if (promoResult != null) {
        setState(() {
          _promoCode = promoCode;
          _discountAmount = promoResult['discount_amount'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promo "${promoResult['promo_title']}" berhasil diterapkan!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode promo tidak valid atau sudah kedaluwarsa')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying promo: $e')),
      );
    }
  }

  void _removePromoCode() {
    setState(() {
      _promoCode = null;
      _discountAmount = 0;
      _promoController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode promo dihapus'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  // Callback to handle shipping method selection
  void _onShippingMethodSelected(Map<String, dynamic> shippingMethod) {
    setState(() {
      _selectedShippingMethod = shippingMethod;
    });
  }

  // Callback to update shipping cost from order items
  void _onShippingCostChanged(double cost) {
    setState(() {
      _shippingCost = cost;
    });
  }

  Future<void> _processCheckout() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih alamat pengiriman terlebih dahulu')),
      );
      return;
    }

    // Validate that all stores have shipping methods selected
    Set<String> storeIds = {};
    for (var item in _cartItems) {
      storeIds.add(item['seller_id'] ?? 'unknown');
    }

    for (String storeId in storeIds) {
      if (!_storeShippingMethods.containsKey(storeId) || _storeShippingMethods[storeId] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih metode pengiriman untuk semua toko')),
        );
        return;
      }
    }

    try {
      setState(() => _isLoading = true);

      // Prepare notes from product notes
      String allNotes = '';
      if (_productNotes.isNotEmpty) {
        List<String> notesList = [];
        for (var entry in _productNotes.entries) {
          // Find product name
          String productName = 'Product';
          for (var item in _cartItems) {
            if ((item['product_id'] ?? item['id']) == entry.key) {
              productName = item['name'] ?? 'Product';
              break;
            }
          }
          notesList.add('$productName: ${entry.value}');
        }
        allNotes = notesList.join('\n');
      }

      // Create order using the service
      final order = await OrderService.createOrder(
        shippingAddress: _selectedAddress!.toJson(),
        paymentMethodId: _selectedPaymentMethod!['id'],
        shippingMethodId: _storeShippingMethods.values.first!['id'],
        promoCode: _promoCode,
        notes: allNotes.isNotEmpty ? allNotes : null,
      );

      if (mounted) {
        // Navigate to payment screen with order ID
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: {
            'orderId': order['id'],
            'orderNumber': order['order_number'],
            'totalAmount': order['total_amount'],
            'paymentMethod': _selectedPaymentMethod,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Checkout failed';

        // Handle specific error messages
        if (e.toString().contains('row-level security policy')) {
          errorMessage = 'Error: Permission denied. Please login again.';
        } else if (e.toString().contains('violates')) {
          errorMessage = 'Error: Invalid data. Please check your information.';
        } else {
          errorMessage = 'Checkout failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipping Address Card
                    _buildShippingAddressCard(),

                    // Order Items Section (with shipping selection)
                    _buildOrderItemsSection(),

                    // Promo Code Section
                    _buildPromoCodeSection(),

                    // Payment Methods Section
                    _buildPaymentMethodsSection(),

                    // Order Summary Section
                    _buildOrderSummarySection(),

                    const SizedBox(height: 10), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      color: Colors.white,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Bayar Sekarang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rp${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF Pro Display',
                        color: Colors.white,
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

  Widget _buildShippingAddressCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alamat Pengiriman',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectAddress,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(_selectedAddress == null ? 'Pilih' : 'Ubah'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            if (_selectedAddress != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getAddressIcon(_selectedAddress!.label),
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedAddress!.label} - ${_selectedAddress!.recipientName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedAddress!.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedAddress!.formattedAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'SF Pro Display',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.location_off, color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada alamat pengiriman',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/address-edit');
                        _initializeCheckout(); // Reload data
                      },
                      child: const Text('Tambah Alamat'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    // Group items by store
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in _cartItems) {
      String storeId = item['seller_id'] ?? 'unknown';
      String storeName = item['store_name'] ?? 'Unknown Store';

      if (!groupedItems.containsKey(storeId)) {
        groupedItems[storeId] = [];
      }
      groupedItems[storeId]!.add({
        ...item,
        'store_name': storeName, // Ensure store name is consistent
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan Anda (${_cartItems.length} item)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 16),

            // Order items list grouped by store
            ...groupedItems.entries.map((storeEntry) {
              final storeId = storeEntry.key;
              final storeItems = storeEntry.value;
              final storeName = storeItems.first['store_name'] ?? 'Unknown Store';
              final isLastStore = storeEntry.key == groupedItems.keys.last;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store header with icon and name
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                              Icons.store_rounded,
                              size: 14,
                              color: AppColors.primaryColor
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            storeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Display',
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        // Store item count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${storeItems.length} item${storeItems.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Display',
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Store items (without individual store names)
                  ...storeItems.asMap().entries.map((itemEntry) {
                    final item = itemEntry.value;
                    final isLastInStore = itemEntry.key == storeItems.length - 1;

                    return Column(
                      children: [
                        _buildProductItem(item),
                        if (!isLastInStore)
                          const Divider(height: 20, thickness: 0.5, indent: 20, endIndent: 20),
                      ],
                    );
                  }).toList(),

                  const SizedBox(height: 12),

                  // Shipping selection for this store (only one per store)
                  _buildStoreShippingSelection(storeId, storeName),

                  // Store separator
                  if (!isLastStore) ...[
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Tambahkan state variable untuk menyimpan catatan
  Map<String, String> _productNotes = {}; // productId -> note

  Widget _buildProductItem(Map<String, dynamic> item) {
    final productId = item['product_id'] ?? item['id'] ?? '';
    final hasNote = _productNotes.containsKey(productId) && _productNotes[productId]!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image'] ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      item['name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Product variant
                    if (item['variant'] != null && item['variant'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['variant'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Price and quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp${(item['price'] as double).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'x${item['quantity']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Add note button
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showAddNoteDialog(productId, item['name'] ?? 'Product'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasNote ? AppColors.primaryColor.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: hasNote ? Border.all(color: AppColors.primaryColor.withOpacity(0.3)) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasNote ? Icons.edit_note : Icons.add_comment_outlined,
                    size: 14,
                    color: hasNote ? AppColors.primaryColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasNote ? 'Edit Catatan' : 'Tambah Catatan',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w500,
                      color: hasNote ? AppColors.primaryColor : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Show note if exists
          if (hasNote) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note_alt, size: 12, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Catatan:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _productNotes[productId]!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[800],
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddNoteDialog(String productId, String productName) {
    final TextEditingController noteController = TextEditingController();

    // Pre-fill with existing note if any
    if (_productNotes.containsKey(productId)) {
      noteController.text = _productNotes[productId]!;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catatan Produk',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productName,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Note text field
              TextField(
                controller: noteController,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Tuliskan catatan untuk produk ini...\nContoh: Warna merah, ukuran L, dll.',
                  hintStyle: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontFamily: 'SF Pro Display'),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Delete note button (if note exists)
                  if (_productNotes.containsKey(productId) && _productNotes[productId]!.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _productNotes.remove(productId);
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Catatan dihapus'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Save button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final note = noteController.text.trim();
                        setState(() {
                          if (note.isEmpty) {
                            _productNotes.remove(productId);
                          } else {
                            _productNotes[productId] = note;
                          }
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(note.isEmpty ? 'Catatan dihapus' : 'Catatan disimpan'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>?> _storeShippingMethods = {}; // Track shipping per store
  Map<String, double> _storeShippingCosts = {}; // Track shipping costs per store

  Widget _buildStoreShippingSelection(String storeId, String storeName) {
    final selectedMethod = _storeShippingMethods[storeId];

    return GestureDetector(
      onTap: () => _showStoreShippingOptions(storeId, storeName),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Shipping icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 12),

            // Shipping details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedMethod != null) ...[
                    Text(
                      selectedMethod['name'] ?? 'Pengiriman Dipilih',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Rp ${(_storeShippingCosts[storeId] ?? 0).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Pilih Metode Pengiriman',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Tap untuk memilih kurir',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreShippingOptions(String storeId, String storeName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StoreShippingOptionsBottomSheet(
        storeId: storeId,
        storeName: storeName,
        onShippingMethodSelected: (method) {
          setState(() {
            _storeShippingMethods[storeId] = method;
            _storeShippingCosts[storeId] = (method['base_cost'] as num?)?.toDouble() ?? 0;
            // Update total shipping cost
            _updateTotalShippingCost();
          });
        },
      ),
    );
  }

  void _updateTotalShippingCost() {
    double totalShippingCost = 0;
    for (double cost in _storeShippingCosts.values) {
      totalShippingCost += cost;
    }
    setState(() {
      _shippingCost = totalShippingCost;
    });
  }

  Widget _buildPromoCodeSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kode Promo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),

            if (_discountAmount == 0) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan kode promo',
                        hintStyle: TextStyle(
                          fontFamily: 'SF Pro Display',
                          color: Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontFamily: 'SF Pro Display'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode: ${_promoCode?.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Hemat Rp${_discountAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removePromoCode,
                      icon: const Icon(Icons.close, color: AppColors.success, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),

            // Payment methods list
            ..._paymentMethods.map((method) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: PaymentMethodWidget(
                  logoUrl: method['logo_url'] ?? '',
                  name: method['name'] ?? 'Unknown Payment Method',
                  isSelected: _selectedPaymentMethod == method,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method;
                    });
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Belanja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),

            // Summary rows
            _buildSummaryRow(
              'Total Harga (${_cartItems.length} Barang)',
              'Rp${_subtotal.toStringAsFixed(0)}',
            ),

            // Shipping cost breakdown by store
            if (_storeShippingCosts.isNotEmpty) ...[
              ...(_storeShippingCosts.entries.where((entry) => entry.value > 0).map((entry) {
                // Find store name for this store ID
                String storeName = 'Unknown Store';
                for (var item in _cartItems) {
                  if (item['seller_id'] == entry.key) {
                    storeName = item['store_name'] ?? 'Unknown Store';
                    break;
                  }
                }

                return _buildSummaryRow(
                  'Ongkir - $storeName',
                  'Rp${entry.value.toStringAsFixed(0)}',
                  isIndented: true,
                );
              }).toList()),

              // Show free shipping count if any
              if (_storeShippingCosts.values.where((cost) => cost == 0).isNotEmpty)
                _buildSummaryRow(
                  'Gratis Ongkir (${_storeShippingCosts.values.where((cost) => cost == 0).length} toko)',
                  'Rp 0',
                  valueColor: AppColors.success,
                  isIndented: true,
                ),
            ],

            // Total shipping
            _buildSummaryRow(
              'Total Ongkos Kirim',
              _shippingCost > 0
                  ? 'Rp${_shippingCost.toStringAsFixed(0)}'
                  : 'Gratis',
              valueColor: _shippingCost == 0 ? AppColors.success : null,
            ),

            if (_discountAmount > 0)
              _buildSummaryRow(
                'Diskon',
                '-Rp${_discountAmount.toStringAsFixed(0)}',
                valueColor: AppColors.success,
              ),

            const Divider(height: 24, thickness: 1),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                Text(
                  'Rp${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool isIndented = false}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isIndented ? 16 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isIndented ? 13 : 14,
                color: isIndented ? Colors.grey[500] : Colors.grey[600],
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isIndented ? 13 : 14,
              color: valueColor ?? (isIndented ? Colors.grey[500] : Colors.grey[600]),
              fontFamily: 'SF Pro Display',
              fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'rumah':
      case 'home':
        return Icons.home_rounded;
      case 'kantor':
      case 'office':
        return Icons.work_rounded;
      case 'apartemen':
      case 'apartment':
        return Icons.apartment_rounded;
      case 'kos':
        return Icons.bed_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }
}