import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({Key? key}) : super(key: key);

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _unreadCount = 0;

  // Categories for tabs
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'type': null},
    {'name': 'Pesanan', 'type': 'order'},
    {'name': 'Artikel', 'type': 'article'},
    {'name': 'Promo', 'type': 'promo'},
    {'name': 'System', 'type': 'system'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadNotifications();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get filtered notifications based on selected category
  List<NotificationModel> _getFilteredNotifications(String? type) {
    if (type == null) return _notifications;
    return _notifications.where((notification) => notification.type == type).toList();
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
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);

      // Update UI immediately
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();

      // Update UI immediately
      setState(() {
        _notifications = _notifications.map((notification) =>
            notification.copyWith(isRead: true)
        ).toList();
        _unreadCount = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);

      // Update UI immediately
      setState(() {
        final notification = _notifications.firstWhere((n) => n.id == notificationId);
        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        }
        _notifications.removeWhere((n) => n.id == notificationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read when tapped
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'order':
        if (notification.data?['order_id'] != null) {
          Navigator.pushNamed(
            context,
            '/order-detail',
            arguments: {'orderId': notification.data!['order_id']},
          );
        }
        break;
      case 'article':
        if (notification.data?['article_id'] != null) {
          Navigator.pushNamed(
            context,
            '/article-detail',
            arguments: {'articleId': notification.data!['article_id']},
          );
        }
        break;
      case 'promo':
        Navigator.pushNamed(context, '/promos');
        break;
      case 'system':
      // Handle system notifications if needed
        break;
    }
  }

  // Enhanced function to get specific icons based on notification content
  IconData _getNotificationIcon(NotificationModel notification) {
    switch (notification.type) {
      case 'order':
      // Get specific icon based on order status from title or message
        final title = notification.title.toLowerCase();
        final message = notification.message.toLowerCase();

        if (title.contains('pembayaran berhasil') || message.contains('pembayaran') && message.contains('berhasil')) {
          return Icons.check_circle_outline; // Payment success
        } else if (title.contains('pesanan tiba') || title.contains('pesanan diterima') || message.contains('telah tiba')) {
          return Icons.home_outlined; // Package delivered
        } else if (title.contains('pesanan dikirim') || title.contains('dalam perjalanan') || message.contains('dalam perjalanan')) {
          return Icons.local_shipping_outlined; // In transit
        } else if (title.contains('pesanan diproses') || message.contains('diproses')) {
          return Icons.settings_outlined; // Processing
        } else if (title.contains('pembayaran gagal') || message.contains('pembayaran') && message.contains('gagal')) {
          return Icons.error_outline; // Payment failed
        } else if (title.contains('dibatalkan') || message.contains('dibatalkan')) {
          return Icons.cancel_outlined; // Cancelled
        } else if (title.contains('menunggu pembayaran') || message.contains('menunggu pembayaran')) {
          return Icons.payment_outlined; // Waiting payment
        } else {
          return Icons.shopping_bag_outlined; // Default order icon
        }

      case 'article':
        return Icons.article_outlined;

      case 'promo':
        return Icons.local_offer_outlined;

      case 'system':
        final title = notification.title.toLowerCase();
        if (title.contains('selamat datang') || title.contains('welcome')) {
          return Icons.celebration_outlined; // Welcome
        } else {
          return Icons.info_outline; // Default system
        }

      default:
        return Icons.notifications_outlined;
    }
  }

  // Enhanced function to get specific colors based on notification content
  Color _getNotificationColor(NotificationModel notification) {
    switch (notification.type) {
      case 'order':
      // Get specific color based on order status from title or message
        final title = notification.title.toLowerCase();
        final message = notification.message.toLowerCase();

        if (title.contains('pembayaran berhasil') || message.contains('pembayaran') && message.contains('berhasil')) {
          return const Color(0xFF4CAF50); // Green for success
        } else if (title.contains('pesanan tiba') || title.contains('pesanan diterima') || message.contains('telah tiba')) {
          return const Color(0xFF2E7D32); // Dark green for delivered
        } else if (title.contains('pesanan dikirim') || title.contains('dalam perjalanan') || message.contains('dalam perjalanan')) {
          return const Color(0xFF1976D2); // Blue for shipping
        } else if (title.contains('pesanan diproses') || message.contains('diproses')) {
          return const Color(0xFFFF9800); // Orange for processing
        } else if (title.contains('pembayaran gagal') || message.contains('pembayaran') && message.contains('gagal')) {
          return const Color(0xFFE53935); // Red for failed
        } else if (title.contains('dibatalkan') || message.contains('dibatalkan')) {
          return const Color(0xFF757575); // Grey for cancelled
        } else if (title.contains('menunggu pembayaran') || message.contains('menunggu pembayaran')) {
          return const Color(0xFFFFB74D); // Light orange for waiting payment
        } else {
          return AppColors.primaryColor; // Default pink
        }

      case 'article':
        return const Color(0xFF2196F3); // Blue for articles

      case 'promo':
        return const Color(0xFFFF5722); // Orange-red for promos

      case 'system':
        final title = notification.title.toLowerCase();
        if (title.contains('selamat datang') || title.contains('welcome')) {
          return const Color(0xFF9C27B0); // Purple for welcome
        } else {
          return const Color(0xFF607D8B); // Blue grey for system
        }

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    if (!AuthService.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Please login to view notifications',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryColor,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: _categories.map((category) => Tab(text: category['name'])).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          final filteredNotifications = _getFilteredNotifications(category['type']);

          if (filteredNotifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When you have notifications, they\'ll appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            color: AppColors.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                final notificationIcon = _getNotificationIcon(notification);
                final notificationColor = _getNotificationColor(notification);

                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteNotification(notification.id);
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.white
                          : notificationColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: notification.isRead
                            ? Colors.grey.withOpacity(0.2)
                            : notificationColor.withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () => _handleNotificationTap(notification),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: notificationColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          notificationIcon,
                          color: notificationColor,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notificationColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            timeago.format(notification.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}