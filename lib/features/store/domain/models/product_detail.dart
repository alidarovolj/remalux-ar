import 'package:remalux_ar/features/store/domain/models/product.dart';

class ProductDetail {
  final int id;
  final Map<String, String> title;
  final Map<String, String> description;
  final Map<String, dynamic> filterData;
  final String article;
  final String alias;
  final String imageUrl;
  final bool isColorable;
  final bool isActive;
  final List<ProductVariant> productVariants;

  ProductDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.filterData,
    required this.article,
    required this.alias,
    required this.imageUrl,
    required this.isColorable,
    required this.isActive,
    required this.productVariants,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as int,
      title: Map<String, String>.from(json['title'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      filterData: json['filter_data'] as Map<String, dynamic>,
      article: json['article'] as String,
      alias: json['alias'] as String,
      imageUrl: json['image_url'] as String,
      isColorable: json['is_colorable'] as bool,
      isActive: json['is_active'] as bool,
      productVariants: (json['product_variants'] as List<dynamic>)
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filter_data': filterData,
      'article': article,
      'alias': alias,
      'image_url': imageUrl,
      'is_colorable': isColorable,
      'is_active': isActive,
      'product_variants': productVariants.map((v) => v.toJson()).toList(),
    };
  }
}
