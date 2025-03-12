import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_product.dart';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';

class ProductCard extends ConsumerWidget {
  final FavoriteProduct product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  String _getTitle() {
    try {
      final productData =
          product.product.attributes['product'] as Map<String, dynamic>?;
      if (productData == null) return '';

      final title = productData['title'] as Map<String, dynamic>?;
      if (title == null) return '';

      return title['ru']?.toString() ?? '';
    } catch (e) {
      print('Error getting product title: $e');
      return '';
    }
  }

  String _getCategory() {
    try {
      final productData =
          product.product.attributes['product'] as Map<String, dynamic>?;
      if (productData == null) return '';

      final category = productData['category'] as Map<String, dynamic>?;
      if (category == null) return '';

      final title = category['title'] as Map<String, dynamic>?;
      if (title == null) return '';

      return title['ru']?.toString() ?? '';
    } catch (e) {
      print('Error getting category: $e');
      return '';
    }
  }

  bool _isColorable() {
    try {
      final productData =
          product.product.attributes['product'] as Map<String, dynamic>?;
      if (productData == null) return false;
      return productData['is_colorable'] as bool? ?? false;
    } catch (e) {
      print('Error checking if product is colorable: $e');
      return false;
    }
  }

  List<int>? _getPriceRange() {
    try {
      final productData =
          product.product.attributes['product'] as Map<String, dynamic>?;
      if (productData == null) return null;

      final priceRange = productData['price_range'] as List<dynamic>?;
      if (priceRange == null || priceRange.length != 2) return null;

      final from = (priceRange[0] as num).toInt();
      final to = (priceRange[1] as num).toInt();

      if (from == 0 && to == 0) return null;
      return [from, to];
    } catch (e) {
      print('Error getting price range: $e');
      return null;
    }
  }

  double? _getPrice() {
    try {
      final productData =
          product.product.attributes['product'] as Map<String, dynamic>?;
      if (productData == null) return null;

      final variants = productData['product_variants'] as List<dynamic>?;
      if (variants == null || variants.isEmpty) return null;

      // Get price from first variant
      final variant = variants[0] as Map<String, dynamic>;
      final price = variant['price'] as num?;

      if (price == null || price == 0) return null;
      return price.toDouble();
    } catch (e) {
      print('Error getting price: $e');
      return null;
    }
  }

  Widget _buildPrice() {
    final price = _getPrice();
    if (price != null && price > 0) {
      // Show regular price
      return Text(
        '${price.toInt()} ₸',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
    } else {
      // Try to get price range
      try {
        final productData =
            product.product.attributes['product'] as Map<String, dynamic>?;
        if (productData == null) return const SizedBox.shrink();

        final priceRange = productData['price_range'] as List<dynamic>?;
        if (priceRange == null || priceRange.length != 2) {
          return const SizedBox.shrink();
        }

        final from = (priceRange[0] as num).toInt();
        final to = (priceRange[1] as num).toInt();

        if (from == 0 && to == 0) return const SizedBox.shrink();

        return Text(
          'от $from ₸',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        );
      } catch (e) {
        print('Error getting price range: $e');
        return const SizedBox.shrink();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _getTitle();
    final category = _getCategory();
    final isColorable = _isColorable();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B4D8B).withOpacity(0.1),
              offset: const Offset(0, 1),
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.product.image_url,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error_outline),
                        ),
                      );
                    },
                  ),
                ),
                if (isColorable)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Image.asset(
                      'lib/core/assets/images/color_wheel.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(favoriteProductsProvider.notifier)
                              .toggleFavorite(
                                product.product.id,
                                context,
                                _getTitle(),
                                product.product.is_favourite,
                              );
                        } catch (error) {
                          // Ошибка уже обработана в toggleFavorite через custom_snack_bar
                        }
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: product.product.rating != null
                                  ? Colors.amber
                                  : const Color(0xFFE0E0E0),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.product.rating != null
                                  ? '${product.product.rating!.toStringAsFixed(1)}${product.product.reviewsCount > 0 ? ' (${product.product.reviewsCount})' : ''}'
                                  : '0.0',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (product.product.value.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.product.value} кг',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPrice(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
