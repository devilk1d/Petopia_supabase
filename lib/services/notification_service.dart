import '../models/notification_model.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final supabase = Supabase.instance.client;

  // Get all notifications for the current user
  static Future<List<NotificationModel>> getUserNotifications({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get notifications from the notifications table
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return 0;

      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Create notification for order updates
  static Future<void> createOrderNotification({
    required String userId,
    required String orderId,
    required String orderNumber,
    required String status,
    required String paymentStatus,
  }) async {
    try {
      String title = '';
      String message = '';
      String type = 'order';

      // Generate notification based on status
      if (paymentStatus == 'paid' && status == 'processing') {
        title = 'Pembayaran Berhasil';
        message = 'Pembayaran untuk pesanan $orderNumber berhasil dan sedang diproses.';
      } else if (status == 'shipped') {
        title = 'Pesanan Dikirim';
        message = 'Pesanan $orderNumber sedang dalam perjalanan menuju alamat Anda.';
      } else if (status == 'delivered') {
        title = 'Pesanan Tiba';
        message = 'Pesanan $orderNumber telah tiba di alamat Anda.';
      } else if (paymentStatus == 'failed') {
        title = 'Pembayaran Gagal';
        message = 'Pembayaran untuk pesanan $orderNumber gagal. Silakan coba lagi.';
      } else if (status == 'cancelled') {
        title = 'Pesanan Dibatalkan';
        message = 'Pesanan $orderNumber telah dibatalkan.';
      } else {
        return; // Don't create notification for other statuses
      }

      await supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': {
          'order_id': orderId,
          'order_number': orderNumber,
          'status': status,
          'payment_status': paymentStatus,
        },
        'is_read': false,
      });
    } catch (e) {
      print('Error creating order notification: $e');
    }
  }

  // Create notification for new articles
  static Future<void> createArticleNotification({
    required String articleId,
    required String title,
    required String categoryName,
  }) async {
    try {
      // Get all users to send notification
      final usersResponse = await supabase
          .from('users')
          .select('id');

      final users = usersResponse as List;

      final notifications = users.map((user) => {
        'user_id': user['id'],
        'type': 'article',
        'title': 'Artikel Baru: $categoryName',
        'message': 'Ada artikel baru tentang $categoryName: "$title"',
        'data': {
          'article_id': articleId,
          'category': categoryName,
        },
        'is_read': false,
      }).toList();

      if (notifications.isNotEmpty) {
        await supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      print('Error creating article notification: $e');
    }
  }

  // Create promo notification
  static Future<void> createPromoNotification({
    required String promoId,
    required String title,
    required String description,
    required String discountType,
    required double discountValue,
  }) async {
    try {
      // Get all users to send notification
      final usersResponse = await supabase
          .from('users')
          .select('id');

      final users = usersResponse as List;

      String discountText = discountType == 'percentage'
          ? '${discountValue.toInt()}% OFF'
          : 'Diskon ${discountValue.toInt()}';

      final notifications = users.map((user) => {
        'user_id': user['id'],
        'type': 'promo',
        'title': 'Promo Baru: $discountText',
        'message': '$title - $description',
        'data': {
          'promo_id': promoId,
          'discount_type': discountType,
          'discount_value': discountValue,
        },
        'is_read': false,
      }).toList();

      if (notifications.isNotEmpty) {
        await supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      print('Error creating promo notification: $e');
    }
  }

  // Create system notification
  static Future<void> createSystemNotification({
    required String title,
    required String message,
    String? userId, // If null, send to all users
  }) async {
    try {
      if (userId != null) {
        // Send to specific user
        await supabase.from('notifications').insert({
          'user_id': userId,
          'type': 'system',
          'title': title,
          'message': message,
          'data': {},
          'is_read': false,
        });
      } else {
        // Send to all users
        final usersResponse = await supabase
            .from('users')
            .select('id');

        final users = usersResponse as List;

        final notifications = users.map((user) => {
          'user_id': user['id'],
          'type': 'system',
          'title': title,
          'message': message,
          'data': {},
          'is_read': false,
        }).toList();

        if (notifications.isNotEmpty) {
          await supabase.from('notifications').insert(notifications);
        }
      }
    } catch (e) {
      print('Error creating system notification: $e');
    }
  }

  // Subscribe to real-time notifications
  static Stream<List<NotificationModel>> subscribeToNotifications() {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)  // This is correct inside stream()
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  // Subscribe to unread count changes
  static Stream<int> subscribeToUnreadCount() {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      return Stream.value(0);
    }

    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.where((n) => n['is_read'] == false).length);
  }
}