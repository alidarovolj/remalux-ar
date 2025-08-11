import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

class ApiClient {
  // Singleton pattern to ensure a single instance of Dio
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _accessToken;

  ApiClient._internal() {
    // Get the base URL from the environment file or use a default value
    final String baseUrl =
        dotenv.env['BASE_URL'] ?? 'https://api.remalux.kz/api';

    // Configure Dio instance
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30), // Increased from 10 to 30
      receiveTimeout: const Duration(seconds: 30), // Increased from 10 to 30
      sendTimeout: const Duration(seconds: 30), // Added send timeout
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

    // Initialize token from storage
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    final token = await StorageService.getToken();
    if (token != null) {
      setAccessToken(token);
    }
  }

  void setAccessToken(String token) {
    _accessToken = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAccessToken() {
    _accessToken = null;
    dio.options.headers.remove('Authorization');
  }

  String? get accessToken => _accessToken;

  void _addInterceptors() {
    // Add Chucker interceptor for network inspection
    dio.interceptors.add(ChuckerDioInterceptor());

    // Interceptor for logging requests, responses, and errors with dividers
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );

    // LogInterceptor for detailed logs
    dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestBody: false,
        requestHeader: false,
        responseBody: false,
        responseHeader: false,
        error: false,
      ),
    );

    // Interceptor to generate cURL commands
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options); // Proceed with the request
        },
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      // Remove auth header if no token
      if (_accessToken == null) {
        dio.options.headers.remove('Authorization');
      }

      final response = await dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      // Handle unauthorized response
      if (response.statusCode == 401) {
        removeAccessToken();
        return {
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'total': 0,
            'per_page': 10,
          }
        };
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Handle unauthorized error
      if (e.response?.statusCode == 401) {
        removeAccessToken();
      }

      return {
        'data': [],
        'meta': {
          'current_page': 1,
          'last_page': 1,
          'total': 0,
          'per_page': 10,
        }
      };
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      // Remove auth header if no token
      if (_accessToken == null) {
        dio.options.headers.remove('Authorization');
      }

      final response = await dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      // Handle unauthorized response
      if (response.statusCode == 401) {
        removeAccessToken();
        return {
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'total': 0,
            'per_page': 10,
          }
        };
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Handle unauthorized error
      if (e.response?.statusCode == 401) {
        removeAccessToken();
      }

      return {
        'data': [],
        'meta': {
          'current_page': 1,
          'last_page': 1,
          'total': 0,
          'per_page': 10,
        }
      };
    }
  }
}
