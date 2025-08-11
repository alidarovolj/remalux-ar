import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'package:remalux_ar/core/widgets/auth_required_modal.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductVariantItem extends ConsumerWidget {
  final ProductVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductVariantItem({
    super.key,
    required this.variant,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = variant.attributes['product'] as Map<String, dynamic>?;
    final currentLocale = context.locale.languageCode;

    if (product == null) {
      return Card(
        child: Center(
          child: Text('common.no_data'.tr()),
        ),
      );
    }

    final title = (product['title'] as Map<String, dynamic>?)?[currentLocale] ??
        (product['title'] as Map<String, dynamic>?)?['ru'] ??
        'common.no_title'.tr();
    final isColorable = product['is_colorable'] as bool? ?? false;
    final isFavourite = product['is_favourite'] as bool? ?? false;
    final productId = product['id'] as int?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B4D8B).withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B4D8B).withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    variant.image_url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error_outline),
                        ),
                      );
                    },
                  ),
                ),
                // Colorable indicator
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
                // Favorite button
                if (productId != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isFavourite
                            ? AppColors.buttonSecondary
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: isFavourite
                              ? AppColors.primary
                              : Colors.grey[600],
                          size: 18,
                        ),
                        onPressed: () async {
                          final authState = ref.read(authProvider);

                          if (!authState.isAuthenticated) {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => const AuthRequiredModal(),
                            );
                            return;
                          }

                          try {
                            await ref
                                .read(favoriteProductsProvider.notifier)
                                .toggleFavorite(
                                    productId, context, title, isFavourite);

                            // Обновляем список товаров через force-refresh
                            ref.read(productsProvider.notifier).fetchProducts();
                          } catch (error) {
                            // Ошибка уже обработана в toggleFavorite
                          }
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                // Availability indicator
                if (variant.isAvailable)
                  Positioned(
                    top: 8,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'store.in_stock'.tr(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),

                  // Rating and Category
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
                              color: variant.rating != null
                                  ? Colors.amber
                                  : const Color(0xFFE0E0E0),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              variant.rating != null
                                  ? '${variant.rating!.toStringAsFixed(1)}${variant.reviewsCount > 0 ? ' (${variant.reviewsCount})' : ''}'
                                  : '0.0',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          'store.weight_value'
                              .tr(args: [variant.value.toString()]),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Price and Cart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (variant.discount_price != null) ...[
                            Text(
                              'store.price_value'.tr(args: [
                                variant.discount_price!.toInt().toString()
                              ]),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'store.price_value'
                                  .tr(args: [variant.price.toInt().toString()]),
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ] else
                            Text(
                              'store.price_value'
                                  .tr(args: [variant.price.toInt().toString()]),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                      if (onAddToCart != null && variant.isAvailable)
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
