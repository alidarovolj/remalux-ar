import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/mock/categories.dart';
import 'package:remalux_ar/core/widgets/loader_modal.dart';
import 'package:remalux_ar/core/types/categories.dart';

class CategoriesRow extends StatefulWidget {
  final bool inSliver;
  final bool isCompact;

  const CategoriesRow({
    super.key,
    this.inSliver = false,
    this.isCompact = false,
  });

  @override
  State<CategoriesRow> createState() => _CategoriesRowState();
}

class _CategoriesRowState extends State<CategoriesRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 230.0,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isCompact) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CategoriesRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompact != oldWidget.isCompact) {
      if (widget.isCompact) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: _heightAnimation.value,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: widget.isCompact
                ? _buildHorizontalLayout()
                : _buildVerticalLayout(),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLayout() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mockCategories.length,
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        separatorBuilder: (_, __) => const SizedBox(width: AppLength.sm),
        itemBuilder: (context, index) {
          final category = mockCategories[index];
          return GestureDetector(
            onTap: () async {
              await _handleNavigation(context, category);
            },
            child: Container(
              margin: const EdgeInsets.only(top: AppLength.sm),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      category.iconPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: AppLength.sm,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return SizedBox(
      height: 230,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.8,
          crossAxisSpacing: AppLength.sm,
          mainAxisSpacing: AppLength.xl,
        ),
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppLength.xs),
        itemCount: mockCategories.length,
        itemBuilder: (context, index) {
          final category = mockCategories[index];
          return GestureDetector(
            onTap: () async {
              await _handleNavigation(context, category);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.asset(
                          category.iconPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppLength.xs),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: AppLength.sm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleNavigation(
      BuildContext context, Category category) async {
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
