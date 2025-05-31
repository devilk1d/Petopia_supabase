import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/countdown_timer.dart';
import '../utils/colors.dart';
import '../services/order_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isCopied = false;
  bool _isConfirmingPayment = false;

  // Order data from arguments
  String? _orderId;
  String? _orderNumber;
  double? _totalAmount;
  Map<String, dynamic>? _paymentMethod;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Define scale animation for the clock container
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments from navigation
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _orderId = args['orderId'];
      _orderNumber = args['orderNumber'];
      _totalAmount = args['totalAmount'];
      _paymentMethod = args['paymentMethod'];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Update state to show copied animation
    setState(() {
      _isCopied = true;
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Nomor Rekening berhasil disalin',
              style: TextStyle(fontFamily: 'SF Pro Display'),
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

    // Reset copied state after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  Future<void> _confirmPayment() async {
    if (_orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Order ID tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConfirmingPayment = true;
    });

    try {
      // Update payment status to paid
      await OrderService.updatePaymentStatus(_orderId!, 'paid');

      if (mounted) {
        // Navigate to success screen
        Navigator.pushReplacementNamed(
          context,
          '/payment-success',
          arguments: {
            'orderId': _orderId,
            'orderNumber': _orderNumber,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConfirmingPayment = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error konfirmasi pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    // Update order status to processing when user closes payment screen
    if (_orderId != null) {
      try {
        await OrderService.updateOrderStatus(_orderId!, 'processing');
      } catch (e) {
        print('Error updating order status: $e');
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            'Pembayaran',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Clock icon with animation
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/icons/uim_clock.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.access_time,
                              size: 80,
                              color: AppColors.primaryColor,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Countdown title and timer
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'SEGERA LAKUKAN PEMBAYARAN DALAM WAKTU',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Countdown timer
                  const CountdownTimer(
                    hours: 23,
                    minutes: 59,
                    seconds: 33,
                  ),
                ],
              ),
            ),

            // Bottom payment information card
            _buildPaymentInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order number
          if (_orderNumber != null) ...[
            Text(
              'Nomor Pesanan',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _orderNumber!,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Payment amount
          const Text(
            'Jumlah yang harus dibayarkan',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp${_formatPrice(_totalAmount ?? 0)}',
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 32,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          // Virtual account info
          const Text(
            'Transfer ke Nomor Virtual Account ini',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // VA number with bank logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  _paymentMethod?['logo_url'] ?? 'assets/images/bca.png',
                  width: 60,
                  height: 25,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 25,
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          _paymentMethod?['name']?.split(' ')[0] ?? 'BANK',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 15),
                const Text(
                  '80777720973390829',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Copy button
          GestureDetector(
            onTap: () => _copyToClipboard(context, '80777720973390829'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 250,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _isCopied ? AppColors.primaryColor : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isCopied
                        ? AppColors.primaryColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCopied ? Icons.check : Icons.copy_rounded,
                    size: 18,
                    color: _isCopied ? Colors.white : AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCopied ? 'Berhasil Disalin' : 'Salin Nomor Rekening',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 15,
                      color: _isCopied ? Colors.white : AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Confirm payment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConfirmingPayment ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConfirmingPayment ? Colors.grey : AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isConfirmingPayment
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
                    'Memproses...',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Info text
          Text(
            'Klik tombol di atas setelah melakukan transfer',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}