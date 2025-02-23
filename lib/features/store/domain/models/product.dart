import 'package:flutter/foundation.dart';

@immutable
class ProductVariant {
  final int id;
  final String value;
  final String sku;
  final int quantity;
  final String imageUrl;
  final Product product;
  final double price;
  final double? discountPrice;
  final bool isFavourite;
  final double? rating;

  const ProductVariant({
    required this.id,
    required this.value,
    required this.sku,
    required this.quantity,
    required this.imageUrl,
    required this.product,
    required this.price,
    this.discountPrice,
    required this.isFavourite,
    this.rating,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      value: json['value'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
      imageUrl: json['image_url'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] == null
          ? null
          : (json['discount_price'] as num).toDouble(),
      isFavourite: json['is_favourite'] as bool,
      rating:
          json['rating'] == null ? null : (json['rating'] as num).toDouble(),
    );
  }
}

class Product {
  final int id;
  final Map<String, String> title;
  final Map<String, String> description;
  final List<FilterData> filterData;
  final String article;
  final String alias;
  final Category category;
  final String imageUrl;
  final bool isColorable;
  final bool isActive;
  final List<double> priceRange;
  final bool isFavourite;
  final double expense;
  final double? rating;
  final ProductGroup? group;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.filterData,
    required this.article,
    required this.alias,
    required this.category,
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
      title: Map<String, String>.from(json['title']),
      description: Map<String, String>.from(json['description']),
      filterData: (json['filter_data'] as List<dynamic>)
          .map((data) => FilterData.fromJson(data as Map<String, dynamic>))
          .toList(),
      article: json['article'] as String,
      alias: json['alias'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      imageUrl: json['image_url'] as String,
      isColorable: json['is_colorable'] as bool,
      isActive: json['is_active'] as bool,
      priceRange: (json['price_range'] as List<dynamic>)
          .map((price) => (price as num).toDouble())
          .toList(),
      isFavourite: json['is_favourite'] as bool,
      expense: (json['expense'] as num).toDouble(),
      rating:
          json['rating'] == null ? null : (json['rating'] as num).toDouble(),
      group: json['group'] == null
          ? null
          : ProductGroup.fromJson(json['group'] as Map<String, dynamic>),
    );
  }
}

class FilterData {
  final int id;
  final int valueId;
  final Map<String, String> title;
  final Map<String, String?> measure;
  final Map<String, String> value;

  const FilterData({
    required this.id,
    required this.valueId,
    required this.title,
    required this.measure,
    required this.value,
  });

  factory FilterData.fromJson(Map<String, dynamic> json) {
    return FilterData(
      id: json['id'] as int,
      valueId: json['value_id'] as int,
      title: Map<String, String>.from(json['title']),
      measure: Map<String, String?>.from(json['measure']),
      value: Map<String, String>.from(json['value']),
    );
  }
}

class Category {
  final int id;
  final Map<String, String> title;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      title: Map<String, String>.from(json['title']),
      imageUrl: json['image_url'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ProductGroup {
  final int id;
  final String name;

  const ProductGroup({
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
