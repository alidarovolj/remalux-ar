import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:chucker_flutter/chucker_flutter.dart';

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
      validateStatus: (status) {
        return status != null && status < 500; // Принимаем все статусы < 500
      },
    ));

    // Add interceptors
    _addInterceptors();
  }

  void _addInterceptors() {
    // Interceptor for logging requests, responses, and errors with dividers
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logDivider();
          print("➡️ Запрос");
          print("Метод: ${options.method}");
          print("URL: ${options.uri}");
          if (options.headers.isNotEmpty) {
            print("Заголовки: ${options.headers}");
          }
          if (options.data != null) {
            print("Данные: ${options.data}");
          }
          _logDivider();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logDivider();
          print("✅ Ответ");
          print("Статус: ${response.statusCode}");
          print("Данные: ${response.data}");
          _logDivider();
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          _logDivider();
          print("❌ Ошибка");
          print("Статус: ${e.response?.statusCode ?? 'Нет ответа'}");
          print("Сообщение: ${e.message}");
          if (e.response?.data != null) {
            print("Данные ошибки: ${e.response?.data}");
          }
          _logDivider();
          return handler.next(e);
        },
      ),
    );

    // LogInterceptor for detailed logs
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (log) => print(log), // Redirect logs to console
      ),
    );

    // Interceptor to generate cURL commands
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final curlCommand = _generateCurlCommand(options);
          print('cURL: $curlCommand');
          return handler.next(options); // Proceed with the request
        },
      ),
    );
  }

  // Helper to generate a cURL command for a request
  String _generateCurlCommand(RequestOptions options) {
    final headers = options.headers.entries
        .map((e) => "-H '${e.key}: ${e.value}'")
        .join(' ');
    final data = options.data != null ? "--data '${options.data}'" : '';
    return "curl -X ${options.method} '${options.uri}' $headers $data";
  }

  void _logDivider() {
    print("------------------------------------");
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

      // Проверяем статус ответа
      if (response.statusCode == 401) {
        print('❌ Unauthorized request: $endpoint');
        return null;
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      // Проверяем статус ответа
      if (response.statusCode == 401) {
        print('❌ Unauthorized request: $endpoint');
        return null;
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      return null;
    }
  }
}
