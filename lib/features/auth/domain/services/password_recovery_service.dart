import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:dio/dio.dart';

class PasswordRecoveryService {
  final ApiClient _apiClient;

  PasswordRecoveryService(this._apiClient);

  Future<void> requestCode(String phoneNumber) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-recovery/request-code',
        data: {'phone_number': phoneNumber},
      );

      if (response.statusCode == 422) {
        final errors = response.data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          throw Exception(
              firstError is List ? firstError.first : firstError.toString());
        }
        throw Exception(response.data['message'] ?? 'Validation failed');
      }

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to send code');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> verifyCode(String phoneNumber, String code) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-recovery/verify-code',
        data: {
          'phone_number': phoneNumber,
          'code': code,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Invalid code');
      }

      return response.data['access_token'] ?? '';
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> resetPassword(
    String accessToken,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/auth/password-recovery/update-password',
        data: {
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to reset password');
      }

      return response.data['message'] as String? ??
          'Password successfully updated';
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final passwordRecoveryServiceProvider =
    Provider<PasswordRecoveryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PasswordRecoveryService(apiClient);
});
