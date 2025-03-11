import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/recipients/domain/models/recipient.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';

class RecipientsService {
  final ApiClient _apiClient;
  final Ref _ref;

  RecipientsService(this._apiClient, this._ref);

  void _ensureToken() {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.token == null) {
      throw Exception('User is not authenticated');
    }
    _apiClient.setAccessToken(authState.token!);
  }

  Future<List<Recipient>> getRecipients() async {
    try {
      _ensureToken();
      final response = await _apiClient.get('/users/recipients');
      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => Recipient.fromJson(json)).toList();
    } catch (error) {
      print('Error getting recipients: $error');
      throw error;
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
      );
    } catch (error) {
      print('Error adding recipient: $error');
      throw error;
    }
  }

  Future<void> deleteRecipient(int id) async {
    try {
      _ensureToken();
      await _apiClient.delete('/users/recipients/$id');
    } catch (error) {
      print('Error deleting recipient: $error');
      throw error;
    }
  }
}

final recipientsServiceProvider = Provider<RecipientsService>((ref) {
  return RecipientsService(ref.read(apiClientProvider), ref);
});
