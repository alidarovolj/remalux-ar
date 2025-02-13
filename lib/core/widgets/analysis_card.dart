import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';

class AnalysisCard extends StatelessWidget {
  final String title;
  final double price;
  final double discount;
  final VoidCallback onAddToCart;

  const AnalysisCard({
    super.key,
    required this.title,
    required this.price,
    required this.discount,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppLength.xs),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppLength.xs),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppLength.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppLength.body,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppLength.xs,
                        vertical: AppLength.four,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppLength.xs),
                      ),
                      child: Text(
                        '-${discount.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: AppLength.sm,
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${price.toStringAsFixed(0)}₸',
                      style: const TextStyle(
                        fontSize: AppLength.body,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: AppLength.xs),
                    Text(
                      '${(price * (1 - discount / 100)).toStringAsFixed(0)}₸',
                      style: const TextStyle(
                        fontSize: AppLength.body,
                        color: AppColors.primary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppLength.tiny),
                CustomButton(
                  label: 'В корзину',
                  onPressed: onAddToCart,
                  type: ButtonType.small,
                  isFullWidth: false,
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}
