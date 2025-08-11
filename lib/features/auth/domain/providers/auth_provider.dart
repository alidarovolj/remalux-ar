import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:remalux_ar/features/auth/domain/models/auth_response.dart';
import 'package:remalux_ar/features/auth/domain/models/login_request.dart';
import 'package:remalux_ar/features/auth/domain/models/register_request.dart';
import 'package:remalux_ar/features/auth/domain/models/user.dart';
import 'package:remalux_ar/core/services/storage_service.dart';
import 'dart:convert';

class Auth {
  final ApiClient _apiClient;
  final Ref ref;

  Auth(this._apiClient, this.ref);

  Future<AuthResponse?> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: request.toJson(),
      );

      final authResponse =
          AuthResponse.fromJson(response.data as Map<String, dynamic>);

      // Save token in storage
      await StorageService.saveToken(authResponse.accessToken);

      // Update ApiClient headers with the new token
      _apiClient.setAccessToken(authResponse.accessToken);

      return authResponse;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return null;
      }

      // Ensure the token is set in headers
      _apiClient.setAccessToken(token);

      final response = await _apiClient.get('/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post(
        '/auth/registration',
        data: request.toJson(),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      String errorMessage = 'Registration failed';
      final responseData = response.data;

      if (responseData != null && responseData.isNotEmpty) {
        try {
          final jsonData = jsonDecode(responseData);
          if (jsonData is Map<String, dynamic>) {
            errorMessage = jsonData['message'] ?? errorMessage;
          }
        } catch (e) {
          errorMessage = responseData;
        }
      }

      throw Exception(errorMessage);
    } on DioException catch (e) {
      String errorMessage = 'Registration failed';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'No internet connection';
          break;
        case DioExceptionType.badResponse:
          final responseData = e.response?.data;
          if (responseData != null && responseData.isNotEmpty) {
            try {
              final jsonData = jsonDecode(responseData);
              if (jsonData is Map<String, dynamic>) {
                errorMessage = jsonData['message'] ?? errorMessage;
              } else {
                errorMessage = responseData;
              }
            } catch (e) {
              errorMessage = responseData;
            }
          }
          break;
        default:
          if (e.error != null) {
            errorMessage = 'Network error: ${e.message}';
          }
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<bool> checkEmailAvailability(String email) async {
    try {
      await _apiClient.get(
        '/auth/email-exists',
        queryParameters: {'email': email},
      );
      return true;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          return false;
        }
      }
      // В случае других ошибок считаем email недоступным
      return false;
    }
  }

  Future<bool> checkPhoneAvailability(String phone) async {
    try {
      await _apiClient.get(
        '/auth/phone-exists',
        queryParameters: {'phone_number': phone},
      );
      return true;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          return false;
        }
      }

      // В случае других ошибок считаем телефон недоступным
      return false;
    }
  }
}

final authProvider = Provider<Auth>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return Auth(apiClient, ref);
});
