import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/domain/models/review.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:remalux_ar/features/store/presentation/widgets/review_modal.dart';

class ReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final int totalReviews;
  final String productTitle;
  final String productImage;

  const ReviewsSection({
    super.key,
    required this.reviews,
    required this.totalReviews,
    required this.productTitle,
    required this.productImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: Text(
              'Пока нет отзывов',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReviewCard(review: review);
            },
          ),
        const SizedBox(height: 16),
        CustomButton(
          label: 'Оставить отзыв',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ReviewModal(
                  productTitle: productTitle,
                  productImage: productImage,
                ),
              ),
            );
          },
          type: ButtonType.normal,
          backgroundColor: const Color(0xFFF8F8F8),
          textColor: AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final formattedDate = dateFormat.format(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B4D8B).withOpacity(0.1),
            offset: const Offset(0, 1),
            blurRadius: 5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.authorName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color:
                      index < review.rating ? Colors.amber : Colors.grey[300],
                  size: 20,
                );
              }),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
