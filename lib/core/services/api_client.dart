import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/storage_service.dart';
import 'package:remalux_ar/core/config/app_config.dart';
import 'dart:convert';

class ApiClient {
  final Dio _dio;

  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? AppConfig.apiUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )) {
    // Add request interceptor for logging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAccessToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      // Convert the data to JSON string and then parse it back to ensure proper formatting
      final jsonString = data != null ? jsonEncode(data) : null;
      final jsonData = jsonString != null ? jsonDecode(jsonString) : null;

      final response = await _dio.post(
        path,
        data: jsonData,
        queryParameters: queryParameters,
        options: options ??
            Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
      );

      // Handle the special case where the response starts with "Array to string conversion"
      if (response.data is String &&
          response.data.toString().contains('Array to string conversion')) {
        final jsonStr = response.data
            .toString()
            .replaceFirst('Array to string conversion', '');
        try {
          final jsonData = jsonDecode(jsonStr);
          response.data = jsonData;
        } catch (e) {
          rethrow;
        }
      }

      if (response.statusCode == null || response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Request failed with status: ${response.statusCode}',
        );
      }

      return response;
    } on DioException catch (e) {
      // Try to handle the error response if it contains the special format
      if (e.response?.data is String &&
          e.response!.data.toString().contains('Array to string conversion')) {
        try {
          final jsonStr = e.response!.data
              .toString()
              .replaceFirst('Array to string conversion', '');
          final jsonData = jsonDecode(jsonStr);
          return Response(
            requestOptions: e.requestOptions,
            data: jsonData,
            statusCode: 200,
          );
        } catch (parseError) {
          rethrow;
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response?> checkEmailAvailability(String email) async {
    try {
      return await get('/auth/check-email', queryParameters: {'email': email});
    } catch (e) {
      return null;
    }
  }

  Future<Response?> checkPhoneAvailability(String phone) async {
    try {
      return await get('/auth/check-phone', queryParameters: {'phone': phone});
    } catch (e) {
      return null;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Provider that handles token initialization
final tokenInitializerProvider = FutureProvider<void>((ref) async {
  final token = await StorageService.getToken();
  if (token != null) {
    final apiClient = ref.read(apiClientProvider);
    apiClient.setAccessToken(token);
  }
});
