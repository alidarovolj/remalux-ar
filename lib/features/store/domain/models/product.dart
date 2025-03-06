import 'package:flutter/foundation.dart';

@immutable
class ProductVariant {
  final int id;
  final String value;
  final String sku;
  final double price;
  final double? discount_price;
  final String image_url;
  final bool is_favourite;
  final int quantity;
  final bool isAvailable;
  final Map<String, dynamic> attributes;
  final double? rating;
  final int reviewsCount;

  const ProductVariant({
    required this.id,
    required this.value,
    required this.sku,
    required this.price,
    this.discount_price,
    required this.image_url,
    required this.is_favourite,
    required this.quantity,
    required this.isAvailable,
    required this.attributes,
    this.rating,
    this.reviewsCount = 0,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    // Parse rating and reviews count
    double? rating;
    int reviewsCount = 0;

    if (json['rating'] != null) {
      if (json['rating'] is Map) {
        final ratingData = json['rating'] as Map<String, dynamic>;
        rating = double.tryParse(ratingData['rating']?.toString() ?? '0.0');
        reviewsCount = (ratingData['count'] as num?)?.toInt() ?? 0;
      } else if (json['rating'] is num) {
        rating = (json['rating'] as num).toDouble();
      } else if (json['rating'] is String) {
        rating = double.tryParse(json['rating']);
      }
    }

    // If rating is not found in variant, try to get it from product data
    if (rating == null && json['attributes']?['product']?['rating'] != null) {
      final productRating = json['attributes']['product']['rating'];
      if (productRating is Map) {
        rating = double.tryParse(productRating['rating']?.toString() ?? '0.0');
        reviewsCount = (productRating['count'] as num?)?.toInt() ?? 0;
      } else if (productRating is num) {
        rating = productRating.toDouble();
      } else if (productRating is String) {
        rating = double.tryParse(productRating);
      }
    }

    return ProductVariant(
      id: json['id'] as int,
      value: json['value']?.toString() ?? '',
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discount_price: (json['discount_price'] as num?)?.toDouble(),
      image_url: json['image_url'] as String? ?? '',
      is_favourite: json['is_favourite'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 0,
      isAvailable: json['quantity'] != null && json['quantity'] > 0,
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
      rating: rating,
      reviewsCount: reviewsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'sku': sku,
      'price': price,
      'discount_price': discount_price,
      'image_url': image_url,
      'is_favourite': is_favourite,
      'quantity': quantity,
      'is_available': isAvailable,
      'attributes': attributes,
      'rating': rating,
      'reviews_count': reviewsCount,
    };
  }
}

class PriceRange {
  final double from;
  final double to;

  PriceRange({
    required this.from,
    required this.to,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    return PriceRange(
      from: (json['from'] as num?)?.toDouble() ?? 0.0,
      to: (json['to'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
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
      filterData: (json['filter_data'] as List<dynamic>?)
              ?.map((data) => FilterData.fromJson(data as Map<String, dynamic>))
              .toList() ??
          [],
      article: json['article'] as String,
      alias: json['alias'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      imageUrl: json['image_url'] as String,
      isColorable: json['is_colorable'] as bool,
      isActive: json['is_active'] as bool,
      priceRange: (json['price_range'] as List<dynamic>)
          .map((price) => (price is num
              ? price.toDouble()
              : (double.tryParse(price.toString()) ?? 0.0)))
          .toList(),
      isFavourite: json['is_favourite'] as bool,
      expense: json['expense'] == null
          ? 150.0
          : json['expense'] is num
              ? (json['expense'] as num).toDouble()
              : json['expense'] is Map
                  ? ((json['expense'] as Map)['value'] == null
                      ? 150.0
                      : ((json['expense'] as Map)['value'] is num
                          ? ((json['expense'] as Map)['value'] as num)
                              .toDouble()
                          : (double.tryParse(((json['expense'] as Map)['value'])
                                  .toString()) ??
                              150.0)))
                  : 150.0,
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
