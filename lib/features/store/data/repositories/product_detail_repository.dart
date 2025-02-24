import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/domain/models/review.dart';
import 'package:remalux_ar/core/constants/api_constants.dart';

class ProductDetailRepository {
  final http.Client _client;

  ProductDetailRepository({http.Client? client})
      : _client = client ?? http.Client();

  Future<ProductDetail> getProductDetail(int productId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/api/products/$productId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ProductDetail.fromJson(json['data']);
      }
      throw Exception('Failed to load product details');
    } catch (e) {
      throw Exception('Failed to load product details: $e');
    }
  }

  Future<List<ProductDetail>> getSimilarProducts(int productId,
      {int page = 1, int perPage = 10}) async {
    try {
      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/products/$productId/same-products?page=$page&perPage=$perPage'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        return data.map((item) => ProductDetail.fromJson(item)).toList();
      }
      throw Exception('Failed to load similar products');
    } catch (e) {
      throw Exception('Failed to load similar products: $e');
    }
  }

  Future<List<ProductDetail>> getRelatedProducts(int productId,
      {int page = 1, int perPage = 10}) async {
    try {
      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/products/$productId/related-products?page=$page&perPage=$perPage'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        return data.map((item) => ProductDetail.fromJson(item)).toList();
      }
      throw Exception('Failed to load related products');
    } catch (e) {
      throw Exception('Failed to load related products: $e');
    }
  }

  Future<ReviewsResponse> getProductReviews(int productId,
      {int page = 1, int perPage = 10}) async {
    try {
      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/api/products/$productId/reviews?page=$page&perPage=$perPage'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ReviewsResponse.fromJson(json);
      }
      throw Exception('Failed to load product reviews');
    } catch (e) {
      throw Exception('Failed to load product reviews: $e');
    }
  }
}
