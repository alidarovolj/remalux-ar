import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/domain/providers/product_storage_service.dart';

final productStorageServiceProvider = Provider<ProductStorageService>((ref) {
  throw UnimplementedError('Initialize this provider in your app');
});

class CompareProductsNotifier extends StateNotifier<List<ProductDetail>> {
  final ProductStorageService _storage;

  CompareProductsNotifier(this._storage) : super([]) {
    // Load initial state from storage
    state = _storage.getCompareProducts();
  }

  void addProduct(ProductDetail product) {
    if (state.length < 2 && !state.any((p) => p.id == product.id)) {
      state = [...state, product];
      _storage.saveCompareProducts(state);
    }
  }

  void removeProduct(ProductDetail product) {
    state = state.where((p) => p.id != product.id).toList();
    _storage.saveCompareProducts(state);
  }

  void clearProducts() {
    state = [];
    _storage.clearCompareProducts();
  }
}

final compareProductsProvider =
    StateNotifierProvider<CompareProductsNotifier, List<ProductDetail>>((ref) {
  final storage = ref.watch(productStorageServiceProvider);
  return CompareProductsNotifier(storage);
});
