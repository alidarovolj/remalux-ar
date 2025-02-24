import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/domain/models/review.dart';
import 'package:remalux_ar/features/store/presentation/providers/product_detail_provider.dart';

class ProductDetailPage extends ConsumerWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productDetailAsync = ref.watch(productDetailProvider(productId));
    final similarProductsAsync = ref.watch(similarProductsProvider(productId));
    final reviewsAsync = ref.watch(productReviewsProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали продукта'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: productDetailAsync.when(
        data: (product) => _buildProductDetail(
            context, product, similarProductsAsync, reviewsAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Ошибка при загрузке: $error'),
        ),
      ),
    );
  }

  Widget _buildProductDetail(
    BuildContext context,
    ProductDetail product,
    AsyncValue<List<ProductDetail>> similarProductsAsync,
    AsyncValue<ReviewsResponse> reviewsAsync,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            product.imageUrl,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title['ru'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description['ru'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Артикул: ${product.article}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withOpacity(0.5),
                  ),
                ),
                if (product.productVariants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Цена: ${product.productVariants.first.price.toInt()} ₸',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildSimilarProducts(similarProductsAsync),
          _buildReviews(reviewsAsync),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts(
      AsyncValue<List<ProductDetail>> similarProductsAsync) {
    return similarProductsAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Похожие товары',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          product.imageUrl,
                          height: 120,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.title['ru'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildReviews(AsyncValue<ReviewsResponse> reviewsAsync) {
    return reviewsAsync.when(
      data: (response) {
        if (response.data.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Отзывы (${response.meta.total})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: response.data.length,
              itemBuilder: (context, index) {
                final review = response.data[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(review.comment),
                        const SizedBox(height: 8),
                        Text(
                          review.createdAt.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
