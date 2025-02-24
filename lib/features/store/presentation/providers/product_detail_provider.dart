import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/store/data/repositories/product_detail_repository.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/domain/models/review.dart';

final productDetailRepositoryProvider =
    Provider<ProductDetailRepository>((ref) {
  return ProductDetailRepository();
});

final productDetailProvider =
    FutureProvider.family<ProductDetail, int>((ref, productId) async {
  final repository = ref.watch(productDetailRepositoryProvider);
  return repository.getProductDetail(productId);
});

final similarProductsProvider =
    FutureProvider.family<List<ProductDetail>, int>((ref, productId) async {
  final repository = ref.watch(productDetailRepositoryProvider);
  return repository.getSimilarProducts(productId);
});

final relatedProductsProvider =
    FutureProvider.family<List<ProductDetail>, int>((ref, productId) async {
  final repository = ref.watch(productDetailRepositoryProvider);
  return repository.getRelatedProducts(productId);
});

final productReviewsProvider =
    FutureProvider.family<ReviewsResponse, int>((ref, productId) async {
  final repository = ref.watch(productDetailRepositoryProvider);
  return repository.getProductReviews(productId);
});
