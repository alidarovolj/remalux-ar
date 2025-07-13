import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/home/domain/providers/selected_color_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remalux_ar/features/store/domain/providers/product_color_selection_provider.dart';

class ColorSelection extends ConsumerWidget {
  const ColorSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = ref.watch(selectedColorProvider);
    final currentLocale = context.locale.languageCode;

    if (selectedColor != null) {
      return Column(
        children: [
          Container(
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Color(
                        int.parse('0xFF${selectedColor.hex.substring(1)}')),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedColor.title[currentLocale] ??
                            selectedColor.title['ru'] ??
                            '',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        selectedColor.ral,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F8F8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      selectedColor.isFavourite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: selectedColor.isFavourite
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      // ✅ Избранное - показываем уведомление
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Функция избранного будет доступна в следующем обновлении'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                try {
                  final product =
                      ref.read(productColorSelectionProvider).product;
                  if (product != null) {
                    await ref
                        .read(productColorSelectionProvider.notifier)
                        .setProduct(product);

                    if (context.mounted) {
                      context.push('/colors', extra: {
                        'productId': product.id,
                        'fromProductDetail': true,
                      });
                    }
                  }
                } catch (e) {
                  print('Error navigating to colors page: $e');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/core/assets/images/color_wheel.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'color_selection.select_another_color'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Material(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          try {
            final product = ref.read(productColorSelectionProvider).product;
            if (product != null) {
              await ref
                  .read(productColorSelectionProvider.notifier)
                  .setProduct(product);

              if (context.mounted) {
                context.push('/colors', extra: {
                  'productId': product.id,
                  'fromProductDetail': true,
                });
              }
            }
          } catch (e) {
            print('Error navigating to colors page: $e');
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/core/assets/images/color_wheel.png',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'color_selection.select_color'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.links,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
