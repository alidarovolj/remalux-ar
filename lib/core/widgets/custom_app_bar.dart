import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showTitle;
  final bool showBottomBorder;
  final bool showFavoritesButton;
  final PreferredSizeWidget? bottom;
  final bool showLogo;
  final String? logoAssetPath;
  final double? logoHeight;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showTitle = true,
    this.showBottomBorder = false,
    this.showFavoritesButton = false,
    this.bottom,
    this.showLogo = false,
    this.logoAssetPath,
    this.logoHeight = 40,
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
      title: showLogo
          ? SvgPicture.asset(
              logoAssetPath ?? 'lib/core/assets/icons/logo.svg',
              height: logoHeight,
            )
          : (showTitle
              ? Text(
                  title,
                  style: GoogleFonts.ysabeau(
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null),
      actions: [
        if (showFavoritesButton)
          IconButton(
            icon: SvgPicture.asset(
              'lib/core/assets/icons/profile/heart.svg',
              width: 24,
              height: 24,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.push('/favorites'),
          ),
        if (actions != null) ...actions!,
      ],
      bottom: bottom ??
          (showBottomBorder
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppColors.borderLightGrey,
                  ),
                )
              : null),
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight =
        bottom?.preferredSize.height ?? (showBottomBorder ? 1 : 0);
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
