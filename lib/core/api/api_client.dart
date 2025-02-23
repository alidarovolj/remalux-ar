import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  // Singleton pattern to ensure a single instance of Dio
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    // Get the base URL from the environment file or use a default value
    final String baseUrl =
        dotenv.env['BASE_URL'] ?? 'https://api.remalux.kz/api';

    // Configure Dio instance
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10), // Connection timeout
      receiveTimeout: const Duration(seconds: 10), // Response timeout
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _addInterceptors();
  }

  Future<Map<String, dynamic>?> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      return null;
    }
  }

  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('➡️ REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print(
              '❌ ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }
}
