class Category {
  final String categoryId;
  final String categoryName;
  final int parentId;

  Category({required this.categoryId, required this.categoryName, required this.parentId});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['category_id'] ?? '0',
      categoryName: json['category_name'] ?? 'Bilinmeyen Kategori',
      parentId: json['parent_id'] ?? 0,
    );
  }
}