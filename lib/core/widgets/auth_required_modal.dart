import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthRequiredModal extends StatelessWidget {
  const AuthRequiredModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'auth.required_title'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'auth.required_description'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary.withOpacity(0.7),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'auth.login'.tr(),
            onPressed: () {
              Navigator.pop(context);
              context.push('/login');
            },
            type: ButtonType.normal,
            isFullWidth: true,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'auth.register'.tr(),
            onPressed: () {
              Navigator.pop(context);
              context.push('/registration');
            },
            type: ButtonType.normal,
            backgroundColor: const Color(0xFFF8F8F8),
            textColor: AppColors.textPrimary,
            isFullWidth: true,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
