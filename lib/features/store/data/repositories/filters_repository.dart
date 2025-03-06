import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/store/domain/models/filter.dart';

class FiltersRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Filter>> getFilters() async {
    try {
      final response = await _apiClient.get('/filters/all', queryParameters: {
        'page': '1',
        'perPage': '10',
      });

      if (response == null) {
        throw Exception('API response is null');
      }

      final data = response['data'] as List<dynamic>;

      final filters = data.map((json) {
        return Filter.fromJson(json);
      }).toList();

      return filters;
    } catch (e) {
      throw Exception('Failed to load filters: $e');
    }
  }
}
