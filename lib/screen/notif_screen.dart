import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'dart:async';

class NotifScreen extends StatefulWidget {
  const NotifScreen({Key? key}) : super(key: key);

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> with SingleTickerProviderStateMixin {
  // Tab controller for different notification categories
  late TabController _tabController;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  Set<String> _readOrderIds = {};
  Set<String> _readPromoSystemIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize timeago with Indonesian locale
    timeago.setLocaleMessages('id', timeago.IdMessages());
    
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadNotifications();
    _setupRealtimeSubscription();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final notifications = await NotificationService.getUserNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) return;

    NotificationService.supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
      if (mounted) {
        setState(() {
          _notifications = NotificationModel.fromJsonList(data);
        });
      }
    });
  }

  // Filter notifications based on selected tab
  List<NotificationModel> get _filteredNotifications {
    switch (_tabController.index) {
      case 0: // All notifications
        return _notifications;
      case 1: // Transactions
        return _notifications.where((n) => n.type == 'order').toList();
      case 2: // Promos
        return _notifications.where((n) => n.type == 'promo').toList();
      case 3: // System
        return _notifications.where((n) => n.type == 'system').toList();
      default:
        return _notifications;
    }
  }

  // Mark all notifications as read (local only)
  Future<void> _markAllAsRead() async {
    setState(() {
      _readOrderIds.addAll(_notifications.where((n) => n.type == 'order').map((n) => n.id));
      _readPromoSystemIds.addAll(_notifications.where((n) => n.type == 'promo' || n.type == 'system').map((n) => n.id));
    });
  }

  // Mark a single notification as read (local only)
  Future<void> _markAsRead(NotificationModel notification) async {
    setState(() {
      if (notification.type == 'order') {
        _readOrderIds.add(notification.id);
      } else if (notification.type == 'promo' || notification.type == 'system') {
        _readPromoSystemIds.add(notification.id);
      }
    });
  }

  // Get icon and color based on notification type and data
  Map<String, dynamic> _getNotificationStyle(NotificationModel notification) {
    if (notification.type == 'order') {
      final status = notification.data?['status'] as String?;
      final paymentStatus = notification.data?['payment_status'] as String?;

      // Pembayaran Berhasil
      if (notification.title == 'Pembayaran Berhasil') {
        return {
          'icon': Icons.verified,
          'color': AppColors.success,
        };
      }
      if (paymentStatus == 'pending') {
        return {
          'icon': Icons.payment_outlined,
          'color': AppColors.warning,
        };
      } else if (paymentStatus == 'failed') {
        return {
          'icon': Icons.error_outline,
          'color': AppColors.error,
        };
      } else {
        switch (status) {
          case 'processing':
            return {
              'icon': Icons.inventory_2_outlined,
              'color': AppColors.primaryColor,
            };
          case 'waiting_shipment':
            return {
              'icon': Icons.schedule_outlined,
              'color': AppColors.primaryColor,
            };
          case 'shipped':
            return {
              'icon': Icons.local_shipping_outlined,
              'color': Colors.blue,
            };
          case 'delivered':
            return {
              'icon': Icons.check_circle_outline,
              'color': AppColors.success,
            };
          default:
            return {
              'icon': Icons.shopping_bag_outlined,
              'color': Colors.grey,
            };
        }
      }
    } else if (notification.type == 'promo') {
      return {
        'icon': Icons.local_offer_outlined,
        'color': Colors.orange,
      };
    } else {
      return {
        'icon': Icons.notifications_outlined,
        'color': Colors.grey,
      };
    }
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _filteredNotifications.isEmpty
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
    final int unreadCount = _notifications.where((n) => !n.isRead).length;

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

  Widget _buildNotificationItem(NotificationModel notification) {
    final bool isPromoOrSystem = notification.type == 'promo' || notification.type == 'system';
    final bool isOrder = notification.type == 'order';
    final bool isUnread = isPromoOrSystem
        ? !_readPromoSystemIds.contains(notification.id)
        : !_readOrderIds.contains(notification.id);
    final style = _getNotificationStyle(notification);

    return GestureDetector(
      onTap: () {
        // Mark as read hanya untuk promo/sistem
        if (isPromoOrSystem && !notification.isRead) {
          _markAsRead(notification);
        }
        // Mark as read lokal untuk order
        if (isOrder && !_readOrderIds.contains(notification.id)) {
          setState(() {
            _readOrderIds.add(notification.id);
          });
        }
        // Navigate based on notification type and data
        if (notification.type == 'order' && notification.data?['order_id'] != null) {
          Navigator.pushNamed(
            context,
            '/order-detail',
            arguments: notification.data!['order_id'],
          );
        } else if (notification.type == 'promo' && notification.data?['promo_id'] != null) {
          Navigator.pushNamed(
            context,
            '/promo',
            arguments: notification.data!['promo_id'],
          );
        }
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
                color: style['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                style['icon'],
                color: style['color'],
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with unread indicator (semua tipe)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
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
                    notification.message,
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
                    timeago.format(notification.createdAt, locale: 'id'),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}