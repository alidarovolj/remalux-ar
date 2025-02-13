import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/domain/models/category.dart';

class CategoriesRepository {
  final ApiClient _apiClient;

  CategoriesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<Category>> getCategories({int page = 1, int perPage = 10}) async {
    final response = await _apiClient.get(
      '/categories/all?page=$page&perPage=$perPage',
    );

    final List<dynamic> data = response['data'];
    return data.map((json) => Category.fromJson(json)).toList();
  }
}
