import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_product.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_color.dart';
import 'package:remalux_ar/features/favorites/domain/services/favorites_service.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';

void showFavoriteSnackBar(
    BuildContext context, bool isAdding, String itemName) {
  CustomSnackBar.show(
    context,
    message:
        'Товар "$itemName" ${isAdding ? "добавлен в" : "удален из"} избранного',
    type: isAdding ? SnackBarType.success : SnackBarType.info,
  );
}

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FavoritesService(apiClient, ref);
});

class FavoriteProductsNotifier
    extends StateNotifier<AsyncValue<List<FavoriteProduct>>> {
  final FavoritesService _service;
  final Ref _ref;
  bool _mounted = true;

  FavoriteProductsNotifier(this._service, this._ref)
      : super(const AsyncValue.loading()) {
    loadFavoriteProducts();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _setState(AsyncValue<List<FavoriteProduct>> newState) {
    if (_mounted) {
      state = newState;
    }
  }

  Future<void> loadFavoriteProducts() async {
    try {
      _setState(const AsyncValue.loading());
      final products = await _service.getFavoriteProducts();
      _setState(AsyncValue.data(products));
    } catch (error, stackTrace) {
      print('❌ Error loading favorite products: $error');
      _setState(AsyncValue.error(error, stackTrace));
    }
  }

  Future<void> toggleFavorite(int productId, BuildContext context,
      String productName, bool isFavourite) async {
    try {
      await _service.toggleFavoriteProduct(productId, isFavourite);
      if (context.mounted) {
        showFavoriteSnackBar(context, !isFavourite, productName);
      }
      await loadFavoriteProducts();
    } catch (error) {
      print('❌ Error toggling favorite: $error');
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Произошла ошибка при обновлении избранного',
          type: SnackBarType.error,
        );
      }
      await loadFavoriteProducts();
      rethrow;
    }
  }
}

class FavoriteColorsNotifier
    extends StateNotifier<AsyncValue<List<FavoriteColor>>> {
  final FavoritesService _service;
  bool _mounted = true;

  FavoriteColorsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadFavoriteColors();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _setState(AsyncValue<List<FavoriteColor>> newState) {
    if (_mounted) {
      state = newState;
    }
  }

  Future<void> loadFavoriteColors() async {
    try {
      _setState(const AsyncValue.loading());
      final colors = await _service.getFavoriteColors();
      _setState(AsyncValue.data(colors));
    } catch (error, stackTrace) {
      print('❌ Error loading favorite colors: $error');
      _setState(AsyncValue.error(error, stackTrace));
    }
  }

  Future<void> toggleFavorite(int colorId, BuildContext context,
      String colorName, bool isFavourite) async {
    try {
      await _service.toggleFavoriteColor(colorId, isFavourite);
      if (context.mounted) {
        showFavoriteSnackBar(context, !isFavourite, colorName);
      }
      await loadFavoriteColors();
    } catch (error) {
      print('❌ Error toggling favorite color: $error');
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Произошла ошибка при обновлении избранного',
          type: SnackBarType.error,
        );
      }
      await loadFavoriteColors();
      rethrow;
    }
  }
}

final favoriteProductsProvider = StateNotifierProvider<FavoriteProductsNotifier,
    AsyncValue<List<FavoriteProduct>>>((ref) {
  final service = ref.read(favoritesServiceProvider);
  return FavoriteProductsNotifier(service, ref);
});

final favoriteColorsProvider = StateNotifierProvider<FavoriteColorsNotifier,
    AsyncValue<List<FavoriteColor>>>((ref) {
  final service = ref.read(favoritesServiceProvider);
  return FavoriteColorsNotifier(service);
});
