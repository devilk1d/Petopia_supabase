// lib/models/shipping_method_model.dart

class ShippingMethodModel {
  final String id;
  final String name;
  final String type;
  final String? logoUrl;
  final double baseCost;
  final bool isActive;
  final DateTime createdAt;

  ShippingMethodModel({
    required this.id,
    required this.name,
    required this.type,
    this.logoUrl,
    required this.baseCost,
    required this.isActive,
    required this.createdAt,
  });

  factory ShippingMethodModel.fromJson(Map<String, dynamic> json) {
    return ShippingMethodModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      logoUrl: json['logo_url'],
      baseCost: (json['base_cost'] as num).toDouble(),
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
      'base_cost': baseCost,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ShippingMethodModel copyWith({
    String? id,
    String? name,
    String? type,
    String? logoUrl,
    double? baseCost,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ShippingMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      logoUrl: logoUrl ?? this.logoUrl,
      baseCost: baseCost ?? this.baseCost,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 