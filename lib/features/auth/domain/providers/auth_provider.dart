import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/auth/domain/models/auth_response.dart';
import 'package:remalux_ar/features/auth/domain/models/login_request.dart';
import 'package:remalux_ar/features/auth/domain/models/user.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

class Auth {
  final ApiClient _apiClient;

  Auth(this._apiClient);

  Future<AuthResponse?> login(LoginRequest request) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: request.toJson(),
    );

    if (response == null) {
      print('❌ Login failed: No response data');
      return null;
    }

    final authResponse = AuthResponse.fromJson(response);

    // Save token in storage
    await StorageService.saveToken(authResponse.accessToken);

    // Update ApiClient headers with the new token
    _apiClient.dio.options.headers['Authorization'] =
        'Bearer ${authResponse.accessToken}';

    return authResponse;
  }

  Future<User?> getCurrentUser() async {
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ Get user failed: No token available');
      return null;
    }

    // Ensure the token is set in headers
    _apiClient.dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await _apiClient.get('/auth/me');

    if (response == null) {
      print('❌ Get user failed: No response data');
      return null;
    }

    return User.fromJson(response);
  }
}

final authProvider = Provider<Auth>((ref) {
  return Auth(ApiClient());
});
