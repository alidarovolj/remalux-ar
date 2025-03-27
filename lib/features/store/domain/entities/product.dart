import 'package:remalux_ar/features/store/domain/entities/product_detail.dart';

class Product {
  final int id;
  final Map<String, String> title;
  final String article;
  final bool isColorable;
  final List<ProductVariant> productVariants;
  final String? rating;
  final String? coverage;
  final String? coating;
  final String? consumptionRate;
  final String? dryingTime;
  final String? workingTemperature;
  final String? surfaceType;
  final String? applicationArea;
  final String imageUrl;

  Product({
    required this.id,
    required this.title,
    required this.article,
    required this.isColorable,
    required this.productVariants,
    this.rating,
    this.coverage,
    this.coating,
    this.consumptionRate,
    this.dryingTime,
    this.workingTemperature,
    this.surfaceType,
    this.applicationArea,
    required this.imageUrl,
  });

  factory Product.fromProductDetail(ProductDetail detail) {
    return Product(
      id: detail.id,
      title: detail.title,
      article: detail.article,
      isColorable: detail.isColorable,
      productVariants: detail.productVariants,
      rating: detail.rating,
      coverage: detail.coverage,
      coating: detail.coating,
      consumptionRate: detail.consumptionRate,
      dryingTime: detail.dryingTime,
      workingTemperature: detail.workingTemperature,
      surfaceType: detail.surfaceType,
      applicationArea: detail.applicationArea,
      imageUrl: detail.imageUrl,
    );
  }
}

class ProductVariant {
  final int id;
  final double price;
  final double weight;

  ProductVariant({
    required this.id,
    required this.price,
    required this.weight,
  });
}
