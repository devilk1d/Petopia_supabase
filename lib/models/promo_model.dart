  class PromoModel {
  final String id;
  final String? sellerId;
  final String? adminId;
  final String code;
  final String title;
  final String? description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double minPurchase;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  PromoModel({
    required this.id,
    this.sellerId,
    this.adminId,
    required this.code,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minPurchase = 0,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to parse date safely
      DateTime parseDate(dynamic dateStr) {
        if (dateStr == null) return DateTime.now();
        if (dateStr is DateTime) return dateStr;
        
        try {
          // Try parsing ISO format first
          return DateTime.parse(dateStr.toString());
        } catch (e) {
          try {
            // Try parsing timestamp
            return DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr.toString()));
          } catch (e) {
            print('Error parsing date: $dateStr');
            return DateTime.now();
          }
        }
      }

      return PromoModel(
        id: json['id'].toString(),
        sellerId: json['seller_id']?.toString(),
        adminId: json['admin_id']?.toString(),
        code: json['code'].toString(),
        title: json['title'].toString(),
        description: json['description']?.toString(),
        discountType: json['discount_type'].toString(),
        discountValue: double.parse(json['discount_value'].toString()),
        minPurchase: double.parse(json['min_purchase']?.toString() ?? '0'),
        maxDiscount: json['max_discount'] != null ? double.parse(json['max_discount'].toString()) : null,
        usageLimit: json['usage_limit'] != null ? int.parse(json['usage_limit'].toString()) : null,
        usedCount: json['used_count'] != null ? int.parse(json['used_count'].toString()) : 0,
        startDate: parseDate(json['start_date']),
        endDate: json['end_date'] != null ? parseDate(json['end_date']) : null,
        isActive: json['is_active'] ?? true,
        createdAt: parseDate(json['created_at']),
      );
    } catch (e) {
      print('Error creating PromoModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  double calculateDiscount(double totalAmount) {
    try {
      if (!isActive) {
        print('Promo is not active');
        return 0;
      }

      final now = DateTime.now();
      if (now.isBefore(startDate)) {
        print('Promo has not started yet. Start date: $startDate');
        return 0;
      }

      if (endDate != null && now.isAfter(endDate!)) {
        print('Promo has expired. End date: $endDate');
        return 0;
      }

      if (totalAmount < minPurchase) {
        print('Total amount does not meet minimum purchase requirement. Required: $minPurchase, Current: $totalAmount');
        return 0;
      }

      if (usageLimit != null && usedCount >= usageLimit!) {
        print('Promo usage limit reached. Limit: $usageLimit, Used: $usedCount');
        return 0;
      }

      double discount = 0;
      if (discountType == 'percentage') {
        discount = totalAmount * (discountValue / 100);
        if (maxDiscount != null && discount > maxDiscount!) {
          discount = maxDiscount!;
        }
      } else {
        discount = discountValue;
      }

      print('Calculated discount: $discount');
      return discount;
    } catch (e) {
      print('Error calculating discount: $e');
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'admin_id': adminId,
      'code': code,
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_purchase': minPurchase,
      'max_discount': maxDiscount,
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
