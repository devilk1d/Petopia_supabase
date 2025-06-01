import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  String? _orderId;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getOrderIdAndLoad();
  }

  void _getOrderIdAndLoad() {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null) {
      _setError('Order ID tidak ditemukan');
      return;
    }

    // Handle both cases: when args is a Map or direct String
    String orderId;
    if (args is Map<String, dynamic>) {
      orderId = args['orderId']?.toString() ?? '';
    } else {
      orderId = args.toString();
    }

    if (orderId.isEmpty || orderId == 'null') {
      _setError('Order ID tidak valid');
      return;
    }

    _orderId = orderId;
    _loadOrderData();
  }

  void _setError(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  Future<void> _loadOrderData() async {
    if (_orderId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orderData = await OrderService.getOrderById(_orderId!);

      if (orderData != null) {
        // Safe conversion using JSON encode/decode
        final jsonString = jsonEncode(orderData);
        final safeOrderData = jsonDecode(jsonString) as Map<String, dynamic>;

        setState(() {
          _orderData = safeOrderData;
          _isLoading = false;
        });
      } else {
        _setError('Order tidak ditemukan');
      }
    } catch (e) {
      _setError('Gagal memuat data order: $e');
    }
  }

  Future<void> _confirmOrderReceived() async {
    if (_orderId == null) return;

    try {
      await OrderService.confirmOrderReceived(_orderId!);
      await _loadOrderData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Pesanan telah dikonfirmasi diterima!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal konfirmasi: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _continuePayment() {
    if (_orderData == null) return;

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'orderId': _orderData!['id'],
        'orderNumber': _orderData!['order_number'],
        'totalAmount': _orderData!['total_amount'],
        'paymentMethod': _orderData!['payment_methods'],
      },
    );
  }

  void _copyTrackingNumber(String trackingNumber) {
    Clipboard.setData(ClipboardData(text: trackingNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Nomor resi disalin'),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Safe method to get string value
  String _safeGetString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  // Safe method to get double value
  double _safeGetDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Safe method to get int value
  int _safeGetInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Safe method to convert any object to Map<String, dynamic>
  Map<String, dynamic> _safeToMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        // If direct conversion fails, use JSON encode/decode
        try {
          final jsonString = jsonEncode(value);
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e2) {
          return <String, dynamic>{};
        }
      }
    }
    return <String, dynamic>{};
  }

  // Safe method to convert list
  List<Map<String, dynamic>> _safeToListOfMaps(dynamic value) {
    if (value == null) return <Map<String, dynamic>>[];
    if (value is List) {
      return value.map((item) => _safeToMap(item)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  // Safe image widget that handles both network and asset images
  Widget _buildSafeImage({
    required String? imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    Widget imageWidget;

    if (imageUrl == null || imageUrl.isEmpty) {
      // No image provided, show placeholder
      imageWidget = Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: width * 0.4,
        ),
      );
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Network image
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
            size: width * 0.4,
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppColors.primaryColor,
              ),
            ),
          );
        },
      );
    } else if (imageUrl.startsWith('assets/')) {
      // Asset image
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
            size: width * 0.4,
          ),
        ),
      );
    } else {
      // Unknown format, show placeholder
      imageWidget = Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: width * 0.4,
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }

    return _buildOrderDetailScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 16),
            Text(
              'Memuat detail pesanan...',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOrderStatusCard(),
                  const SizedBox(height: 16),
                  _buildOrderInfoCard(),
                  const SizedBox(height: 16),
                  _buildProductsCard(),
                  const SizedBox(height: 16),
                  _buildShippingCard(),
                  const SizedBox(height: 16),
                  _buildPaymentSummaryCard(),
                  const SizedBox(height: 10), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildSliverAppBar() {
    final orderNumber = _safeGetString(_orderData?['order_number'], defaultValue: 'N/A');

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 50, right: 50, bottom: 60),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor Pesanan',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orderNumber,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
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

  Widget _buildOrderStatusCard() {
    final status = _safeGetString(_orderData?['status'], defaultValue: 'pending_payment');
    final paymentStatus = _safeGetString(_orderData?['payment_status'], defaultValue: 'pending');

    String statusText = _getStatusText(status, paymentStatus);
    Color statusColor = _getStatusColor(status, paymentStatus);
    IconData statusIcon = _getStatusIcon(status, paymentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              size: 40,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(status, paymentStatus),
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final createdAt = _orderData?['created_at'];
    String formattedDate = 'N/A';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString()).toLocal();
        formattedDate = _formatDate(date);
      } catch (e) {
        formattedDate = 'Format tanggal tidak valid';
      }
    }

    final trackingNumber = _safeGetString(_orderData?['tracking_number']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pesanan',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Tanggal Pemesanan', formattedDate, Icons.calendar_today),
          if (trackingNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTrackingRow('Nomor Resi', trackingNumber),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingRow(String label, String trackingNumber) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_shipping,
            size: 20,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                trackingNumber,
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _copyTrackingNumber(trackingNumber),
          icon: const Icon(
            Icons.copy,
            size: 20,
            color: AppColors.primaryColor,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsCard() {
    final orderItemsRaw = _orderData?['order_items'];
    final orderItems = _safeToListOfMaps(orderItemsRaw);

    if (orderItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: const Center(
          child: Text(
            'Tidak ada produk',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Safe grouping items by store
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in orderItems) {
      try {
        final sellerId = _safeGetString(item['seller_id'], defaultValue: 'unknown');
        final productData = _safeToMap(item['product']);
        final storeName = _safeGetString(productData['seller_store_name'], defaultValue: 'Unknown Store');

        if (!groupedItems.containsKey(sellerId)) {
          groupedItems[sellerId] = [];
        }

        // Create safe item with store name
        final safeItem = Map<String, dynamic>.from(item);
        safeItem['store_name'] = storeName;
        groupedItems[sellerId]!.add(safeItem);
      } catch (e) {
        print('Error processing item: $e');
        // Skip this item if there's an error
        continue;
      }
    }

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Produk Pesanan',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orderItems.length} item',
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...groupedItems.entries.map((storeEntry) {
            final storeItems = storeEntry.value;
            if (storeItems.isEmpty) return const SizedBox.shrink();

            final storeName = _safeGetString(storeItems.first['store_name'], defaultValue: 'Unknown Store');
            final isLastStore = storeEntry.key == groupedItems.keys.last;

            return Column(
              children: [
                if (groupedItems.length > 1) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: const Color(0xFFF8F9FA),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          storeName,
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ...storeItems.asMap().entries.map((itemEntry) {
                  final item = itemEntry.value;
                  final isLastInStore = itemEntry.key == storeItems.length - 1;

                  return Column(
                    children: [
                      _buildProductItem(item),
                      if (!isLastInStore || !isLastStore)
                        Divider(
                          height: 1,
                          color: Colors.grey[200],
                          indent: 20,
                          endIndent: 20,
                        ),
                    ],
                  );
                }).toList(),
              ],
            );
          }).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final productData = _safeToMap(item['product']);
    final productName = _safeGetString(productData['name'], defaultValue: 'Unknown Product');
    final productImage = _safeGetString(productData['image_url']);
    final quantity = _safeGetInt(item['quantity'], defaultValue: 1);
    final price = _safeGetDouble(item['price']);
    final variant = _safeGetString(item['variant']);
    final storeName = _safeGetString(productData['seller_store_name'], defaultValue: 'Unknown Store');
    final storeImage = _safeGetString(productData['seller_store_image']);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image with safe loading
          _buildSafeImage(
            imageUrl: productImage.isNotEmpty ? productImage : null,
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 16),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store profile (image + name)
                Row(
                  children: [
                    _buildSafeImage(
                      imageUrl: storeImage.isNotEmpty ? storeImage : null,
                      width: 24,
                      height: 24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  productName,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      variant,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Price and quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp${_formatPrice(price)}',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x$quantity',
                        style: const TextStyle(
                          fontSize: 12,
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
    );
  }

  Widget _buildShippingCard() {
    final shippingAddressRaw = _orderData?['shipping_address'];
    final shippingAddress = _safeToMap(shippingAddressRaw);

    final recipientName = _safeGetString(
        shippingAddress['recipientName'] ?? shippingAddress['recipient_name'],
        defaultValue: 'Unknown'
    );
    final address = _safeGetString(shippingAddress['address'], defaultValue: 'Alamat tidak tersedia');
    final phone = _safeGetString(shippingAddress['phone'], defaultValue: 'Nomor tidak tersedia');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Alamat Pengiriman',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipientName,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    final totalAmount = _safeGetDouble(_orderData?['total_amount']);
    final shippingCost = _safeGetDouble(_orderData?['shipping_cost']);
    final discountAmount = _safeGetDouble(_orderData?['discount_amount']);
    final subtotal = totalAmount - shippingCost + discountAmount;
    final paymentMethod = _safeGetString(_orderData?['payment_methods']?['name'] ?? _orderData?['payment_method']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                color: AppColors.primaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Ringkasan Pembayaran',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (paymentMethod.isNotEmpty) ...[
            _buildSummaryRow('Metode Pembayaran', _formatPaymentMethod(paymentMethod)),
            const SizedBox(height: 8),
          ],
          _buildSummaryRow('Subtotal', 'Rp${_formatPrice(subtotal)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Ongkos Kirim', 'Rp${_formatPrice(shippingCost)}'),
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Diskon', '-Rp${_formatPrice(discountAmount)}', isDiscount: true),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey[200], height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Rp${_formatPrice(totalAmount)}',
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          softWrap: true,
          maxLines: 2,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.success : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final status = _safeGetString(_orderData?['status'], defaultValue: 'pending_payment');
    final paymentStatus = _safeGetString(_orderData?['payment_status'], defaultValue: 'pending');

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Continue payment button for pending payments
            if (paymentStatus == 'pending') ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continuePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 20, color: Colors.white,),
                      SizedBox(width: 8),
                      Text(
                        'Lanjutkan Pembayaran',
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
            ],

            // Order received button for shipped orders
            if (status == 'shipped' && paymentStatus == 'paid') ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _showOrderReceivedDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pesanan Diterima',
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
            ],

            // Secondary actions
            if (paymentStatus == 'paid' && status == 'delivered') ...[
              Row(
                children: [
                  // Complaint button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/complaint'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.report_problem_outlined, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Komplain',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/rating',
                          arguments: {
                            'productId': _orderData!['order_items'][0]['product_id'],
                            'orderId': _orderData!['order_items'][0]['id'],
                          },
                        );
                        
                        if (result == true) {
                          // Refresh order details after successful rating
                          _loadOrderData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_outline, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Beri Rating',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOrderReceivedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 10),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.success,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Konfirmasi Penerimaan',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah Anda sudah menerima pesanan dengan baik?',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Belum',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _confirmOrderReceived();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Sudah Diterima',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
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
        );
      },
    );
  }

  // Helper methods
  String _getStatusText(String status, String paymentStatus) {
    if (paymentStatus == 'pending') {
      return 'Menunggu Pembayaran';
    } else if (paymentStatus == 'failed') {
      return 'Pembayaran Gagal';
    } else {
      switch (status) {
        case 'processing':
          return 'Sedang Diproses';
        case 'waiting_shipment':
          return 'Menunggu Pengiriman';
        case 'shipped':
          return 'Dalam Perjalanan';
        case 'delivered':
          return 'Pesanan Selesai';
        default:
          return 'Status Tidak Diketahui';
      }
    }
  }

  String _getStatusDescription(String status, String paymentStatus) {
    if (paymentStatus == 'pending') {
      return 'Silakan lanjutkan pembayaran untuk memproses pesanan Anda';
    } else if (paymentStatus == 'failed') {
      return 'Pembayaran gagal diproses, silakan hubungi customer service';
    } else {
      switch (status) {
        case 'processing':
          return 'Pesanan Anda sedang disiapkan oleh penjual';
        case 'waiting_shipment':
          return 'Pesanan siap dikirim dan menunggu kurir';
        case 'shipped':
          return 'Pesanan sedang dalam perjalanan menuju alamat Anda';
        case 'delivered':
          return 'Pesanan telah berhasil diterima';
        default:
          return 'Hubungi customer service untuk informasi lebih lanjut';
      }
    }
  }

  Color _getStatusColor(String status, String paymentStatus) {
    if (paymentStatus == 'pending') {
      return AppColors.warning;
    } else if (paymentStatus == 'failed') {
      return AppColors.error;
    } else {
      switch (status) {
        case 'processing':
        case 'waiting_shipment':
          return AppColors.primaryColor;
        case 'shipped':
          return Colors.blue;
        case 'delivered':
          return AppColors.success;
        default:
          return Colors.grey;
      }
    }
  }

  IconData _getStatusIcon(String status, String paymentStatus) {
    if (paymentStatus == 'pending') {
      return Icons.payment_outlined;
    } else if (paymentStatus == 'failed') {
      return Icons.error_outline;
    } else {
      switch (status) {
        case 'processing':
          return Icons.inventory_2_outlined;
        case 'waiting_shipment':
          return Icons.schedule_outlined;
        case 'shipped':
          return Icons.local_shipping_outlined;
        case 'delivered':
          return Icons.check_circle_outline;
        default:
          return Icons.help_outline;
      }
    }
  }

  String _formatDate(DateTime date) {
    const List<String> monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final day = date.day.toString();
    final month = monthNames[date.month - 1];
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute WIB';
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  String _formatPaymentMethod(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('alfamart') && lower.contains('lawson')) {
      // Untuk string seperti "Alfamart / Alfamidi / Lawson / Dan+Dan"
      return method.replaceAll(' / Lawson', '\nLawson');
    }
    return method;
  }
}