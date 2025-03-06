import 'package:remalux_ar/features/store/domain/models/product.dart';

class ProductDetail {
  final int id;
  final Map<String, String> title;
  final Map<String, String> description;
  final List<Map<String, dynamic>> filterData;
  final String article;
  final String alias;
  final String imageUrl;
  final bool isColorable;
  final bool isActive;
  final List<ProductVariant> productVariants;
  final double expense;

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
    required this.expense,
  });

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
        imageUrl: json['image_url'] as String? ?? '',
        isColorable: json['is_colorable'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? false,
        productVariants: (json['product_variants'] as List<dynamic>?)
                ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        expense: expense,
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
      'image_url': imageUrl,
      'is_colorable': isColorable,
      'is_active': isActive,
      'product_variants': productVariants.map((v) => v.toJson()).toList(),
      'expense': expense,
    };
  }

  @override
  String toString() {
    return 'ProductDetail{id: $id, title: $title, description: $description, article: $article}';
  }
}
