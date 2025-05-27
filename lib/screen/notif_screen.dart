import 'package:flutter/material.dart';
import '../utils/colors.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({Key? key}) : super(key: key);

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> with SingleTickerProviderStateMixin {
  // Tab controller for different notification categories
  late TabController _tabController;

  // Sample notification data
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'transaction',
      'title': 'Pesanan Dikirim',
      'description': 'Pesanan Royal Canin Sensible Adult Dry Cat Food sedang dalam pengiriman.',
      'time': '20 menit yang lalu',
      'isRead': false,
      'icon': Icons.local_shipping_outlined,
      'iconColor': Colors.blue,
    },
    {
      'type': 'promo',
      'title': 'Diskon 25% PETKIT',
      'description': 'Dapatkan diskon 25% untuk seluruh produk PETKIT Indonesia. Periode promo sampai 30 April 2025.',
      'time': '1 jam yang lalu',
      'isRead': false,
      'icon': Icons.local_offer_outlined,
      'iconColor': Colors.orange,
    },
    {
      'type': 'transaction',
      'title': 'Pesanan Selesai',
      'description': 'Pesanan Ceramic Pet Bowl telah diterima. Silakan berikan penilaian.',
      'time': '3 jam yang lalu',
      'isRead': true,
      'icon': Icons.check_circle_outline,
      'iconColor': Colors.green,
    },
    {
      'type': 'promo',
      'title': 'Promo Makanan Hewan',
      'description': 'Nikmati diskon hingga 40% untuk seluruh produk makanan kucing dan anjing.',
      'time': '5 jam yang lalu',
      'isRead': true,
      'icon': Icons.pets_outlined,
      'iconColor': AppColors.primaryColor,
    },
    {
      'type': 'transaction',
      'title': 'Pembayaran Berhasil',
      'description': 'Pembayaran untuk PETKIT YumShare Gemini Dual-hopper with Camera telah berhasil.',
      'time': '1 hari yang lalu',
      'isRead': true,
      'icon': Icons.payment_outlined,
      'iconColor': Colors.green,
    },
    {
      'type': 'system',
      'title': 'Update Aplikasi',
      'description': 'Update aplikasi Petopia ke versi terbaru untuk mendapatkan fitur baru.',
      'time': '2 hari yang lalu',
      'isRead': true,
      'icon': Icons.system_update_outlined,
      'iconColor': Colors.purple,
    },
  ];

  // Filter notifications based on selected tab
  List<Map<String, dynamic>> get _filteredNotifications {
    switch (_tabController.index) {
      case 0: // All notifications
        return _notifications;
      case 1: // Transactions
        return _notifications.where((n) => n['type'] == 'transaction').toList();
      case 2: // Promos
        return _notifications.where((n) => n['type'] == 'promo').toList();
      case 3: // System
        return _notifications.where((n) => n['type'] == 'system').toList();
      default:
        return _notifications;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mark all notifications as read
  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  // Mark a single notification as read
  void _markAsRead(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: _filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Count unread notifications
    final int unreadCount = _notifications.where((n) => !n['isRead']).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              color: Colors.black,
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Title
          const Text(
            'Notifikasi',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          // Mark all as read button (only if there are unread notifications)
          unreadCount > 0
              ? GestureDetector(
            onTap: _markAllAsRead,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          )
              : const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: true,
        labelStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Transaksi'),
          Tab(text: 'Promo'),
          Tab(text: 'Sistem'),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = _filteredNotifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final bool isUnread = !notification['isRead'];

    return GestureDetector(
      onTap: () {
        // Mark as read when tapped
        if (!notification['isRead']) {
          _markAsRead(notification);
        }

        // Here you could navigate to relevant screens based on notification type
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: isUnread ? const Color(0xFFF8F8FF) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with circular background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification['iconColor'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification['icon'],
                color: notification['iconColor'],
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with unread indicator
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    notification['description'],
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Time ago
                  Text(
                    notification['time'],
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi Anda akan muncul di sini',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}