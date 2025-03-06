import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
