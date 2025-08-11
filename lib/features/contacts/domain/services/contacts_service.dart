import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/contacts/data/models/contact_model.dart';

final contactsServiceProvider = Provider<ContactsService>((ref) {
  final dio = ApiClient().dio;
  return ContactsService(dio: dio);
});

class ContactsService {
  final Dio dio;

  ContactsService({required this.dio});

  Future<List<Contact>> getContacts({bool forceRefresh = false}) async {
    try {
      final response = await dio.get(
        '/contacts',
        options: Options(
          headers: {
            'Cache-Control':
                forceRefresh ? 'no-cache, no-store, must-revalidate' : null,
            'Pragma': forceRefresh ? 'no-cache' : null,
            'Expires': forceRefresh ? '0' : null,
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) {
          try {
            return Contact.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            rethrow;
          }
        }).toList();
      }
      throw Exception('Failed to load contacts');
    } catch (e) {
      rethrow;
    }
  }
}
