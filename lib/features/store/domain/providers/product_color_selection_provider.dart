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

  ProductColorSelectionNotifier(this._prefs) : super(ProductColorSelection()) {
    print('ProductColorSelectionNotifier initialized with prefs: $_prefs');
  }

  Future<void> setProduct(ProductDetail product,
      {String? initialWeight}) async {
    print('\n\n=== SET PRODUCT DEBUG ===');
    print('Attempting to save product ID: ${product.id}');
    print('Product title: ${product.title}');
    print('Current SharedPreferences instance: $_prefs');

    final success = await _prefs.setInt('selected_product_id', product.id);
    print('Save success: $success');

    if (success) {
      print('Successfully saved product ID: ${product.id}');
    } else {
      print('Failed to save product ID: ${product.id}');
    }

    print('Setting state with product...');
    state = ProductColorSelection(
      productId: product.id,
      initialWeight: initialWeight,
      product: product,
    );
    print('State set successfully');
    print(
        'Current state: productId=${state.productId}, product=${state.product?.id}');

    // Verify the save
    final savedId = _prefs.getInt('selected_product_id');
    print('Verified saved product ID: $savedId');
    print('===========================\n\n');
  }

  Future<void> clear() async {
    print('Clearing product ID');
    print('Current SharedPreferences instance: $_prefs');

    final success = await _prefs.remove('selected_product_id');
    print('Clear success: $success');

    if (success) {
      print('Successfully cleared product ID');
    } else {
      print('Failed to clear product ID');
    }

    state = ProductColorSelection();
  }

  Future<bool> hasSelectedProduct() async {
    final hasProduct = _prefs.containsKey('selected_product_id');
    print('Checking for product ID: $hasProduct');
    print('Current SharedPreferences instance: $_prefs');
    return hasProduct;
  }

  Future<int?> getSelectedProductId() async {
    final productId = _prefs.getInt('selected_product_id');
    print('Retrieved product ID: $productId');
    print('Current SharedPreferences instance: $_prefs');
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
