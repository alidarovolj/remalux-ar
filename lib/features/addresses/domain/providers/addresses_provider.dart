import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/addresses/domain/services/addresses_service.dart';
import 'package:remalux_ar/features/addresses/domain/models/address.dart';

final addressesProvider =
    AsyncNotifierProvider<AddressesNotifier, List<Address>>(() {
  return AddressesNotifier();
});

class AddressesNotifier extends AsyncNotifier<List<Address>> {
  @override
  Future<List<Address>> build() async {
    return _fetchAddresses();
  }

  Future<List<Address>> _fetchAddresses() async {
    print('🔄 Fetching addresses in notifier');
    final addressesService = ref.read(addressesServiceProvider);
    return await addressesService.getAddresses(forceRefresh: true);
  }

  Future<void> refreshAddresses() async {
    print('🔄 Refreshing addresses in notifier');
    state = const AsyncValue.loading();
    try {
      final addresses = await _fetchAddresses();
      print('✅ Successfully refreshed addresses in notifier');
      state = AsyncValue.data(addresses);
    } catch (error, stackTrace) {
      print('❌ Error refreshing addresses in notifier: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAddress(int id) async {
    print('🔄 Deleting address in notifier: $id');
    try {
      final addressesService = ref.read(addressesServiceProvider);
      await addressesService.deleteAddress(id);
      print('✅ Successfully deleted address in notifier');
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchAddresses());
    } catch (e) {
      print('❌ Error deleting address in notifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addAddress({
    required String address,
    required double latitude,
    required double longitude,
    String? entrance,
    String? floor,
    String? apartment,
  }) async {
    print('🔄 Adding new address in notifier: $address');
    try {
      final addressesService = ref.read(addressesServiceProvider);
      await addressesService.addAddress(
        address: address,
        latitude: latitude,
        longitude: longitude,
        entrance: entrance,
        floor: floor,
        apartment: apartment,
      );
      print('✅ Successfully added new address in notifier');
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchAddresses());
    } catch (e) {
      print('❌ Error adding address in notifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
