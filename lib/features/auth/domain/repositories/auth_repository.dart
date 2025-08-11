import 'package:dio/dio.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/auth/domain/models/auth_response.dart';
import 'package:remalux_ar/features/auth/domain/models/login_request.dart';
import 'package:remalux_ar/features/auth/domain/models/user.dart';

class AuthResult {
  final AuthResponse? data;
  final String? error;

  AuthResult({this.data, this.error});
  bool get isSuccess => data != null;
}

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<AuthResult> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      _apiClient.setAccessToken(authResponse.accessToken);
      return AuthResult(data: authResponse);
    } on DioException catch (e) {
      String errorMessage;
      if (e.response?.statusCode == 422) {
        errorMessage = 'Неверный логин или пароль';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage =
            'Превышено время ожидания. Проверьте подключение к интернету';
      } else {
        errorMessage = 'Произошла ошибка при входе. Попробуйте позже';
      }

      return AuthResult(error: errorMessage);
    } catch (e) {
      return AuthResult(error: 'Произошла неизвестная ошибка');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get(
        '/auth/me',
        queryParameters: {
          'page': 1,
          'perPage': 10,
        },
      );

      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
