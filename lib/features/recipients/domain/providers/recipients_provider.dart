import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/recipients/domain/models/recipient.dart';
import 'package:remalux_ar/features/recipients/domain/services/recipients_service.dart';

final recipientsServiceProvider = Provider<RecipientsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RecipientsService(apiClient, ref);
});

class RecipientsNotifier extends StateNotifier<AsyncValue<List<Recipient>>> {
  final RecipientsService _service;

  RecipientsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadRecipients();
  }

  Future<void> loadRecipients() async {
    try {
      state = const AsyncValue.loading();
      final recipients = await _service.getRecipients();
      state = AsyncValue.data(recipients);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addRecipient(String name, String phoneNumber) async {
    try {
      await _service.addRecipient(name, phoneNumber);
      await loadRecipients();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteRecipient(int id) async {
    try {
      await _service.deleteRecipient(id);
      await loadRecipients();
    } catch (error) {
      rethrow;
    }
  }
}

final recipientsProvider =
    StateNotifierProvider<RecipientsNotifier, AsyncValue<List<Recipient>>>(
        (ref) {
  final service = ref.read(recipientsServiceProvider);
  return RecipientsNotifier(service);
});
