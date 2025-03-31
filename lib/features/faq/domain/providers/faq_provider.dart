import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/faq/domain/models/faq.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

final questionsProvider =
    StateNotifierProvider<QuestionsNotifier, AsyncValue<List<Faq>>>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: dotenv.env['BASE_URL'] ?? 'https://api.remalux.kz',
  ));
  return QuestionsNotifier(ApiClient());
});

class QuestionsNotifier extends StateNotifier<AsyncValue<List<Faq>>> {
  final ApiClient _apiClient;

  QuestionsNotifier(this._apiClient) : super(const AsyncValue.data([]));

  Future<void> _ensureToken() async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('User is not authenticated');
    }
    _apiClient.setAccessToken(token);
  }

  Future<void> submitQuestion(String question) async {
    try {
      state = const AsyncValue.loading();
      await _ensureToken();

      await _apiClient.post(
        '/questions',
        data: {
          'question': question,
        },
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
