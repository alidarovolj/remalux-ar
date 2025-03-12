import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/contacts/data/models/contact_model.dart';
import 'package:remalux_ar/features/contacts/domain/services/contacts_service.dart';

final contactsProvider = AsyncNotifierProvider<ContactsNotifier, List<Contact>>(
  () => ContactsNotifier(),
);

class ContactsNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() async {
    return _fetchContacts();
  }

  Future<List<Contact>> _fetchContacts() async {
    final contactsService = ref.read(contactsServiceProvider);
    return await contactsService.getContacts(forceRefresh: true);
  }

  Future<void> refreshContacts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchContacts());
  }
}
