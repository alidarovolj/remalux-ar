import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/features/home/presentation/providers/categories_provider.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:easy_localization/easy_localization.dart';

class FiltersModal extends ConsumerWidget {
  final int? initialFilterId;

  const FiltersModal({
    super.key,
    this.initialFilterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final filtersAsync = ref.watch(filtersProvider);
    final selectedFilters = ref.watch(selectedFiltersProvider);
    final selectedFiltersNotifier = ref.read(selectedFiltersProvider.notifier);
    final productsNotifier = ref.read(productsProvider.notifier);
    final scrollController = ScrollController();

    // Scroll to the selected filter after the widget is built
    if (initialFilterId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        filtersAsync.whenData((filters) {
          final index = filters.indexWhere((f) => f.id == initialFilterId);
          if (index != -1) {
            final offset =
                index * 200.0; // Approximate height of each filter section
            scrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'store.filters'.tr(),
                style: GoogleFonts.ysabeau(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(
                  color: AppColors.borderLight, height: 1, thickness: 1),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'store.categories.title'.tr(),
                    style: GoogleFonts.ysabeau(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    data: (categories) => GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                      padding: EdgeInsets.zero,
                      children: categories
                          .map((category) => GestureDetector(
                                onTap: () => selectedFiltersNotifier
                                    .toggleFilter(category.id,
                                        isCategory: true),
                                child: _buildCategoryChip(
                                  category.title[context.locale.languageCode] ??
                                      '',
                                  category.imageUrl,
                                  isSelected: selectedFiltersNotifier
                                          .selectedCategory ==
                                      category.id,
                                ),
                              ))
                          .toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('common.error'.tr())),
                  ),
                  const SizedBox(height: 24),
                  const Divider(
                      color: AppColors.borderLight, height: 1, thickness: 1),
                  const SizedBox(height: 24),
                  filtersAsync.when(
                    data: (filters) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: filters.asMap().entries.map((entry) {
                        final index = entry.key;
                        final filter = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (index > 0) ...[
                              const Divider(
                                  color: AppColors.borderLight,
                                  height: 1,
                                  thickness: 1),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              filter.title[context.locale.languageCode] ?? '',
                              style: GoogleFonts.ysabeau(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...filter.values.map((value) => _buildCheckboxItem(
                                  value.values[context.locale.languageCode] ??
                                      '',
                                  isSelected:
                                      selectedFilters.contains(value.id),
                                  onChanged: (bool? checked) {
                                    if (checked != null) {
                                      selectedFiltersNotifier
                                          .toggleFilter(value.id);
                                    }
                                  },
                                )),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('common.error'.tr())),
                  ),
                  const SizedBox(height: 24),
                  const Divider(
                      color: AppColors.borderLight, height: 1, thickness: 1),
                  const SizedBox(height: 24),
                  Text(
                    'store.price.title'.tr(),
                    style: GoogleFonts.ysabeau(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: RangeSlider(
                      values: const RangeValues(3000, 5000),
                      min: 0,
                      max: 10000,
                      activeColor: AppColors.primary,
                      inactiveColor: const Color(0xFFEEEEEE),
                      onChanged: (RangeValues values) {},
                      divisions: 100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 0),
                                child: Text(
                                  'store.price.from'.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: Text(
                                  '3000 ₸',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'store.price.to'.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: Text(
                                  '5000 ₸',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  offset: Offset(0, -2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                CustomButton(
                  onPressed: () {
                    final Map<String, dynamic> queryParams = {};

                    // Handle category selection
                    if (selectedFiltersNotifier.selectedCategory != null) {
                      queryParams['filters[product.category_id]'] =
                          selectedFiltersNotifier.selectedCategory.toString();
                    }

                    // Handle other filters
                    for (final id in selectedFilters) {
                      if (id != selectedFiltersNotifier.selectedCategory) {
                        queryParams['filter_ids[$id]'] = id.toString();
                      }
                    }

                    if (queryParams.isNotEmpty) {
                      productsNotifier.fetchProducts(queryParams: queryParams);
                    }
                    Navigator.pop(context);
                  },
                  label: 'common.save'.tr(),
                  type: ButtonType.normal,
                  isFullWidth: true,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onPressed: () {
                    selectedFiltersNotifier.reset();
                    productsNotifier.fetchProducts();
                    Navigator.pop(context);
                  },
                  label: 'common.cancel'.tr(),
                  type: ButtonType.normal,
                  backgroundColor: const Color(0xFFF5F6FA),
                  textColor: AppColors.textPrimary,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String iconPath,
      {bool isSelected = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.borderDark, width: 1)
            : null,
      ),
      child: SizedBox(
        height: 80,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Image.network(
                iconPath,
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
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildCheckboxItem(String label,
      {bool isSelected = false, void Function(bool?)? onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppColors.borderDark, width: 1)
            : null,
      ),
      child: Theme(
        data: ThemeData(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(
              color:
                  isSelected ? AppColors.borderDark : const Color(0xFFDDDDDD),
              width: 1,
            ),
          ),
        ),
        child: CheckboxListTile(
          value: isSelected,
          onChanged: onChanged,
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4),
          activeColor: AppColors.primary,
        ),
      ),
    );
  }
}
