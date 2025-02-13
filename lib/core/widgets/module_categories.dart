import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/mock/categories.dart';
import 'package:remalux_ar/core/widgets/loader_modal.dart';
import 'package:remalux_ar/core/types/categories.dart';

class ModuleCategories extends StatelessWidget {
  final bool inSliver;
  final bool isCompact;
  final String? categoryType;

  const ModuleCategories({
    super.key,
    this.inSliver = false,
    this.isCompact = false,
    this.categoryType,
  });

  List<SaleCategory> _getFilteredCategories() {
    if (categoryType == 'analyses') {
      return analysesCategories.toList();
    } else if (categoryType == 'doctors') {
      return doctorsCategories.toList();
    }
    return doctorsCategories;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _buildHorizontalLayout(context);
    return inSliver ? SliverToBoxAdapter(child: content) : content;
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final filteredCategories = _getFilteredCategories();

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filteredCategories.length,
        padding: const EdgeInsets.only(left: AppLength.xs),
        separatorBuilder: (_, __) => const SizedBox(width: AppLength.sm),
        itemBuilder: (context, index) {
          final category = filteredCategories[index];
          return GestureDetector(
            onTap: () async {
              await _handleNavigation(context, category);
            },
            child: SizedBox(
              width: 96,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 96,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: Image.asset(
                              category.iconPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 96,
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: AppLength.xs,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (category.sale && category.saleValue > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppLength.tiny,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppLength.xl),
                        ),
                        child: Text(
                          '-${category.saleValue}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppLength.sm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleNavigation(
      BuildContext context, SaleCategory category) async {
    if (category.route != null) {
      try {
        await LoaderModal.show(
          context,
          title: category.name,
          imagePath: category.iconPath,
        );
        if (context.mounted) {
          context.push(category.route!);
        }
      } catch (e) {
        // Ignore any navigation errors
      }
    }
    category.onTap();
  }
}
