import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_product.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_color.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

class FavoritesService {
  final ApiClient _apiClient;

  FavoritesService(this._apiClient);

  Future<List<FavoriteProduct>> getFavoriteProducts() async {
    final token = await StorageService.getToken();
    if (token == null) {
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

      return (response.data['data'] as List)
          .map((json) => FavoriteProduct.fromJson(json))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<List<FavoriteColor>> getFavoriteColors() async {
    final token = await StorageService.getToken();
    if (token == null) {
      return [];
    }
    _apiClient.setAccessToken(token);
    try {
      final response = await _apiClient.get('/favourite-colors');
      return (response.data['data'] as List)
          .map((json) => FavoriteColor.fromJson(json))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addFavoriteProduct(int productId) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.post(
        '/favourite-products',
        data: {'product_id': productId},
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<void> removeFavoriteProduct(int productId) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.delete(
        '/favourite-products',
        queryParameters: {'product_id': productId},
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addFavoriteColor(int colorId) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.post(
        '/favourite-colors',
        data: {'color_id': colorId},
      );
    } catch (error) {
      rethrow;
    }
  }

  Future<void> removeFavoriteColor(int colorId) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Необходимо войти в аккаунт');
    }
    _apiClient.setAccessToken(token);
    try {
      await _apiClient.delete(
        '/favourite-colors',
        queryParameters: {'favourite_color_id': colorId},
      );
    } catch (error) {
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
