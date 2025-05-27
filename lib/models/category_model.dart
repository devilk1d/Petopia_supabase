class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;
  final String? color;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.color,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
      color: json['color'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }
}