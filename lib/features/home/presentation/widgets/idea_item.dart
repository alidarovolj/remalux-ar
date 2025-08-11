import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/home/domain/models/idea.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

class IdeaItem extends StatelessWidget {
  final Idea idea;

  const IdeaItem({super.key, required this.idea});

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate the relative luminance
    double luminance = backgroundColor.computeLuminance();
    // Use white text on dark backgrounds and dark text on light backgrounds
    return luminance > 0.5 ? AppColors.textPrimary : AppColors.white;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    // Get first two colors from the idea's colors list
    final firstColor = idea.colors?.isNotEmpty == true
        ? _parseHexColor(idea.colors?[0]['hex'] ?? '')
        : const Color(0xFFD5EBDF);
    final secondColor = (idea.colors?.length ?? 0) > 1
        ? _parseHexColor(idea.colors?[1]['hex'] ?? '')
        : const Color(0xFFFFB833);

    // Get text colors based on background colors
    final firstTextColor = _getTextColor(firstColor);
    final secondTextColor = _getTextColor(secondColor);

    return GestureDetector(
      onTap: () => context.push('/ideas/${idea.id}'),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      idea.imageUrl,
                      fit: BoxFit.cover,
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

                  // Content
                  SizedBox(
                    height: 80,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            idea.title[currentLocale] ?? idea.title['ru'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const Spacer(),

                          // Room and Color info
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: firstColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (idea.roomTitle?[currentLocale] ??
                                          idea.roomTitle?['ru'] ??
                                          '')
                                      .toUpperCase(),
                                  style: GoogleFonts.ysabeau(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: firstTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: secondColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (idea.colorTitle?[currentLocale] ??
                                          idea.colorTitle?['ru'] ??
                                          '')
                                      .toUpperCase(),
                                  style: GoogleFonts.ysabeau(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: secondTextColor,
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

              // Color Palette
              if (idea.colors?.isNotEmpty == true)
                Positioned(
                  right: 12,
                  top: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 55.0,
                        sigmaY: 55.0,
                      ),
                      child: Container(
                        height: 40,
                        width: (idea.colors?.length ?? 0) * 24 +
                            ((idea.colors?.length ?? 0) - 1) * 4 +
                            16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: idea.colors?.asMap().entries.map((entry) {
                                final colorInfo = entry.value;
                                final color =
                                    _parseHexColor(colorInfo['hex'] ?? '');
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: entry.key < (idea.colors!.length - 1)
                                        ? 4
                                        : 0,
                                  ),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }).toList() ??
                              [],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
