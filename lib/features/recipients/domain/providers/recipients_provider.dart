import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/recipients/domain/models/recipient.dart';
import 'package:remalux_ar/features/recipients/domain/services/recipients_service.dart';

final recipientsServiceProvider = Provider<RecipientsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RecipientsService(apiClient, ref);
});

final recipientsProvider =
    AsyncNotifierProvider<RecipientsNotifier, List<Recipient>>(() {
  return RecipientsNotifier();
});

class RecipientsNotifier extends AsyncNotifier<List<Recipient>> {
  @override
  Future<List<Recipient>> build() async {
    return _fetchRecipients();
  }

  Future<List<Recipient>> _fetchRecipients() async {
    final recipientsService = ref.read(recipientsServiceProvider);
    return await recipientsService.getRecipients(forceRefresh: true);
  }

  Future<void> refreshRecipients() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchRecipients());
  }

  Future<void> deleteRecipient(int id) async {
    try {
      final recipientsService = ref.read(recipientsServiceProvider);
      await recipientsService.deleteRecipient(id);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchRecipients());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addRecipient({
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final recipientsService = ref.read(recipientsServiceProvider);
      await recipientsService.addRecipient(name, phoneNumber);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchRecipients());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
