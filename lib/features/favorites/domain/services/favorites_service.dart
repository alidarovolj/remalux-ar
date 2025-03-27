import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_product.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_color.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

class FavoritesService {
  final ApiClient _apiClient;
  final Ref _ref;

  FavoritesService(this._apiClient, this._ref);

  Future<List<FavoriteProduct>> getFavoriteProducts() async {
    print('🔄 Fetching favorite products');
    final token = await StorageService.getToken();
    if (token == null) {
      print('⚠️ No token found, returning empty list');
      return [];
    }
    _apiClient.setAccessToken(token);
    try {
      final response = await _apiClient.get(
        '/favourite-products',
        queryParameters: {
          'include': 'product,product.attributes',
        },
      );

      print('✅ Successfully fetched favorite products');
      print('📊 Response data: ${response.data}');

      return (response.data['data'] as List)
          .map((json) => FavoriteProduct.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching favorite products: $error');
      rethrow;
    }
  }

  Future<List<FavoriteColor>> getFavoriteColors() async {
    print('🔄 Fetching favorite colors');
    final token = await StorageService.getToken();
    if (token == null) {
      print('⚠️ No token found, returning empty list');
      return [];
    }
    _apiClient.setAccessToken(token);
    try {
      final response = await _apiClient.get('/favourite-colors');
      print('✅ Successfully fetched favorite colors');
      return (response.data['data'] as List)
          .map((json) => FavoriteColor.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching favorite colors: $error');
      rethrow;
    }
  }

  Future<void> addFavoriteProduct(int productId) async {
    print('🔄 Adding product to favorites: $productId');
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token found, cannot add to favorites');
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.post(
        '/favourite-products',
        data: {'product_id': productId},
      );
      print('✅ Successfully added product to favorites');
    } catch (error) {
      print('❌ Error adding favorite product: $error');
      rethrow;
    }
  }

  Future<void> removeFavoriteProduct(int productId) async {
    print('🔄 Removing product from favorites: $productId');
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token found, cannot remove from favorites');
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.delete(
        '/favourite-products',
        queryParameters: {'product_id': productId},
      );
      print('✅ Successfully removed product from favorites');
    } catch (error) {
      print('❌ Error removing favorite product: $error');
      rethrow;
    }
  }

  Future<void> addFavoriteColor(int colorId) async {
    print('🔄 Adding color to favorites: $colorId');
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token found, cannot add to favorites');
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.post(
        '/favourite-colors',
        data: {'color_id': colorId},
      );
      print('✅ Successfully added color to favorites');
    } catch (error) {
      print('❌ Error adding favorite color: $error');
      rethrow;
    }
  }

  Future<void> removeFavoriteColor(int colorId) async {
    print('🔄 Removing color from favorites: $colorId');
    final token = await StorageService.getToken();
    if (token == null) {
      print('❌ No token found, cannot remove from favorites');
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.delete(
        '/favourite-colors',
        queryParameters: {'favourite_color_id': colorId},
      );
      print('✅ Successfully removed color from favorites');
    } catch (error) {
      print('❌ Error removing favorite color: $error');
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
