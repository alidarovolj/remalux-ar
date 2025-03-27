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
    print('🔄 Building RecipientsNotifier');
    return _fetchRecipients();
  }

  Future<List<Recipient>> _fetchRecipients() async {
    print('🔄 Fetching recipients in notifier');
    final recipientsService = ref.read(recipientsServiceProvider);
    return await recipientsService.getRecipients(forceRefresh: true);
  }

  Future<void> refreshRecipients() async {
    print('🔄 Refreshing recipients in notifier');
    state = const AsyncValue.loading();
    try {
      final recipients = await _fetchRecipients();
      print('✅ Successfully refreshed recipients in notifier');
      state = AsyncValue.data(recipients);
    } catch (error, stackTrace) {
      print('❌ Error refreshing recipients in notifier: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteRecipient(int id) async {
    print('🔄 Deleting recipient in notifier: $id');
    try {
      final recipientsService = ref.read(recipientsServiceProvider);
      await recipientsService.deleteRecipient(id);
      print('✅ Successfully deleted recipient in notifier');
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchRecipients());
    } catch (e) {
      print('❌ Error deleting recipient in notifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addRecipient({
    required String name,
    required String phoneNumber,
  }) async {
    print('🔄 Adding new recipient in notifier: $name');
    try {
      final recipientsService = ref.read(recipientsServiceProvider);
      await recipientsService.addRecipient(name, phoneNumber);
      print('✅ Successfully added new recipient in notifier');
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchRecipients());
    } catch (e) {
      print('❌ Error adding recipient in notifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
