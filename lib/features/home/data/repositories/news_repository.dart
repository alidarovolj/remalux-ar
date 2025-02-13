import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/domain/models/news.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<News>> getNews({int page = 1, int perPage = 10}) async {
    final response = await _apiClient.get(
      '/news?page=$page&perPage=$perPage',
    );

    final List<dynamic> data = response['data'];
    return data.map((json) => News.fromJson(json)).toList();
  }

  Future<News> getNewsDetail(int id) async {
    final response = await _apiClient.get('/news/$id');
    return News.fromJson(response);
  }
}
