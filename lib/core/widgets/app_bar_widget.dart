import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showCompareButton;
  final bool showFavoriteButton;

  const AppBarWidget({
    super.key,
    required this.title,
    this.showCompareButton = false,
    this.showFavoriteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F1F1F)),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1F1F1F),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (showCompareButton)
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Color(0xFF1F1F1F)),
            onPressed: () {},
          ),
        if (showFavoriteButton)
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF1F1F1F)),
            onPressed: () {},
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
