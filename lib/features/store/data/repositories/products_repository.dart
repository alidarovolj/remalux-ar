import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';

class ProductsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ProductsResponse> getProducts({
    int page = 1,
    int perPage = 10,
    List<int>? filterIds,
    String? searchQuery,
    String? orderBy,
  }) async {
    try {
      final queryParameters = {
        'page': page.toString(),
        'perPage': perPage.toString(),
      };

      if (filterIds != null && filterIds.isNotEmpty) {
        for (final id in filterIds) {
          queryParameters['filter_ids[$id]'] = id.toString();
        }
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParameters['search'] = searchQuery;
      }

      if (orderBy != null) {
        queryParameters['order_by'] = orderBy;
      }

      final response = await _apiClient.get(
        '/product-variants',
        queryParameters: queryParameters,
      );

      if (response == null) {
        print('API Response is null');
        return ProductsResponse(data: [], meta: Meta(total: 0));
      }

      print('API Response meta: ${response['meta']}');
      print('Total products from API: ${response['meta']['total']}');

      final List<dynamic> data = response['data'];
      final List<ProductVariant> variants = [];

      for (var item in data) {
        try {
          print('Raw variant data: $item');
          print('Raw variant attributes: ${item['attributes']}');

          if (item['attributes'] == null) {
            item['attributes'] = {};
          }

          if (item['product'] != null) {
            item['attributes']['product'] = item['product'];
          }

          final variant = ProductVariant.fromJson(item);
          print('Parsed variant attributes: ${variant.attributes}');
          variants.add(variant);
        } catch (e) {
          print('Error parsing variant: $e');
          continue;
        }
      }

      final meta = Meta(total: response['meta']['total'] ?? 0);
      return ProductsResponse(data: variants, meta: meta);
    } catch (e, stackTrace) {
      print('Error fetching products: $e');
      print('Stack trace: $stackTrace');
      return ProductsResponse(data: [], meta: Meta(total: 0));
    }
  }
}
