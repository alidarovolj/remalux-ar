import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/features/store/domain/models/filter.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:go_router/go_router.dart';

class SingleFilterModal extends ConsumerWidget {
  final Filter filter;

  const SingleFilterModal({
    super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilters = ref.watch(selectedFiltersProvider);
    final selectedFiltersNotifier = ref.read(selectedFiltersProvider.notifier);
    final productsNotifier = ref.read(productsProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: IntrinsicHeight(
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
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  filter.title['ru'] ?? '',
                  style: GoogleFonts.ysabeau(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: filter.values
                      .map((value) => _buildCheckboxItem(
                            value.values['ru'] ?? '',
                            isSelected: selectedFilters.contains(value.id),
                            onChanged: (bool? checked) {
                              if (checked != null) {
                                selectedFiltersNotifier.toggleFilter(value.id);
                              }
                            },
                          ))
                      .toList(),
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
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  CustomButton(
                    onPressed: () async {
                      if (selectedFilters.isNotEmpty) {
                        final Map<String, dynamic> queryParams = {};
                        for (final id in selectedFilters) {
                          queryParams['filter_ids[$id]'] = id.toString();
                        }
                        await productsNotifier.fetchProducts(
                            queryParams: queryParams);
                        if (context.mounted) context.pop();
                      } else {
                        await productsNotifier.fetchProducts();
                        if (context.mounted) context.pop();
                      }
                    },
                    label: 'Применить',
                    type: ButtonType.normal,
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    onPressed: () async {
                      // Reset only this filter's values
                      final newState = Set<int>.from(selectedFilters);
                      for (final value in filter.values) {
                        newState.remove(value.id);
                      }
                      selectedFiltersNotifier.state = newState;
                      await productsNotifier.fetchProducts();
                      if (context.mounted) context.pop();
                    },
                    label: 'Сбросить',
                    type: ButtonType.normal,
                    backgroundColor: const Color(0xFFF8F8F8),
                    textColor: AppColors.textPrimary,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
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
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4),
          activeColor: AppColors.primary,
        ),
      ),
    );
  }
}
