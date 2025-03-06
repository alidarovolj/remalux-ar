import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/widgets/section_widget.dart';
import 'package:remalux_ar/features/home/domain/providers/colors_provider.dart';

class ColorsGrid extends ConsumerWidget {
  const ColorsGrid({super.key});

  String _getImageName(String colorName) {
    switch (colorName.toLowerCase()) {
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

    return SectionWidget(
      title: 'Цветовые палитры',
      buttonTitle: 'Все цвета',
      onButtonPressed: () {
        context.push('/colors');
      },
      child: SizedBox(
        height: 120,
        child: colorsAsync.when(
          data: (colors) => ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    context.push('/colors', extra: {'mainColorId': color.id});
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
                            'lib/core/assets/images/colors/${_getImageName(color.title['ru'] ?? '')}',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        color.title['ru'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
