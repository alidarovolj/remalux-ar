import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';

class ProductStorageService {
  static const String _compareProductsKey = 'compare_products';
  final SharedPreferences _prefs;

  ProductStorageService(this._prefs);

  Future<void> saveCompareProducts(List<ProductDetail> products) async {
    final productsJson =
        products.map((product) => jsonEncode(product.toJson())).toList();
    await _prefs.setStringList(_compareProductsKey, productsJson);
  }

  List<ProductDetail> getCompareProducts() {
    final productsJson = _prefs.getStringList(_compareProductsKey) ?? [];
    return productsJson
        .map((json) => ProductDetail.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> clearCompareProducts() async {
    await _prefs.remove(_compareProductsKey);
  }
}
