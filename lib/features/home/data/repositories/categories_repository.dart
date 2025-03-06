import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/domain/models/category.dart';

class CategoriesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Category>> getCategories() async {
    try {
      final response =
          await _apiClient.get('/categories/all', queryParameters: {
        'page': '1',
        'perPage': '10',
      });

      if (response == null) {
        throw Exception('API response is null');
      }

      final List<dynamic> data = response['data'];

      final categories = data.map((json) {
        return Category.fromJson(json as Map<String, dynamic>);
      }).toList();

      return categories;
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
