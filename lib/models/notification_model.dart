import 'dart:convert';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : json['data'] is String
          ? _parseJsonString(json['data'] as String)
          : null,
      isRead: json['is_read'] == true,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static Map<String, dynamic>? _parseJsonString(String jsonStr) {
    try {
      final parsed = jsonDecode(jsonStr);
      return parsed is Map<String, dynamic> ? parsed : null;
    } catch (e) {
      print('Error parsing JSON string: $e');
      return null;
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    try {
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) return DateTime.parse(dateValue);
      return DateTime.now();
    } catch (e) {
      print('Error parsing date: $e');
      return DateTime.now();
    }
  }

  static List<NotificationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for specific notification types
  String? get orderId => data?['order_id'];
  String? get orderNumber => data?['order_number'];
  String? get articleId => data?['article_id'];
  String? get promoId => data?['promo_id'];
  String? get promoCode => data?['code'];

  // Get notification priority (for sorting)
  int get priority {
    switch (type) {
      case 'order':
        return isRead ? 2 : 1; // Highest priority for unread orders
      case 'promo':
        return isRead ? 4 : 3;
      case 'article':
        return isRead ? 6 : 5;
      case 'system':
        return isRead ? 8 : 7; // Lowest priority
      default:
        return 9;
    }
  }

  // Get relative time display
  String getTimeDisplay() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${(difference.inDays / 7).floor()} minggu yang lalu';
    }
  }

  // Copy with method for updating properties
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}