import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/favorites/domain/models/favorite_color.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'package:remalux_ar/core/widgets/auth_required_modal.dart';
import 'package:easy_localization/easy_localization.dart';

class DetailedColorCard extends ConsumerStatefulWidget {
  final dynamic color;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  const DetailedColorCard({
    super.key,
    required this.color,
    this.onTap,
    this.onFavoritePressed,
  });

  @override
  ConsumerState<DetailedColorCard> createState() => _DetailedColorCardState();
}

class _DetailedColorCardState extends ConsumerState<DetailedColorCard> {
  String currentLocale = 'ru';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentLocale = context.locale.languageCode;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = context.locale.languageCode;
    if (currentLocale != newLocale) {
      setState(() {
        currentLocale = newLocale;
      });
    }
  }

  String _getHexColor() {
    if (widget.color is FavoriteColor) {
      return widget.color.color.hex;
    }
    return widget.color.hex;
  }

  bool _isFavorite() {
    if (widget.color is FavoriteColor) {
      return widget.color.color.isFavourite;
    }
    return widget.color.isFavourite;
  }

  Map<String, String> _getTitle() {
    if (widget.color is FavoriteColor) {
      return widget.color.color.title;
    }
    return widget.color.title;
  }

  String _getRal() {
    if (widget.color is FavoriteColor) {
      return widget.color.color.ral;
    }
    return widget.color.ral;
  }

  @override
  Widget build(BuildContext context) {
    final hexColor = _getHexColor();
    final isFavorite = _isFavorite();
    final title = _getTitle();
    final ral = _getRal();

    return GestureDetector(
      onTap: widget.onTap,
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
                  if (widget.onFavoritePressed != null)
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
                          onPressed: () {
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

                            widget.onFavoritePressed?.call();
                          },
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
                    title[currentLocale] ?? '',
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
