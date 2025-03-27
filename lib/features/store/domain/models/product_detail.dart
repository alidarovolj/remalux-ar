import 'package:remalux_ar/features/store/domain/models/product.dart';

class ProductDetail {
  final int id;
  final Map<String, String> title;
  final Map<String, String> description;
  final List<Map<String, dynamic>> filterData;
  final String article;
  final String alias;
  final Map<String, dynamic> category;
  final String imageUrl;
  final bool isColorable;
  final bool isActive;
  final List<ProductVariant> productVariants;
  final double expense;
  final Map<String, dynamic>? rating;
  final String? coverage;
  final String? coating;
  final String? consumptionRate;
  final String? dryingTime;
  final String? workingTemperature;
  final String? surfaceType;
  final String? applicationArea;
  final List<String> certificates;
  final List<String> images;

  ProductDetail({
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
    required this.productVariants,
    required this.expense,
    required this.rating,
    required this.coverage,
    this.coating,
    this.consumptionRate,
    this.dryingTime,
    this.workingTemperature,
    this.surfaceType,
    this.applicationArea,
    required this.certificates,
    required this.images,
  });

  ProductDetail copyWith({
    int? id,
    Map<String, String>? title,
    Map<String, String>? description,
    List<Map<String, dynamic>>? filterData,
    String? article,
    String? alias,
    Map<String, dynamic>? category,
    String? imageUrl,
    bool? isColorable,
    bool? isActive,
    List<ProductVariant>? productVariants,
    double? expense,
    Map<String, dynamic>? rating,
    String? coverage,
    String? coating,
    String? consumptionRate,
    String? dryingTime,
    String? workingTemperature,
    String? surfaceType,
    String? applicationArea,
    List<String>? certificates,
    List<String>? images,
  }) {
    return ProductDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filterData: filterData ?? this.filterData,
      article: article ?? this.article,
      alias: alias ?? this.alias,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isColorable: isColorable ?? this.isColorable,
      isActive: isActive ?? this.isActive,
      productVariants: productVariants ?? this.productVariants,
      expense: expense ?? this.expense,
      rating: rating ?? this.rating,
      coverage: coverage ?? this.coverage,
      coating: coating ?? this.coating,
      consumptionRate: consumptionRate ?? this.consumptionRate,
      dryingTime: dryingTime ?? this.dryingTime,
      workingTemperature: workingTemperature ?? this.workingTemperature,
      surfaceType: surfaceType ?? this.surfaceType,
      applicationArea: applicationArea ?? this.applicationArea,
      certificates: certificates ?? this.certificates,
      images: images ?? this.images,
    );
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Starting to parse ProductDetail from JSON');
      print('📝 Input JSON: $json');

      // Parse each field individually with logging
      print('Parsing id...');
      final id = json['id'] as int;
      print('✓ id: $id');

      print('Parsing title...');
      final title = json['title'];
      print('Raw title: $title (${title.runtimeType})');
      final Map<String, String> parsedTitle =
          Map<String, String>.from(title ?? {});
      print('✓ title: $parsedTitle');

      print('Parsing description...');
      final description = json['description'];
      print('Raw description: $description (${description.runtimeType})');
      final Map<String, String> parsedDescription =
          Map<String, String>.from(description ?? {});
      print('✓ description: $parsedDescription');

      print('Parsing filterData...');
      final filterData = json['filter_data'];
      print('Raw filterData: $filterData (${filterData.runtimeType})');
      final List<Map<String, dynamic>> parsedFilterData =
          (filterData as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [];
      print('✓ filterData: $parsedFilterData');

      print('Parsing expense...');
      final expense = json['expense'] == null
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
                  : 150.0;
      print('✓ expense: $expense');

      final detail = ProductDetail(
        id: id,
        title: parsedTitle,
        description: parsedDescription,
        filterData: parsedFilterData,
        article: json['article'] as String? ?? '',
        alias: json['alias'] as String? ?? '',
        category: json['category'] as Map<String, dynamic>? ?? {},
        imageUrl: json['image_url'] as String? ?? '',
        isColorable: json['is_colorable'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? false,
        productVariants: (json['product_variants'] as List<dynamic>?)
                ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        expense: expense,
        rating: json['rating'] as Map<String, dynamic>?,
        coverage: json['coverage'] as String?,
        coating: json['coating'] as String?,
        consumptionRate: json['consumption_rate'] as String?,
        dryingTime: json['drying_time'] as String?,
        workingTemperature: json['working_temperature'] as String?,
        surfaceType: json['surface_type'] as String?,
        applicationArea: json['application_area'] as String?,
        certificates: (json['certificates'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

      print('✅ Successfully created ProductDetail object');
      return detail;
    } catch (e, stackTrace) {
      print('❌ Error parsing ProductDetail: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filter_data': filterData,
      'article': article,
      'alias': alias,
      'category': category,
      'image_url': imageUrl,
      'is_colorable': isColorable,
      'is_active': isActive,
      'product_variants': productVariants.map((v) => v.toJson()).toList(),
      'expense': expense,
      'rating': rating,
      'coverage': coverage,
      'coating': coating,
      'consumption_rate': consumptionRate,
      'drying_time': dryingTime,
      'working_temperature': workingTemperature,
      'surface_type': surfaceType,
      'application_area': applicationArea,
      'certificates': certificates,
      'images': images,
    };
  }

  @override
  String toString() {
    return 'ProductDetail{id: $id, title: $title, description: $description, article: $article}';
  }
}

class ProductVariant {
  final int id;
  final double price;
  final String value;
  final double? discount_price;

  ProductVariant({
    required this.id,
    required this.price,
    required this.value,
    this.discount_price,
  });

  ProductVariant copyWith({
    int? id,
    double? price,
    String? value,
    double? discount_price,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      price: price ?? this.price,
      value: value ?? this.value,
      discount_price: discount_price ?? this.discount_price,
    );
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Starting to parse ProductVariant from JSON');
      print('📝 Input JSON: $json');

      // Parse each field individually with logging
      print('Parsing id...');
      final id = json['id'] as int;
      print('✓ id: $id');

      print('Parsing price...');
      final price = json['price'] as num;
      print('✓ price: $price');

      print('Parsing value...');
      final value = json['value'] as String;
      print('✓ value: $value');

      print('Parsing discount_price...');
      final discount_price = json['discount_price'] as num?;
      print('✓ discount_price: $discount_price');

      final variant = ProductVariant(
        id: id,
        price: price.toDouble(),
        value: value,
        discount_price: discount_price?.toDouble(),
      );

      print('✅ Successfully created ProductVariant object');
      return variant;
    } catch (e, stackTrace) {
      print('❌ Error parsing ProductVariant: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'value': value,
      'discount_price': discount_price,
    };
  }

  double get weight => double.tryParse(value) ?? 0.0;
}
