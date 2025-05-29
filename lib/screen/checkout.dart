import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/checkout_service.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../widgets/order_item.dart';
import '../widgets/payment_method.dart';
import 'dart:async';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _shippingMethods = [];
  Map<String, dynamic>? _selectedPaymentMethod;
  Map<String, dynamic>? _selectedShippingMethod;
  Map<String, dynamic>? _shippingAddress;
  String? _promoCode;
  double _shippingCost = 0;
  double _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  Future<void> _initializeCheckout() async {
    setState(() => _isLoading = true);
    try {
      // Load cart items
      final items = await CartService.getCartItems();

      // Load payment methods
      final paymentMethods = await CheckoutService.getPaymentMethods();

      // Load shipping methods
      final shippingMethods = await OrderService.getShippingMethods();

      // Load default shipping address
      final userId = AuthService.getCurrentUserId();
      if (userId != null) {
        final address = await CheckoutService.getDefaultShippingAddress(userId);
        if (address != null) {
          _shippingAddress = address;
        }
      }

      if (mounted) {
        setState(() {
          _cartItems = items;
          _paymentMethods = paymentMethods;
          _shippingMethods = shippingMethods;
          if (_paymentMethods.isNotEmpty) {
            _selectedPaymentMethod = _paymentMethods.first;
          }
          if (_shippingMethods.isNotEmpty) {
            _selectedShippingMethod = _shippingMethods.first;
            _shippingCost = _selectedShippingMethod!['base_cost'] ?? 0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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

  Future<void> _processCheckout() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_selectedShippingMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shipping method')),
      );
      return;
    }

    if (_shippingAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a shipping address')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final order = await OrderService.createOrder(
        shippingAddress: _shippingAddress!,
        paymentMethodId: _selectedPaymentMethod!['id'],
        shippingMethodId: _selectedShippingMethod!['id'],
        promoCode: _promoCode,
      );

      if (mounted) {
        // Navigate to order success page
        Navigator.pushReplacementNamed(
          context,
          '/order-success',
          arguments: order,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipping Address Card
                    _buildShippingAddressCard(),

                    // Order Items Section
                    _buildOrderItemsSection(),

                    // Payment Methods Section
                    _buildPaymentMethodsSection(),

                    // Order Summary Section
                    _buildOrderSummarySection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Fixed payment button at bottom
          _buildPaymentButton(),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
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
                  'Alamat pengiriman',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/address-list');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: const Text('Ubah'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Rumah - Abim',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/map.png',
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan Anda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 16),

            // Order items list
            ..._cartItems.map((item) => Column(
              children: [
                OrderItemWidget(
                  storeName: item['store_name'],
                  productImages: [item['image']],
                  productName: item['name'],
                  productVariant: item['variant'] ?? '',
                  price: 'Rp${item['price'].toStringAsFixed(0)}',
                  quantity: item['quantity'],
                  isSmallScreen: true,
                  onAddNote: () {},
                ),
                if (item != _cartItems.last)
                  const Divider(height: 24, thickness: 1),
              ],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
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
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment methods list
            ..._paymentMethods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: PaymentMethodWidget(
                  logoUrl: method['logo_url'],
                  name: method['name'],
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan belanja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),

            // Summary rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Harga (${_cartItems.length} Barang)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B7B7B),
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                Text(
                  'Rp${_subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B7B7B),
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Ongkos Kirim',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B7B7B),
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                Text(
                  'Rp${_shippingCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7B7B7B),
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ],
            ),
            if (_discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Diskon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7B7B7B),
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  Text(
                    '-Rp${_discountAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ],
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
                    fontSize: 18,
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

  Widget _buildPaymentButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment_rounded, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Bayar Sekarang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}