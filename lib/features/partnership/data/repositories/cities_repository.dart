import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/partnership/domain/models/city.dart';

class CitiesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<City>> getCities() async {
    try {
      final response = await _apiClient.dio.get('/cities');

      if (response.data == null) {
        throw Exception('API response is null');
      }

      final List<dynamic> data = response.data;
      return data
          .map((json) => City.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load cities: $e');
    }
  }
}
