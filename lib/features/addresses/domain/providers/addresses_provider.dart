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
    final addressesService = ref.read(addressesServiceProvider);
    return await addressesService.getAddresses(forceRefresh: true);
  }

  Future<void> refreshAddresses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAddresses());
  }

  Future<void> deleteAddress(int id) async {
    try {
      final addressesService = ref.read(addressesServiceProvider);
      await addressesService.deleteAddress(id);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchAddresses());
    } catch (e) {
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
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => _fetchAddresses());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
