import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:remalux_ar/core/styles/constants.dart';

class CartSkeleton extends StatelessWidget {
  const CartSkeleton({super.key});

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildCartItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          _buildShimmerContainer(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _buildShimmerContainer(
                  width: double.infinity,
                  height: 16,
                ),
                const SizedBox(height: 8),

                // Color info
                _buildShimmerContainer(
                  width: 120,
                  height: 12,
                ),
                const SizedBox(height: 8),

                // Weight
                _buildShimmerContainer(
                  width: 80,
                  height: 12,
                ),
                const SizedBox(height: 12),

                // Price and Quantity Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    _buildShimmerContainer(
                      width: 80,
                      height: 16,
                    ),

                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildShimmerContainer(
                        width: 100,
                        height: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Favorite Button
          _buildShimmerContainer(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cart Items
          for (var i = 0; i < 3; i++) ...[
            _buildCartItemSkeleton(),
            const SizedBox(height: 12),
          ],

          // Bottom Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promo Code Input
                _buildShimmerContainer(
                  width: double.infinity,
                  height: 48,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 16),

                // Cart Summary Title
                _buildShimmerContainer(
                  width: 120,
                  height: 16,
                ),
                const SizedBox(height: 16),

                // Products Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerContainer(
                      width: 80,
                      height: 14,
                    ),
                    _buildShimmerContainer(
                      width: 100,
                      height: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Discount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerContainer(
                      width: 60,
                      height: 14,
                    ),
                    _buildShimmerContainer(
                      width: 80,
                      height: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmerContainer(
                      width: 40,
                      height: 16,
                    ),
                    _buildShimmerContainer(
                      width: 120,
                      height: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Continue Button
                _buildShimmerContainer(
                  width: double.infinity,
                  height: 48,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
