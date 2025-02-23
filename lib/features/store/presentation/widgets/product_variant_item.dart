import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';

class ProductVariantItem extends StatelessWidget {
  final ProductVariant variant;
  final VoidCallback? onAddToCart;

  const ProductVariantItem({
    super.key,
    required this.variant,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B4D8B).withOpacity(0.09),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -0.9,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    variant.imageUrl,
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
                if (variant.product.isColorable)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Image.asset(
                      'lib/core/assets/images/color_wheel.png',
                      width: 24,
                      height: 24,
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
                // Title and SKU
                Text(
                  variant.product.title['ru'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Rating
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
                const SizedBox(height: 8),

                // Price and Add to Cart
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (variant.discountPrice != null)
                          Text(
                            '${variant.price.toInt()} ₸',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textPrimary.withOpacity(0.5),
                            ),
                          ),
                        Text(
                          '${(variant.discountPrice ?? variant.price).toInt()} ₸',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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
