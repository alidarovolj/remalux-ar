import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/home/domain/models/category.dart';
import 'package:remalux_ar/features/home/presentation/providers/categories_provider.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class StoreCategoriesGrid extends ConsumerWidget {
  const StoreCategoriesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedFilters = ref.watch(selectedFiltersProvider);
    final selectedFiltersNotifier = ref.read(selectedFiltersProvider.notifier);
    final currentLocale = context.locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'store.categories.title'.tr(),
            style: GoogleFonts.ysabeau(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        categoriesAsync.when(
          data: (categories) => GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected =
                  selectedFiltersNotifier.selectedCategory == category.id;
              return _CategoryItem(
                category: category,
                isSelected: isSelected,
                currentLocale: currentLocale,
              );
            },
          ),
          loading: () => GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 8,
            itemBuilder: (context, index) => const _CategoryItemSkeleton(),
          ),
          error: (error, stack) => Center(
            child: Text('common.error'.tr()),
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends ConsumerWidget {
  final Category category;
  final bool isSelected;
  final String currentLocale;

  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFiltersNotifier = ref.read(selectedFiltersProvider.notifier);
    final selectedFilters = ref.watch(selectedFiltersProvider);
    final productsNotifier = ref.read(productsProvider.notifier);

    return GestureDetector(
      onTap: () {
        selectedFiltersNotifier.toggleFilter(category.id, isCategory: true);

        final Map<String, dynamic> queryParams = {};

        // Add category if selected
        if (selectedFiltersNotifier.selectedCategory != null) {
          queryParams['filters[product.category_id]'] =
              selectedFiltersNotifier.selectedCategory.toString();
        }

        // Add other filters
        for (final id in selectedFilters) {
          if (id != selectedFiltersNotifier.selectedCategory) {
            queryParams['filter_ids[$id]'] = id.toString();
          }
        }

        productsNotifier.fetchProducts(
          queryParams: queryParams.isNotEmpty ? queryParams : null,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.borderDark, width: 1)
              : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Image.network(
                category.imageUrl,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                color: AppColors.textPrimary,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 32,
                    height: 32,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 32,
                    height: 32,
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  category.title[currentLocale] ?? category.title['ru'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CategoryItemSkeleton extends StatelessWidget {
  const _CategoryItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 80,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                width: 48,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                width: 32,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
