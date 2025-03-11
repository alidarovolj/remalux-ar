import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/domain/models/product.dart';

class ProductsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    try {
      final response = await _apiClient.get(
        '/products/paginated',
        queryParameters: {
          'page': '1',
          'perPage': '10',
          if (forceRefresh)
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (response == null) {
        throw Exception('API response is null');
      }

      final List<dynamic> data = response['data'];
      return data
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
