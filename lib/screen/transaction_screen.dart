import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import '../utils/datetime_utils.dart';
import '../widgets/search_bar.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabTitles = ['Semua', 'Pending', 'Berlangsung', 'Selesai'];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    _filterTransactions();
  }

  void _filterTransactions() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredTransactions = List.from(_transactions);
      });
      return;
    }

    final filtered = _transactions.where((transaction) {
      final invoiceNumber = transaction['invoiceNumber']?.toString().toLowerCase() ?? '';
      final productName = transaction['productName']?.toString().toLowerCase() ?? '';
      final storeName = transaction['storeName']?.toString().toLowerCase() ?? '';

      return invoiceNumber.contains(_searchQuery) ||
          productName.contains(_searchQuery) ||
          storeName.contains(_searchQuery);
    }).toList();

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> transactions;

      switch (_selectedTabIndex) {
        case 1: // Pending
          transactions = await TransactionService.getTransactionsByStatus('PENDING');
          break;
        case 2: // Berlangsung
          transactions = await TransactionService.getTransactionsByStatus('ONGOING');
          break;
        case 3: // Selesai
          transactions = await TransactionService.getTransactionsByStatus('COMPLETED');
          break;
        case 0: // Semua
        default:
          transactions = await TransactionService.getTransactions();
          break;
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _filteredTransactions = List.from(transactions);
          _isLoading = false;
        });

        // Apply current search filter if any
        if (_searchQuery.isNotEmpty) {
          _filterTransactions();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat transaksi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredTransactions = List.from(_transactions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.getCurrentUserId() != null;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildLoginPrompt(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchAndTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                  : _filteredTransactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Silahkan login terlebih dahulu',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'untuk melihat riwayat transaksi Anda',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: const Text(
        'Riwayat Transaksi',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSearchAndTabs() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: 'Cari transaksi...',
            enabled: true,
            onChanged: (value) {
              // Real-time search handled by listener
            },
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: _clearSearch,
            )
                : const Icon(Icons.search, color: Colors.grey),
          ),
        ),

        // Search results info
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Hasil pencarian untuk "$_searchQuery" (${_filteredTransactions.length} transaksi)',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (_filteredTransactions.length != _transactions.length)
                  TextButton(
                    onPressed: _clearSearch,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Tab Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _tabTitles.length,
            itemBuilder: (context, index) => _buildTabItem(index),
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        _loadTransactions();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Text(
              _tabTitles[index],
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primaryColor : Colors.grey,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionCard(_filteredTransactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    // Safely get values with null checks and default values
    final String orderId = transaction['id']?.toString() ?? '';
    final String invoiceNumber = transaction['invoiceNumber']?.toString() ?? 'N/A';
    final String storeName = transaction['storeName']?.toString() ?? 'Unknown Store';
    final String storeImage = transaction['storeImage']?.toString() ?? '';
    final String productName = transaction['productName']?.toString() ?? 'Unknown Product';
    final String productImage = transaction['productImage']?.toString() ?? '';
    final String quantity = transaction['quantity']?.toString() ?? '0 barang';
    final String paymentMethod = transaction['paymentMethod']?.toString() ?? 'Unknown';
    final String status = transaction['status']?.toString() ?? 'UNKNOWN';

    // Safe date handling
    String formattedDate = '-';
    final dateValue = transaction['date'];
    if (transaction.containsKey('created_at')) {
      formattedDate = DateTimeUtils.formatIndonesianDateTime(transaction['created_at']);
    } else if (dateValue is DateTime) {
      formattedDate = DateTimeUtils.formatIndonesianDateTime(dateValue);
    } else if (dateValue is String) {
      formattedDate = DateTimeUtils.formatIndonesianDateTime(dateValue);
    }

    // Safe double conversion
    double totalAmount = 0.0;
    final totalValue = transaction['totalAmount'];
    if (totalValue is double) {
      totalAmount = totalValue;
    } else if (totalValue is int) {
      totalAmount = totalValue.toDouble();
    } else if (totalValue is String) {
      totalAmount = double.tryParse(totalValue) ?? 0.0;
    }

    Color statusColor;
    String statusText;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        statusColor = AppColors.success;
        statusText = 'Selesai';
        break;
      case 'FAILED':
        statusColor = AppColors.error;
        statusText = 'Gagal';
        break;
      case 'PENDING':
        statusColor = AppColors.warning;
        statusText = 'Menunggu Pembayaran';
        break;
      case 'ON_DELIVERY':
        statusColor = Colors.blue;
        statusText = 'Dalam Perjalanan';
        break;
      case 'ONGOING':
        statusColor = AppColors.primaryColor;
        statusText = 'Dalam Proses';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return GestureDetector(
      onTap: () {
        if (orderId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/order-detail',
            arguments: orderId,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order ID tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
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
        child: Column(
          children: [
            // Store and invoice info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Store icon
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: storeImage.isNotEmpty && storeImage.startsWith('http')
                              ? Image.network(
                            storeImage,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.store,
                                size: 14,
                                color: AppColors.primaryColor,
                              );
                            },
                          )
                              : const Icon(
                            Icons.store,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    invoiceNumber,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: Colors.grey.shade200, height: 1),

            // Product info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: productImage.isNotEmpty && productImage.startsWith('http')
                        ? Image.network(
                      productImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quantity,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Transaction info
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPaymentMethod(paymentMethod),
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),

                  // Status and total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatPrice(totalAmount),
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage;
    String emptyDescription;

    if (_searchQuery.isNotEmpty) {
      emptyMessage = 'Tidak Ada Hasil';
      emptyDescription = 'Tidak ditemukan transaksi dengan pencarian "$_searchQuery"';
    } else {
      emptyMessage = 'Belum Ada Transaksi';
      emptyDescription = 'Mulai belanja untuk melihat riwayat transaksi';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptyDescription,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hapus Pencarian',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Mulai Belanja',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
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