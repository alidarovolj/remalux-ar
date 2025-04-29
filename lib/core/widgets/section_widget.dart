import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';

class SectionWidget extends StatelessWidget {
  final String title;
  final Widget child;
  final String? buttonTitle;
  final VoidCallback? onButtonPressed;
  final String? leadingIcon;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const SectionWidget({
    super.key,
    required this.title,
    required this.child,
    this.buttonTitle,
    this.onButtonPressed,
    this.leadingIcon,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.ysabeau(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (buttonTitle != null && onButtonPressed != null)
                TextButton(
                  onPressed: onButtonPressed,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 24),
                    maximumSize: const Size(double.infinity, 24),
                    backgroundColor: const Color(0xFFF8F8F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonTitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
