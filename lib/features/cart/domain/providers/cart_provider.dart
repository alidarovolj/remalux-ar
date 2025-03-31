import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/cart/domain/models/cart_item.dart';
import 'package:dio/dio.dart';

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final ApiClient _apiClient;
  bool _mounted = true;

  CartNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    getCart();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _setState(AsyncValue<List<CartItem>> newState) {
    if (_mounted) {
      state = newState;
    }
  }

  Future<void> getCart() async {
    try {
      _setState(const AsyncValue.loading());
      final response = await _apiClient.get('/carts');

      if (!_mounted) return;

      final data = response.data['data'];
      final List<CartItem> items = data != null
          ? (data as List).map((item) => CartItem.fromJson(item)).toList()
          : [];
      _setState(AsyncValue.data(items));
    } catch (error, stackTrace) {
      if (!_mounted) return;

      if (error is DioException && error.response?.statusCode == 401) {
        _setState(AsyncValue.error(error, stackTrace));
        return;
      }

      _setState(AsyncValue.error(error, stackTrace));
    }
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    if (!_mounted) return;

    try {
      // Оптимистично обновляем UI
      state.whenData((items) {
        final updatedItems = items.map((item) {
          if (item.id == itemId) {
            return CartItem(
              id: item.id,
              productImage: item.productImage,
              productTitle: item.productTitle,
              productVariant: item.productVariant,
              price: item.price,
              quantity: quantity,
              colorId: item.colorId,
            );
          }
          return item;
        }).toList();
        _setState(AsyncValue.data(updatedItems ?? []));
      });

      // Отправляем запрос на сервер
      await _apiClient.put('/carts/$itemId', data: {'quantity': quantity});

      // В случае ошибки от сервера, getCart() вызовется в catch блоке
    } catch (error) {
      if (!_mounted) return;
      if (error is DioException && error.response?.statusCode == 401) {
        _setState(AsyncValue.error(error, StackTrace.current));
        return;
      }
      print('Error updating quantity: $error');
      // При ошибке обновляем данные с сервера
      await getCart();
    }
  }

  Future<void> removeItem(int itemId) async {
    if (!_mounted) return;

    try {
      await _apiClient.delete('/carts/$itemId');
      if (!_mounted) return;
      await getCart(); // Refresh cart after removal
    } catch (error) {
      if (!_mounted) return;
      if (error is DioException && error.response?.statusCode == 401) {
        _setState(AsyncValue.error(error, StackTrace.current));
        return;
      }
      print('Error removing item: $error');
    }
  }

  Future<void> addToCart({
    required int productVariantId,
    required int quantity,
    int? colorId,
  }) async {
    if (!_mounted) return;

    try {
      await _apiClient.post('/carts/add', data: {
        'product_variant_id': productVariantId,
        'quantity': quantity,
        if (colorId != null) 'color_id': colorId,
      });

      if (!_mounted) return;
      await getCart(); // Обновляем корзину после добавления
    } catch (error) {
      if (!_mounted) return;
      if (error is DioException && error.response?.statusCode == 401) {
        _setState(AsyncValue.error(error, StackTrace.current));
        return;
      }
      print('Error adding to cart: $error');
      rethrow; // Прокидываем ошибку дальше для обработки в UI
    }
  }

  double get totalAmount {
    if (state.value == null) return 0.0;
    return state.value!.fold(
        0.0,
        (sum, item) =>
            sum + (double.tryParse(item.price) ?? 0.0) * item.quantity);
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CartNotifier(apiClient);
});
