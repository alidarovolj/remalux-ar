import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';

class ReviewModal extends ConsumerStatefulWidget {
  final String productTitle;
  final String productImage;

  const ReviewModal({
    super.key,
    required this.productTitle,
    required this.productImage,
  });

  @override
  ConsumerState<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends ConsumerState<ReviewModal> {
  int selectedRating = 0;
  final reviewController = TextEditingController();
  final List<String> selectedImages = [];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthorized = authState.token != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEEEEEE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Text(
                  'Оставить отзыв',
                  style: GoogleFonts.ysabeau(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (!isAuthorized) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.productImage,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.productTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Чтобы оставить отзыв, необходимо авторизоваться',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    label: 'Войти',
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/auth');
                    },
                    type: ButtonType.normal,
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Content for authorized users
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.productImage,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.productTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating
                    const Text(
                      'Поставьте оценку',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              selectedRating > index
                                  ? Icons.star
                                  : Icons.star_border,
                              color: selectedRating > index
                                  ? Colors.amber
                                  : Colors.grey,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Photo upload
                    const Text(
                      'Добавьте фото',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ...List.generate(3, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Review text
                    const Text(
                      'Ваш отзыв',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Напишите ваш отзыв о продукте',
                        hintStyle: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit button
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
              ),
              child: CustomButton(
                label: 'Оставить отзыв',
                onPressed: () {
                  Navigator.pop(context);
                },
                type: ButtonType.normal,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
