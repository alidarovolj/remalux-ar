import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/domain/models/review.dart';

class ProductDetailRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ProductDetail> getProductDetail(int productId) async {
    try {
      final response = await _apiClient.get('/products/$productId');

      final productDetail = ProductDetail.fromJson(response);
      return productDetail;
    } catch (e) {
      throw Exception('Failed to load product details: $e');
    }
  }

  Future<List<ProductDetail>> getSimilarProducts(int productId,
      {int page = 1, int perPage = 10}) async {
    try {
      final response = await _apiClient.get(
        '/products/$productId/same-products',
        queryParameters: {
          'page': page.toString(),
          'perPage': perPage.toString(),
        },
      );

      final List<dynamic> data = response['data'];
      return data.map((item) => ProductDetail.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load similar products: $e');
    }
  }

  Future<List<ProductDetail>> getRelatedProducts(int productId,
      {int page = 1, int perPage = 10}) async {
    try {
      final response = await _apiClient.get(
        '/products/$productId/related-products',
        queryParameters: {
          'page': page.toString(),
          'perPage': perPage.toString(),
        },
      );

      final List<dynamic> data = response['data'];
      return data.map((item) => ProductDetail.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load related products: $e');
    }
  }

  Future<ReviewsResponse> getProductReviews(int productId,
      {int page = 1, int perPage = 10}) async {
    try {
      final response = await _apiClient.get(
        '/products/$productId/reviews',
        queryParameters: {
          'page': page.toString(),
          'perPage': perPage.toString(),
        },
      );

      return ReviewsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load product reviews: $e');
    }
  }
}
