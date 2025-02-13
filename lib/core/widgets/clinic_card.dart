import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/types/clinics_card_type.dart';

class ClinicsCard extends StatelessWidget {
  final Clinic data;

  const ClinicsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: 300, // Fixed width for the card
        margin:
            const EdgeInsets.only(right: AppLength.body), // Space between cards
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppLength.body),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with fixed height
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppLength.body),
                    topRight: Radius.circular(AppLength.body),
                  ),
                  child: Image.network(
                    data.image,
                    height: 160, // Set a fixed height
                    width: double.infinity, // Match container width
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: AppLength.tiny,
                  left: AppLength.tiny,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppLength.xs, vertical: AppLength.four),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppLength.xs),
                    ),
                    child: Text(
                      "${data.discount.value}% ${data.discount.title}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppLength.xs,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppLength.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontSize: AppLength.body,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppLength.four),
                  Text(
                    data.description,
                    style: const TextStyle(
                      fontSize: AppLength.sm,
                      color: AppColors.textSecondary,
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
                        "${data.place.distance} км от вас",
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
                        data.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: AppLength.xs,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
