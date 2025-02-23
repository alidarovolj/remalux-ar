import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';

class ProductsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ProductVariant>> getProducts({
    int page = 1,
    int perPage = 10,
    List<int>? filterIds,
    String? searchQuery,
  }) async {
    try {
      final queryParameters = {
        'page': page.toString(),
        'perPage': perPage.toString(),
      };

      if (filterIds != null && filterIds.isNotEmpty) {
        queryParameters['filters'] = filterIds.join(',');
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParameters['search'] = searchQuery;
      }

      final response = await _apiClient.get(
        '/product-variants',
        queryParameters: queryParameters,
      );

      if (response == null) {
        throw Exception('API response is null');
      }

      final data = response['data'] as List<dynamic>;

      final products = data.map((json) {
        return ProductVariant.fromJson(json);
      }).toList();

      return products;
    } catch (e, stackTrace) {
      throw Exception('Failed to load products: $e');
    }
  }
}
