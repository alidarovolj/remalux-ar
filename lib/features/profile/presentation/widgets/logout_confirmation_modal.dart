import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/features/profile/presentation/pages/profile_page.dart';

class LogoutConfirmationModal extends ConsumerWidget {
  const LogoutConfirmationModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const SizedBox(height: 24),
          Text(
            'Выйти из профиля',
            style: GoogleFonts.ysabeau(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Вы уверены, что хотите выйти из профиля?',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Отмена',
                  onPressed: () => Navigator.of(context).pop(),
                  backgroundColor: const Color(0xFFF5F5F5),
                  textColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Выйти',
                  onPressed: () async {
                    await ref.read(userProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      CustomSnackBar.show(
                        context,
                        message: 'Вы успешно вышли из профиля',
                        type: SnackBarType.success,
                      );
                    }
                  },
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
