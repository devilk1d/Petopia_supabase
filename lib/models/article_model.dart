class ArticleModel {
  final String id;
  final String adminId;
  final String categoryId;
  final String title;
  final String content;
  final String? imageUrl;
  final String? authorName;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? categoryName;

  ArticleModel({
    required this.id,
    required this.adminId,
    required this.categoryId,
    required this.title,
    required this.content,
    this.imageUrl,
    this.authorName,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'],
      adminId: json['admin_id'],
      categoryId: json['category_id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_url'],
      authorName: json['author_name'],
      isPublished: json['is_published'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      categoryName: json['category_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'category_id': categoryId,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'author_name': authorName,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ArticleModel copyWith({
    String? id,
    String? adminId,
    String? categoryId,
    String? title,
    String? content,
    String? imageUrl,
    String? authorName,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorName: authorName ?? this.authorName,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: this.categoryName,
    );
  }
}