import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/home/domain/models/product.dart';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';
import 'package:remalux_ar/features/home/presentation/providers/products_provider.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'package:remalux_ar/core/widgets/auth_required_modal.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductItem extends ConsumerWidget {
  final Product product;

  const ProductItem({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = context.locale.languageCode;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 5,
      shadowColor: const Color.fromRGBO(59, 77, 139, 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                if (product.isColorable)
                  Positioned(
                    top: 8,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'lib/core/assets/images/color_wheel.png',
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: product.isFavourite
                          ? AppColors.buttonSecondary
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        product.isFavourite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: product.isFavourite
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
                                product.id,
                                context,
                                product.title[currentLocale] ??
                                    product.title['ru'] ??
                                    '',
                                product.isFavourite,
                              );

                          // Обновляем список товаров
                          ref.invalidate(productsProvider);
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title[currentLocale] ?? product.title['ru'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: product.rating != null
                              ? Colors.amber
                              : const Color(0xFFE0E0E0),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating?.toString() ?? '0.0',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${product.priceRange[0]} - ${product.priceRange[1]} ₸',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
