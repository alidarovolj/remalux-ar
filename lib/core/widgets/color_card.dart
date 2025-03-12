import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_color.dart';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';
import 'package:remalux_ar/core/theme/colors.dart';

class ColorCard extends ConsumerWidget {
  final FavoriteColor color;
  final VoidCallback? onTap;

  const ColorCard({
    super.key,
    required this.color,
    this.onTap,
  });

  Color _getColor() {
    try {
      final hex = color.color.hex;
      if (hex.isEmpty) return Colors.grey;
      final hexString = hex.startsWith('#') ? hex.substring(1) : hex;
      return Color(int.parse('0xFF$hexString'));
    } catch (e) {
      print('Error parsing color hex: $e');
      return Colors.grey;
    }
  }

  String _getTitle() {
    try {
      final title = color.color.title;
      return title['ru']?.toString() ?? '';
    } catch (e) {
      print('Error getting color title: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorValue = _getColor();
    final title = _getTitle();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: colorValue,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
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
                      onPressed: () {
                        ref
                            .read(favoriteColorsProvider.notifier)
                            .toggleFavorite(
                              color.color.id,
                              context,
                              _getTitle(),
                              color.color.isFavourite,
                            );
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
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    color.color.ral ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
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
