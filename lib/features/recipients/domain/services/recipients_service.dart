import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/recipients/domain/models/recipient.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'package:dio/dio.dart';

class RecipientsService {
  final ApiClient _apiClient;
  final Ref _ref;

  RecipientsService(this._apiClient, this._ref);

  void _ensureToken() {
    final authState = _ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.token == null) {
      throw Exception('User is not authenticated');
    }
    _apiClient.setAccessToken(authState.token!);
  }

  Future<List<Recipient>> getRecipients({bool forceRefresh = false}) async {
    try {
      _ensureToken();
      final response = await _apiClient.get(
        '/users/recipients',
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );

      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => Recipient.fromJson(json)).toList();
    } catch (e) {
      print('Error getting recipients: $e');
      rethrow;
    }
  }

  Future<void> addRecipient(String name, String phoneNumber) async {
    try {
      _ensureToken();
      await _apiClient.post(
        '/users/recipients',
        data: {
          'name': name,
          'phone_number': phoneNumber,
        },
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
    } catch (error) {
      print('Error adding recipient: $error');
      rethrow;
    }
  }

  Future<void> deleteRecipient(int id) async {
    try {
      _ensureToken();
      await _apiClient.delete(
        '/users/recipients/$id',
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
    } catch (error) {
      print('Error deleting recipient: $error');
      rethrow;
    }
  }
}

final recipientsServiceProvider = Provider<RecipientsService>((ref) {
  return RecipientsService(ref.read(apiClientProvider), ref);
});
