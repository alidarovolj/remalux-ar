import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';

class DiscountCard extends StatelessWidget {
  final bool isCompact;

  const DiscountCard({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLength.body,
          vertical: AppLength.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLength.body),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFCE7F4), // Compact gradient colors
              Color(0xFFE2E9FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(
                    'lib/core/assets/images/promos/discount.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 40);
                    },
                  ),
                ),
                const SizedBox(width: AppLength.sm),
                const Text(
                  "10% скидка на первый прием",
                  style: TextStyle(
                    fontSize: AppLength.body,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      );
    }

    // Full version of the card
    return Container(
      padding: const EdgeInsets.all(AppLength.body),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLength.body),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE2E9FF),
            Color(0xFFEAE8FD),
            Color(0xFFF6E7F7),
            Color(0xFFFAE7F4),
            Color(0xFFFDE8F0),
            Color(0xFFFFE9ED),
            Color(0xFFFFEAEA),
          ],
          stops: [0.0196, 0.2167, 0.442, 0.542, 0.7236, 0.8644, 1.0052],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "10% скидка",
                  style: TextStyle(
                    fontSize: AppLength.xl,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Запишитесь на прием к врачу через приложение и получите скидку на первый прием",
                  style: TextStyle(
                    fontSize: AppLength.sm,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppLength.body),
                CustomButton(
                  label: 'Поиск врачей и клиник',
                  onPressed: () {},
                  type: ButtonType.normal,
                  isFullWidth: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppLength.body),
          SizedBox(
            width: 96,
            height: 141,
            child: Image.asset(
              'lib/core/assets/images/promos/discount.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 40);
              },
            ),
          ),
        ],
      ),
    );
  }
}
