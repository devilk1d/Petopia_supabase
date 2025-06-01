import '../models/notification_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final supabase = Supabase.instance.client;

  // Get user notifications from orders and other tables
  static Future<List<NotificationModel>> getUserNotifications({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get orders with their items
      final ordersResponse = await supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              product:products (
                name
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      // Get promos
      final promosResponse = await supabase
          .from('promos')
          .select()
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      // Convert orders to notifications
      final orderNotifications = (ordersResponse as List).expand((order) {
        final status = order['status'] as String;
        final paymentStatus = order['payment_status'] as String;
        final orderNumber = order['order_number'] ?? order['id'];
        String type = 'order';
        Map<String, dynamic> data = {
          'order_id': order['id'],
          'order_number': orderNumber,
          'status': status,
          'payment_status': paymentStatus,
        };
        List<NotificationModel> notifs = [];

        // Notifikasi pembayaran berhasil
        if (paymentStatus == 'paid') {
          notifs.add(NotificationModel(
            id: order['id'] + '_paid',
            title: 'Pembayaran Berhasil',
            message: 'Pembayaran untuk pesanan $orderNumber berhasil.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        }
        // Notifikasi menunggu pembayaran
        else if (paymentStatus == 'pending') {
          notifs.add(NotificationModel(
            id: order['id'] + '_pending',
            title: 'Menunggu Pembayaran',
            message: 'Pesanan $orderNumber menunggu pembayaran Anda.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        }
        // Notifikasi pembayaran gagal
        else if (paymentStatus == 'failed') {
          notifs.add(NotificationModel(
            id: order['id'] + '_failed',
            title: 'Pembayaran Gagal',
            message: 'Pembayaran untuk pesanan $orderNumber gagal.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        }

        // Notifikasi status pesanan (selalu buat jika status shipped/delivered)
        if (status == 'shipped') {
          notifs.add(NotificationModel(
            id: order['id'] + '_shipped',
            title: 'Pesanan Dalam Perjalanan',
            message: 'Pesanan $orderNumber sedang dalam perjalanan.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        } else if (status == 'delivered') {
          notifs.add(NotificationModel(
            id: order['id'] + '_delivered',
            title: 'Pesanan Diterima',
            message: 'Pesanan $orderNumber telah diterima.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        } else if (status == 'processing') {
          notifs.add(NotificationModel(
            id: order['id'] + '_processing',
            title: 'Pesanan Diproses',
            message: 'Pesanan $orderNumber sedang diproses.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        } else if (status == 'waiting_shipment') {
          notifs.add(NotificationModel(
            id: order['id'] + '_waiting',
            title: 'Menunggu Pengiriman',
            message: 'Pesanan $orderNumber sedang menunggu pengiriman.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        } else if (status == 'cancelled') {
          notifs.add(NotificationModel(
            id: order['id'] + '_cancelled',
            title: 'Pesanan Dibatalkan',
            message: 'Pesanan $orderNumber telah dibatalkan.',
            type: type,
            data: data,
            isRead: order['is_read'] ?? false,
            createdAt: DateTime.parse(order['created_at']),
          ));
        }
        return notifs;
      }).toList();

      // Convert promos to notifications
      final promoNotifications = (promosResponse as List).map((promo) {
        return NotificationModel(
          id: promo['id'],
          title: promo['title'],
          message: promo['description'],
          type: 'promo',
          data: {
            'promo_id': promo['id'],
            'discount': promo['discount'],
            'valid_until': promo['valid_until'],
          },
          isRead: false,
          createdAt: DateTime.parse(promo['created_at']),
        );
      }).toList();

      // Combine and sort all notifications by date
      final allNotifications = [...orderNotifications, ...promoNotifications];
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allNotifications;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('orders')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Mark notification as read (for notifications table only)
  static Future<void> markAsRead(String notificationId) async {
    try {
      // Jika id mengandung 'promo' atau 'system', update tabel notifications
      if (notificationId.contains('promo') || notificationId.contains('system')) {
        final userId = AuthService.currentUserId;
        if (userId == null) throw Exception('User not authenticated');
        await supabase
            .from('notifications')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            })
            .eq('id', notificationId)
            .eq('user_id', userId);
      }
      // Jika id notifikasi order, tidak perlu update apa-apa
      return;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read (for notifications table only)
  static Future<void> markAllAsRead() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');
      await supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
      // Untuk notifikasi order, tidak perlu update apa-apa
      return;
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

  // Delete all notifications
  static Future<void> deleteAllNotifications() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Create notification (admin/system only)
  static Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'type': type,
            'data': data,
            'is_read': false,
          })
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Create notifications for multiple users (admin/system only)
  static Future<List<NotificationModel>> createNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'is_read': false,
      }).toList();

      final response = await supabase
          .from('notifications')
          .insert(notifications)
          .select();

      return NotificationModel.fromJsonList(response);
    } catch (e) {
      throw Exception('Failed to create notifications: $e');
    }
  }
} 