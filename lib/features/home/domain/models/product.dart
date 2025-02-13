class Product {
  final int id;
  final Map<String, String> title;
  final Map<String, String> description;
  final String article;
  final String alias;
  final String imageUrl;
  final bool isColorable;
  final bool isActive;
  final List<int> priceRange;
  final bool isFavourite;
  final double expense;
  final double? rating;
  final ProductGroup? group;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.article,
    required this.alias,
    required this.imageUrl,
    required this.isColorable,
    required this.isActive,
    required this.priceRange,
    required this.isFavourite,
    required this.expense,
    this.rating,
    this.group,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: Map<String, String>.from(json['title'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      article: json['article'] as String,
      alias: json['alias'] as String,
      imageUrl: json['image_url'] as String,
      isColorable: json['is_colorable'] as bool,
      isActive: json['is_active'] as bool,
      priceRange: List<int>.from(json['price_range'] as List),
      isFavourite: json['is_favourite'] as bool,
      expense: (json['expense'] as num).toDouble(),
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      group:
          json['group'] != null ? ProductGroup.fromJson(json['group']) : null,
    );
  }
}

class ProductGroup {
  final int id;
  final String name;

  ProductGroup({
    required this.id,
    required this.name,
  });

  factory ProductGroup.fromJson(Map<String, dynamic> json) {
    return ProductGroup(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
