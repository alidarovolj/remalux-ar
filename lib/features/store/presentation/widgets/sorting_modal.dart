import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class SortingModal extends ConsumerWidget {
  const SortingModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSorting = ref.watch(sortingProvider);
    final sortingNotifier = ref.read(sortingProvider.notifier);
    final productsNotifier = ref.read(productsProvider.notifier);

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
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'store.sorting'.tr(),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildRadioItem(
                  'store.sorting_options.price_asc'.tr(),
                  'asc',
                  selectedSorting,
                  (value) {
                    sortingNotifier.state = value;
                  },
                ),
                const SizedBox(height: 8),
                _buildRadioItem(
                  'store.sorting_options.price_desc'.tr(),
                  'desc',
                  selectedSorting,
                  (value) {
                    sortingNotifier.state = value;
                  },
                ),
              ],
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
                    final selectedFilters = ref.read(selectedFiltersProvider);
                    final Map<String, dynamic> queryParams = {};

                    if (selectedSorting != null) {
                      queryParams['order_by'] = selectedSorting;
                    }

                    if (selectedFilters.isNotEmpty) {
                      for (final id in selectedFilters) {
                        queryParams['filter_ids[$id]'] = id.toString();
                      }
                    }

                    await productsNotifier.fetchProducts(
                        queryParams: queryParams);
                    if (context.mounted) context.pop();
                  },
                  label: 'common.save'.tr(),
                  type: ButtonType.normal,
                ),
                const SizedBox(height: 8),
                CustomButton(
                  onPressed: () async {
                    sortingNotifier.state = null;
                    final selectedFilters = ref.read(selectedFiltersProvider);

                    if (selectedFilters.isNotEmpty) {
                      final Map<String, dynamic> queryParams = {};
                      for (final id in selectedFilters) {
                        queryParams['filter_ids[$id]'] = id.toString();
                      }
                      await productsNotifier.fetchProducts(
                          queryParams: queryParams);
                    } else {
                      await productsNotifier.fetchProducts();
                    }

                    if (context.mounted) context.pop();
                  },
                  label: 'common.cancel'.tr(),
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
    );
  }

  Widget _buildRadioItem(
    String label,
    String value,
    String? groupValue,
    void Function(String?) onChanged,
  ) {
    final isSelected = value == groupValue;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: AppColors.borderDark, width: 1)
            : null,
      ),
      child: RadioListTile(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: const VisualDensity(horizontal: -4),
      ),
    );
  }
}
