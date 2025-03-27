import 'package:remalux_ar/features/store/domain/entities/product.dart';

class ProductDetail {
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
  final Map<String, String> description;
  final List<String> certificates;
  final List<String> images;

  ProductDetail({
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
    required this.description,
    required this.certificates,
    required this.images,
  });
}
