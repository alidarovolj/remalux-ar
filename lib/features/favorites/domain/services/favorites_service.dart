import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_product.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_color.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';

class FavoritesService {
  final ApiClient _apiClient;
  final Ref _ref;

  FavoritesService(this._apiClient, this._ref);

  void _ensureToken() {
    final authState = _ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.token == null) {
      throw Exception('User is not authenticated');
    }
    _apiClient.setAccessToken(authState.token!);
  }

  Future<List<FavoriteProduct>> getFavoriteProducts() async {
    _ensureToken();
    final response = await _apiClient.get(
      '/favourite-products',
      queryParameters: {
        'include': 'product,product.attributes',
      },
    );

    print('API Response for favorite products:');
    print('Full response data: ${response.data}');

    return (response.data['data'] as List)
        .map((json) => FavoriteProduct.fromJson(json))
        .toList();
  }

  Future<List<FavoriteColor>> getFavoriteColors() async {
    _ensureToken();
    final response = await _apiClient.get('/favourite-colors');
    return (response.data['data'] as List)
        .map((json) => FavoriteColor.fromJson(json))
        .toList();
  }

  Future<void> addFavoriteProduct(int productId) async {
    _ensureToken();
    try {
      await _apiClient.post(
        '/favourite-products',
        data: {'product_id': productId},
      );
    } catch (error) {
      print('Error adding favorite product: $error');
      rethrow;
    }
  }

  Future<void> removeFavoriteProduct(int productId) async {
    _ensureToken();
    try {
      await _apiClient.delete(
        '/favourite-products',
        queryParameters: {'product_id': productId},
      );
    } catch (error) {
      print('Error removing favorite product: $error');
      rethrow;
    }
  }

  Future<void> addFavoriteColor(int colorId) async {
    _ensureToken();
    try {
      await _apiClient.post(
        '/favourite-colors',
        data: {'color_id': colorId},
      );
    } catch (error) {
      print('Error adding favorite color: $error');
      rethrow;
    }
  }

  Future<void> removeFavoriteColor(int colorId) async {
    _ensureToken();
    try {
      await _apiClient.delete(
        '/favourite-colors',
        queryParameters: {'favourite_color_id': colorId},
      );
    } catch (error) {
      print('Error removing favorite color: $error');
      rethrow;
    }
  }

  Future<void> toggleFavoriteProduct(int productId, bool isFavorite) async {
    if (isFavorite) {
      await removeFavoriteProduct(productId);
    } else {
      await addFavoriteProduct(productId);
    }
  }

  Future<void> toggleFavoriteColor(int colorId, bool isFavorite) async {
    if (isFavorite) {
      await removeFavoriteColor(colorId);
    } else {
      await addFavoriteColor(colorId);
    }
  }
}
