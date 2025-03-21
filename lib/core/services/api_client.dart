import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;
  String? _accessToken;

  ApiClient(this._dio);

  void setAccessToken(String token) {
    _accessToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
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
      print('Error checking email availability: $e');
      return null;
    }
  }

  Future<Response?> checkPhoneAvailability(String phone) async {
    try {
      return await get('/auth/check-phone', queryParameters: {'phone': phone});
    } catch (e) {
      print('Error checking phone availability: $e');
      return null;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.remalux.kz/api',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  return ApiClient(dio);
});
