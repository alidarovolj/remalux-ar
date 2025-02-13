import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/home/domain/models/idea.dart';

class IdeaItem extends StatelessWidget {
  final Idea idea;

  const IdeaItem({super.key, required this.idea});

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
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
    // Get first two colors from the idea's colors list
    final firstColor = idea.colors.isNotEmpty
        ? _parseHexColor(idea.colors[0].hex)
        : const Color(0xFFD5EBDF);
    final secondColor = idea.colors.length > 1
        ? _parseHexColor(idea.colors[1].hex)
        : const Color(0xFFFFB833);

    // Get text colors based on background colors
    final firstTextColor = _getTextColor(firstColor);
    final secondTextColor = _getTextColor(secondColor);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        idea.title['ru'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),

                      const Spacer(),

                      // Room and Color info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: firstColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              idea.roomTitle.title['ru'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: firstTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: secondColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              idea.colorTitle.title['ru'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
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
          if (idea.colors.isNotEmpty)
            Positioned(
              left: 12,
              top: 145,
              child: Container(
                height: 28,
                width:
                    idea.colors.length * 20 + (idea.colors.length - 1) * 6 + 16,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: idea.colors.map((colorInfo) {
                    final color = _parseHexColor(colorInfo.hex);
                    return Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
