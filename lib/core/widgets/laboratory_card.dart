import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/types/laboratory_card_type.dart';

class LaboratoryCard extends StatelessWidget {
  final Laboratory data;

  const LaboratoryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container with discount badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppLength.xs),
                ),
                child: Image.asset(
                  data.image,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              if (data.discount != null)
                Positioned(
                  left: AppLength.xs,
                  top: AppLength.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLength.xs,
                      vertical: AppLength.tiny,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5FBC), Color(0xFF5D51A8)],
                      ),
                      borderRadius: BorderRadius.circular(AppLength.tiny),
                    ),
                    child: Text(
                      '${data.discount}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppLength.sm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Lab info
          Padding(
            padding: const EdgeInsets.all(AppLength.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: AppLength.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppLength.tiny),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: AppLength.body,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppLength.four),
                    Text(
                      '${data.distance} км от вас',
                      style: const TextStyle(
                        fontSize: AppLength.xs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star,
                      size: AppLength.body,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: AppLength.four),
                    Text(
                      data.rating.toString(),
                      style: const TextStyle(
                        fontSize: AppLength.xs,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
