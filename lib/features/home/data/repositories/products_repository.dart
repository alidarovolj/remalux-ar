import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/domain/models/product.dart';

class ProductsRepository {
  final ApiClient _apiClient;

  ProductsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<Product>> getProducts({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _apiClient.get(
      '/products/paginated?page=$page&perPage=$perPage',
    );

    final List<dynamic> data = response['data'];
    return data.map((item) => Product.fromJson(item)).toList();
  }
}
