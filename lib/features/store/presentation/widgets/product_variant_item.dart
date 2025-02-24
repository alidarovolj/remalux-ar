import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';

class ProductVariantItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final product = variant.attributes['product'] as Map<String, dynamic>?;

    if (product == null) {
      return const Card(
        child: Center(
          child: Text('Нет данных о продукте'),
        ),
      );
    }

    final title =
        (product['title'] as Map<String, dynamic>?)?['ru'] as String? ??
            'Без названия';
    final isColorable = product['is_colorable'] as bool? ?? false;
    final category = (product['category'] as Map<String, dynamic>?)?['title']
            ?['ru'] as String? ??
        '';

    return Container(
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
                // Availability indicator
                if (variant.isAvailable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'В наличии',
                        style: TextStyle(
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 8),

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
                            variant.rating?.toString() ?? '0.0',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (category.isNotEmpty) ...[
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
                          '${variant.value} кг',
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

                // Price and Cart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (variant.discount_price != null) ...[
                          Text(
                            '${variant.discount_price!.toInt()} ₸',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${variant.price.toInt()} ₸',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textPrimary.withOpacity(0.5),
                            ),
                          ),
                        ] else
                          Text(
                            '${variant.price.toInt()} ₸',
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
        ],
      ),
    );
  }
}
