import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/products_repository.dart';
import 'package:remalux_ar/features/home/domain/models/product.dart';

final productsRepositoryProvider = Provider((ref) => ProductsRepository());

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductsRepository _repository;

  ProductsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts({bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final products =
          await _repository.getProducts(forceRefresh: forceRefresh);
      state = AsyncValue.data(products);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return ProductsNotifier(repository);
});

final forceRefreshProvider = StateProvider<bool>((ref) => false);
