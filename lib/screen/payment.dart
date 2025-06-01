import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/countdown_timer.dart';
import '../utils/colors.dart';
import '../services/order_service.dart';
import 'dart:async';
import 'dart:math';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCopied = false;
  bool _isConfirmingPayment = false;

  // Order data from arguments
  String? _orderId;
  String? _orderNumber;
  double? _totalAmount;
  Map<String, dynamic>? _paymentMethod;
  String? _virtualAccountNumber;

  // Timer related
  DateTime? _paymentDeadline;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePaymentTimer();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _initializePaymentTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final deadlineTimestamp = prefs.getInt('payment_deadline_${_orderId ?? 'default'}');

    if (deadlineTimestamp != null) {
      _paymentDeadline = DateTime.fromMillisecondsSinceEpoch(deadlineTimestamp);
    } else {
      // Set default 24 hours from now
      _paymentDeadline = DateTime.now().add(const Duration(hours: 24));
      await prefs.setInt('payment_deadline_${_orderId ?? 'default'}', _paymentDeadline!.millisecondsSinceEpoch);
    }

    _updateRemainingTime();

    // Start periodic timer to update remaining time
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateRemainingTime() {
    if (_paymentDeadline != null) {
      final now = DateTime.now();
      final difference = _paymentDeadline!.difference(now);

      setState(() {
        _remainingSeconds = difference.inSeconds > 0 ? difference.inSeconds : 0;
      });
    }
  }

  void _generateVirtualAccountNumber() {
    if (_paymentMethod == null) return;

    // Get bank code based on payment method
    String bankCode = '807777'; // Default for BCA
    if (_paymentMethod!['name'].toString().toLowerCase().contains('mandiri')) {
      bankCode = '888888';
    } else if (_paymentMethod!['name'].toString().toLowerCase().contains('bri')) {
      bankCode = '002';
    }

    // Generate random 8 digits using Random
    final random = Random();
    final randomDigits = List.generate(8, (_) => random.nextInt(10)).join();

    // Combine bank code and random digits
    setState(() {
      _virtualAccountNumber = '$bankCode$randomDigits';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _orderId = args['orderId'];
      _orderNumber = args['orderNumber'];
      _totalAmount = args['totalAmount'];
      _paymentMethod = args['paymentMethod'];
      _generateVirtualAccountNumber();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));

    setState(() {
      _isCopied = true;
    });

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Nomor rekening berhasil disalin',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  Future<void> _confirmPayment() async {
    if (_orderId == null) return;

    setState(() {
      _isConfirmingPayment = true;
    });

    try {
      await OrderService.updatePaymentStatus(_orderId!, 'paid');

      // Clear the timer from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('payment_deadline_${_orderId}');

      if (mounted) {
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
            content: Text('Gagal mengonfirmasi pembayaran: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_orderId != null) {
      try {
        await OrderService.updateOrderStatus(_orderId!, 'processing', '');
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
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildTimerSection()),
            _buildPaymentInfoCard(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Pembayaran',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTimerSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern clock container
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.schedule_outlined,
                  size: 64,
                  color: AppColors.primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Timer instruction
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Selesaikan pembayaran dalam',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // Countdown timer
            if (_remainingSeconds > 0)
              CountdownTimer(
                hours: _remainingSeconds ~/ 3600,
                minutes: (_remainingSeconds % 3600) ~/ 60,
                seconds: _remainingSeconds % 60,
                onTick: _updateRemainingTime,
              )
            else
              Text(
                'Waktu habis',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Order info
            if (_orderNumber != null) ...[
              _buildInfoRow('Nomor Pesanan', _orderNumber!),
              const SizedBox(height: 20),
            ],

            // Payment amount
            Column(
              children: [
                Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp${_formatPrice(_totalAmount ?? 0)}',
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 28,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Divider
            Divider(color: Colors.grey[200], thickness: 1),

            const SizedBox(height: 24),

            // VA info
            Text(
              'Transfer ke Virtual Account',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // VA number container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  // Bank logo
                  Image.asset(
                    _paymentMethod?['logo_url'] ?? 'assets/images/bca.png',
                    width: 60,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 32,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Text(
                            _paymentMethod?['name']?.split(' ')[0] ?? 'BCA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 16),

                  // VA number
                  Expanded(
                    child: Text(
                      _virtualAccountNumber ?? 'Generating...',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Copy button
            _buildCopyButton(),

            const SizedBox(height: 24),

            // Confirm payment button
            _buildConfirmButton(),

            const SizedBox(height: 8),

            // Info text
            Text(
              'Tekan konfirmasi setelah transfer berhasil',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyButton() {
    return GestureDetector(
      onTap: () => _copyToClipboard(context, _virtualAccountNumber ?? ''),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _isCopied ? AppColors.success : AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isCopied ? AppColors.success : AppColors.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isCopied ? Icons.check : Icons.copy_rounded,
              size: 16,
              color: _isCopied ? Colors.white : AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              _isCopied ? 'Tersalin!' : 'Salin Nomor',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                color: _isCopied ? Colors.white : AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isConfirmingPayment ? null : _confirmPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: _isConfirmingPayment
            ? Row(
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
            const SizedBox(width: 12),
            const Text(
              'Memproses...',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : const Text(
          'Konfirmasi Pembayaran',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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