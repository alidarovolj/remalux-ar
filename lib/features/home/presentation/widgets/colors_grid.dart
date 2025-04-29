import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/widgets/section_widget.dart';
import 'package:remalux_ar/features/home/domain/providers/colors_provider.dart';
import 'package:remalux_ar/features/home/domain/providers/detailed_colors_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class ColorsGrid extends ConsumerWidget {
  const ColorsGrid({super.key});

  String _getImageName(Map<String, String> colorTitles) {
    // Пробуем получить русское название для определения картинки
    final ruTitle = colorTitles['ru']?.toLowerCase() ?? '';

    switch (ruTitle) {
      case 'серый':
        return 'grey.png';
      case 'синий':
        return 'Blue.png';
      case 'розовый':
        return 'Pink.png';
      case 'оранжевый':
        return 'Coral.png';
      case 'фиолетовый':
        return 'Purple.png';
      case 'коричневый':
        return 'Brown.png';
      case 'белый':
        return 'aqua.png';
      case 'зеленый':
        return 'Green.png';
      case 'желтый':
        return 'Yellow.png';
      default:
        return 'grey.png';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(colorsProvider);
    final currentLocale = context.locale.languageCode;

    return SectionWidget(
      title: 'home.colors.title'.tr(),
      buttonTitle: 'home.colors.view_all'.tr(),
      onButtonPressed: () => context.push('/colors'),
      child: SizedBox(
        height: 90,
        child: colorsAsync.when(
          data: (colors) => ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    context.push('/colors?mainColorId=${color.id}');
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'lib/core/assets/images/colors/${_getImageName(color.title)}',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // const SizedBox(height: 8),
                      // Text(
                      //   color.title[currentLocale] ?? color.title['ru'] ?? '',
                      //   style: const TextStyle(
                      //     fontSize: 12,
                      //     color: Color(0xFF1F1F1F),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              );
            },
          ),
          loading: () => ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: 6, // Show 6 skeleton items
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
