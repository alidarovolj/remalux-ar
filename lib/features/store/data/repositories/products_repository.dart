import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';

class ProductsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ProductsResponse> getProducts({
    int page = 1,
    int perPage = 10,
    List<int>? filterIds,
    String? orderBy,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page.toString(),
        'perPage': perPage.toString(),
      };

      // Add filter IDs if present
      if (filterIds != null && filterIds.isNotEmpty) {
        for (final id in filterIds) {
          params['filter_ids[$id]'] = id.toString();
        }
      }

      // Add order by if present
      if (orderBy != null) {
        params['order_by'] = orderBy;
      }

      // Add any additional query parameters
      if (queryParameters != null) {
        params.addAll(queryParameters);
      }

      print('Final query parameters: $params'); // Debug print

      final response = await _apiClient.get(
        '/product-variants',
        queryParameters: params,
      );

      final List<dynamic> data = response['data'];
      final List<ProductVariant> variants = [];

      for (var item in data) {
        try {
          if (item['attributes'] == null) {
            item['attributes'] = {};
          }

          if (item['product'] != null) {
            item['attributes']['product'] = item['product'];
          }

          final variant = ProductVariant.fromJson(item);
          variants.add(variant);
        } catch (e) {
          print('Error: $e');
        }
      }

      final meta = Meta(total: response['meta']['total'] ?? 0);
      return ProductsResponse(data: variants, meta: meta);
    } catch (e) {
      return ProductsResponse(data: [], meta: Meta(total: 0));
    }
  }
}
