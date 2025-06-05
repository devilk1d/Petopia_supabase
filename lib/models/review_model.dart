import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String productId;
  final String? orderId;
  final double rating;
  final String? comment; // This maps to review_text from database
  final List<String>? images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userFullName;
  final String? userAvatar;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    this.orderId,
    required this.rating,
    this.comment,
    this.images,
    required this.createdAt,
    this.updatedAt,
    this.userFullName,
    this.userAvatar,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      orderId: json['order_item_id'], // Note: using order_item_id as orderId
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['review_text'], // Map review_text to comment field
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      userFullName: json['users']?['full_name'],
      userAvatar: json['users']?['profile_image_url'], // Updated field name
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'order_item_id': orderId, // Use order_item_id for database
      'rating': rating,
      'review_text': comment, // Map comment back to review_text
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static List<ReviewModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => ReviewModel.fromJson(json)).toList();
  }
}