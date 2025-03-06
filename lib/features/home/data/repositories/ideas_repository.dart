import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/domain/models/idea.dart';

class IdeasRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Idea>> getIdeas() async {
    try {
      final response = await _apiClient.get('/ideas');

      if (response == null) {
        throw Exception('API response is null');
      }

      final data = response['data'] as List<dynamic>;

      final ideas = data.map((json) {
        return Idea.fromJson(json);
      }).toList();

      return ideas;
    } catch (e) {
      throw Exception('Failed to load ideas: $e');
    }
  }
}
