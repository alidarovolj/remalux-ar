import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remalux_ar/core/providers/shared_preferences_provider.dart';

class ProductColorSelection {
  final int? productId;
  final String? initialWeight;
  final ProductDetail? product;

  ProductColorSelection({
    this.productId,
    this.initialWeight,
    this.product,
  });
}

class ProductColorSelectionNotifier
    extends StateNotifier<ProductColorSelection> {
  final SharedPreferences _prefs;

  ProductColorSelectionNotifier(this._prefs) : super(ProductColorSelection());

  Future<void> setProduct(ProductDetail product,
      {String? initialWeight}) async {
    final success = await _prefs.setInt('selected_product_id', product.id);

    if (success) {
    } else {}

    state = ProductColorSelection(
      productId: product.id,
      initialWeight: initialWeight,
      product: product,
    );
  }

  Future<void> clear() async {
    final success = await _prefs.remove('selected_product_id');

    if (success) {
    } else {}

    state = ProductColorSelection();
  }

  Future<bool> hasSelectedProduct() async {
    final hasProduct = _prefs.containsKey('selected_product_id');
    return hasProduct;
  }

  Future<int?> getSelectedProductId() async {
    final productId = _prefs.getInt('selected_product_id');
    return productId;
  }
}

final productColorSelectionProvider =
    StateNotifierProvider<ProductColorSelectionNotifier, ProductColorSelection>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ProductColorSelectionNotifier(prefs);
  },
);
