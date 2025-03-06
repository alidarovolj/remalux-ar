import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NewsModalSkeleton extends StatelessWidget {
  const NewsModalSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
          const SizedBox(height: 16),

          // Title placeholder
          Container(
            width: double.infinity,
            height: 24,
            color: Colors.white,
          ),
          const SizedBox(height: 8),

          // Date placeholder
          Container(
            width: 100,
            height: 16,
            color: Colors.white,
          ),
          const SizedBox(height: 16),

          // Content placeholders
          ...List.generate(
              4,
              (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                  )),
        ],
      ),
    );
  }
}
