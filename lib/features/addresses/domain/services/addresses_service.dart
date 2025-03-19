import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'package:remalux_ar/features/addresses/domain/models/address.dart';

final addressesServiceProvider = Provider<AddressesService>((ref) {
  final dio = ApiClient().dio;
  return AddressesService(dio: dio, ref: ref);
});

class AddressesService {
  final Dio dio;
  final Ref ref;

  AddressesService({required this.dio, required this.ref});

  Future<void> _ensureToken() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.token == null) {
      throw Exception('Unauthorized');
    }
    dio.options.headers['Authorization'] = 'Bearer ${authState.token}';
  }

  Future<List<Address>> getAddresses({bool forceRefresh = false}) async {
    await _ensureToken();

    try {
      final response = await dio.get(
        '/users/addresses/list',
        options: Options(
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Address.fromJson(json)).toList();
      }
      throw Exception('Failed to load addresses');
    } catch (e) {
      print('Error getting addresses: $e');
      rethrow;
    }
  }

  Future<Address> addAddress({
    required String address,
    required double latitude,
    required double longitude,
    String? entrance,
    String? floor,
    String? apartment,
  }) async {
    await _ensureToken();

    try {
      final response = await dio.post(
        '/users/addresses',
        data: {
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'entrance': entrance,
          'floor': floor,
          'apartment': apartment,
        },
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
      return Address.fromJson(response.data['data']);
    } catch (e) {
      print('Error adding address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(int id) async {
    await _ensureToken();

    try {
      await dio.delete(
        '/users/addresses/$id',
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
          },
        ),
      );
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }
}
