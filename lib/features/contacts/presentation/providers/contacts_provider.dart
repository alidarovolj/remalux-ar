import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/network/dio_provider.dart';
import 'package:remalux_ar/features/contacts/data/models/contact_model.dart';
import 'package:remalux_ar/features/contacts/domain/services/contacts_service.dart';

final contactsProvider =
    StateNotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>((ref) {
  final dio = ref.watch(dioProvider);
  return ContactsNotifier(ContactsService(dio: dio));
});

class ContactsNotifier extends StateNotifier<AsyncValue<List<Contact>>> {
  final ContactsService _service;

  ContactsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> fetchContacts() async {
    state = const AsyncValue.loading();
    try {
      final contacts = await _service.getContacts();
      state = AsyncValue.data(contacts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
