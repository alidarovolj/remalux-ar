import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';

class LanguageSelectionModal extends StatelessWidget {
  const LanguageSelectionModal({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          RadioListTile<String>(
            value: 'kk',
            groupValue: currentLocale,
            onChanged: (value) {
              context.setLocale(const Locale('kk'));
              Navigator.pop(context);
            },
            title: const Text(
              'Қазақша',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
          RadioListTile<String>(
            value: 'ru',
            groupValue: currentLocale,
            onChanged: (value) {
              context.setLocale(const Locale('ru'));
              Navigator.pop(context);
            },
            title: const Text(
              'Русский',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
          RadioListTile<String>(
            value: 'en',
            groupValue: currentLocale,
            onChanged: (value) {
              context.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
            title: const Text(
              'English',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: () => Navigator.pop(context),
            label: 'common.update_language'.tr(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
