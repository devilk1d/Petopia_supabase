import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/order_item.dart';
import '../widgets/payment_method.dart';
import '../services/checkout_service.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int selectedPaymentMethod = 0;
  List<Map<String, dynamic>> _paymentMethods = [];
  Map<String, dynamic>? _shippingAddress;
  List<OrderItemModel> _orderItems = [];
  bool _isLoading = true;
  String? _error;
  double _subtotal = 0;
  double _shippingCost = 0;
  double _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckoutData();
    });
  }

  Future<void> _loadCheckoutData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get cart items from route arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null || args['items'] == null) {
        throw Exception('No items to checkout');
      }
      
      _orderItems = (args['items'] as List).cast<OrderItemModel>();

      // Load data in parallel
      final paymentMethodsFuture = CheckoutService.getPaymentMethods();
      final addressFuture = CheckoutService.getDefaultShippingAddress(userId);
      final shippingCostFuture = CheckoutService.calculateShippingCost(_orderItems);

      // Wait for all futures to complete
      final results = await Future.wait([
        paymentMethodsFuture,
        addressFuture,
        shippingCostFuture,
      ]);

      if (mounted) {
        setState(() {
          _paymentMethods = results[0] as List<Map<String, dynamic>>;
          _shippingAddress = results[1] as Map<String, dynamic>?;
          _shippingCost = results[2] as double;

          // Calculate totals
          _subtotal = _orderItems.fold(
            0, 
            (sum, item) => sum + (item.price * item.quantity)
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading checkout data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processCheckout() async {
    try {
      setState(() => _isLoading = true);

      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (_shippingAddress == null) {
        throw Exception('Please select a shipping address');
      }

      if (_paymentMethods.isEmpty) {
        throw Exception('No payment method selected');
      }

      // Create order
      final order = await CheckoutService.createOrder(
        userId: userId,
        items: _orderItems,
        shippingAddress: _shippingAddress!,
        paymentMethodId: _paymentMethods[selectedPaymentMethod]['id'],
      );

      if (mounted) {
        // Navigate to payment screen with order details
        Navigator.of(context).pushReplacementNamed(
          '/payment',
          arguments: {'orderId': order.id},
        );
      }
    } catch (e) {
      print('Error processing checkout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCheckoutData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
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
                    _buildShippingAddressCard(),
                    _buildOrderItemsSection(),
                    _buildPaymentMethodsSection(),
                    _buildOrderSummarySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          _buildPaymentButton(),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard() {
    if (_shippingAddress == null) {
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
            children: [
              const Text(
                'No shipping address found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/address-list');
                },
                child: const Text('Add Address'),
              ),
            ],
          ),
        ),
      );
    }

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
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_shippingAddress!['label']} - ${_shippingAddress!['recipient_name']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _shippingAddress!['address'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'SF Pro Display',
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

            ..._orderItems.map((item) => Column(
              children: [
                OrderItemWidget(
                  storeName: item.storeName ?? '',
                  productImages: [item.productImage ?? ''],
                  productName: item.productName ?? '',
                  productVariant: item.variant ?? '',
                  price: 'Rp${item.price.toStringAsFixed(0)}',
                  quantity: item.quantity,
                  isSmallScreen: true,
                  onAddNote: () {},
                ),
                if (item != _orderItems.last)
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

            ..._paymentMethods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: PaymentMethodWidget(
                  logoUrl: method['logo_url'],
                  name: method['name'],
                  isSelected: selectedPaymentMethod == index,
                  onTap: () {
                    setState(() {
                      selectedPaymentMethod = index;
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
    final totalAmount = _subtotal + _shippingCost - _discountAmount;

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Harga (${_orderItems.length} Barang)',
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
                  'Rp${totalAmount.toStringAsFixed(0)}',
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
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment_rounded, size: 24),
                    SizedBox(width: 12),
                    Text(
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