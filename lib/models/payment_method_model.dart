// lib/models/payment_method_model.dart

class PaymentMethodModel {
  final String id;
  final String name;
  final String type;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.type,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'logo_url': logoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    String? type,
    String? logoUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 