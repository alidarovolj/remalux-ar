import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_color.dart';

class DetailedColorCard extends ConsumerWidget {
  final dynamic color;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  const DetailedColorCard({
    super.key,
    required this.color,
    this.onTap,
    this.onFavoritePressed,
  });

  String _getHexColor() {
    if (color is FavoriteColor) {
      return color.color.hex;
    }
    return color.hex;
  }

  bool _isFavorite() {
    if (color is FavoriteColor) {
      return color.color.isFavourite;
    }
    return color.isFavourite;
  }

  int _getId() {
    if (color is FavoriteColor) {
      return color.color.id;
    }
    return color.id;
  }

  Map<String, String> _getTitle() {
    if (color is FavoriteColor) {
      return color.color.title;
    }
    return color.title;
  }

  String _getRal() {
    if (color is FavoriteColor) {
      return color.color.ral;
    }
    return color.ral;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hexColor = _getHexColor();
    final isFavorite = _isFavorite();
    final id = _getId();
    final title = _getTitle();
    final ral = _getRal();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(59, 77, 139, 0.1),
              blurRadius: 5,
              offset: Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${hexColor.substring(1)}')),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  if (onFavoritePressed != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? AppColors.buttonSecondary
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.primary
                                : Colors.grey[600],
                            size: 18,
                          ),
                          onPressed: onFavoritePressed,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title['ru'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ral,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
