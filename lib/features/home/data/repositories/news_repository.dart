import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/domain/models/news.dart';

class NewsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<News>> getNews() async {
    try {
      final response = await _apiClient.get('/news', queryParameters: {
        'page': '1',
        'perPage': '10',
      });

      final List<dynamic> data = response['data'];

      final news = data.map((json) {
        return News.fromJson(json as Map<String, dynamic>);
      }).toList();

      return news;
    } catch (e) {
      throw Exception('Failed to load news: $e');
    }
  }

  Future<News> getNewsDetail(int id) async {
    final response = await _apiClient.get('/news/$id');
    return News.fromJson(response);
  }
}
