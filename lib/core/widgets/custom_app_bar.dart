import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/theme/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showTitle;
  final bool showBottomBorder;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showTitle = true,
    this.showBottomBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              color: AppColors.textPrimary,
              onPressed: () => context.pop(),
            )
          : null,
      title: showTitle
          ? Text(
              title,
              style: GoogleFonts.ysabeau(
                color: AppColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: actions,
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.borderLightGrey,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => showBottomBorder
      ? const Size.fromHeight(kToolbarHeight + 1)
      : const Size.fromHeight(kToolbarHeight);
}
