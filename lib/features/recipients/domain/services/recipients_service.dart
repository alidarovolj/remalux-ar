import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/recipients/domain/models/recipient.dart';
import 'package:remalux_ar/core/services/storage_service.dart';
import 'package:dio/dio.dart';

class RecipientsService {
  final ApiClient _apiClient;
  final Ref _ref;

  RecipientsService(this._apiClient, this._ref);

  Future<List<Recipient>> getRecipients({bool forceRefresh = false}) async {
    print('🔄 Fetching recipients${forceRefresh ? ' (force refresh)' : ''}');
    final token = await StorageService.getToken();
    if (token == null) {
      print('⚠️ No token found, returning empty list');
      return [];
    }
    _apiClient.setAccessToken(token);

    try {
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

      print('✅ Successfully fetched recipients');
      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => Recipient.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting recipients: $e');
      rethrow;
    }
  }

  Future<void> addRecipient(String name, String phoneNumber) async {
    print('🔄 Adding new recipient: $name');
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token found, cannot add recipient');
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);

    try {
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
      print('✅ Successfully added new recipient');
    } catch (error) {
      print('❌ Error adding recipient: $error');
      rethrow;
    }
  }

  Future<void> deleteRecipient(int id) async {
    print('🔄 Deleting recipient with ID: $id');
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token found, cannot delete recipient');
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);

    try {
      await _apiClient.delete(
        '/users/recipients/$id',
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
      print('✅ Successfully deleted recipient');
    } catch (error) {
      print('❌ Error deleting recipient: $error');
      rethrow;
    }
  }
}

final recipientsServiceProvider = Provider<RecipientsService>((ref) {
  return RecipientsService(ref.read(apiClientProvider), ref);
});
