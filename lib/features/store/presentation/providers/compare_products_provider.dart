import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';

class CompareProductsNotifier extends StateNotifier<List<ProductDetail>> {
  CompareProductsNotifier() : super([]);

  void addProduct(ProductDetail product) {
    if (state.length < 2) {
      state = [...state, product];
    } else {
      // Replace first product with new one
      state = [product, state[1]];
    }
  }

  void removeProduct(ProductDetail product) {
    state = state.where((p) => p.id != product.id).toList();
  }

  bool isProductInComparison(ProductDetail product) {
    return state.any((p) => p.id == product.id);
  }
}

final compareProductsProvider =
    StateNotifierProvider<CompareProductsNotifier, List<ProductDetail>>(
  (ref) => CompareProductsNotifier(),
);
