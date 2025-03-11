import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final bool isColorable;
  final bool isFavorite;
  final List<int>? priceRange;
  final double? rating;
  final int? reviewsCount;
  final String? weight;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.isColorable,
    required this.isFavorite,
    this.priceRange,
    this.rating,
    this.reviewsCount,
    this.weight,
    this.onTap,
    this.onFavoritePressed,
  });

  Widget _buildPrice() {
    if (priceRange == null || priceRange!.isEmpty)
      return const SizedBox.shrink();

    return Text(
      'от ${priceRange![0]} ₸',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    imageUrl,
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
                    decoration: BoxDecoration(
                      color:
                          isFavorite ? AppColors.buttonSecondary : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: isFavorite ? AppColors.primary : Colors.grey,
                        size: 18,
                      ),
                      onPressed: onFavoritePressed,
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
                              color: rating != null
                                  ? Colors.amber
                                  : const Color(0xFFE0E0E0),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating != null
                                  ? '${rating!.toStringAsFixed(1)}${reviewsCount != null && reviewsCount! > 0 ? ' ($reviewsCount)' : ''}'
                                  : '0.0',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (weight != null && weight!.isNotEmpty) ...[
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
                            '$weight кг',
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
