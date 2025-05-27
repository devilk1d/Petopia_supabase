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
    return PromoModel(
      id: json['id'],
      sellerId: json['seller_id'],
      adminId: json['admin_id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      discountType: json['discount_type'],
      discountValue: double.parse(json['discount_value'].toString()),
      minPurchase: double.parse(json['min_purchase'].toString()),
      maxDiscount: json['max_discount'] != null
          ? double.parse(json['max_discount'].toString())
          : null,
      usageLimit: json['usage_limit'],
      usedCount: json['used_count'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  double calculateDiscount(double totalAmount) {
    if (!isActive || totalAmount < minPurchase) return 0;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return 0;
    if (usageLimit != null && usedCount >= usageLimit!) return 0;

    double discount = 0;
    if (discountType == 'percentage') {
      discount = totalAmount * (discountValue / 100);
    } else {
      discount = discountValue;
    }

    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }

    return discount;
  }
}
