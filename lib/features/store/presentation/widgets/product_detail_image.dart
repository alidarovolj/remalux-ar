import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/domain/providers/selected_color_provider.dart';

class ProductDetailImage extends ConsumerWidget {
  final String imageUrl;
  final bool isColorable;

  const ProductDetailImage({
    super.key,
    required this.imageUrl,
    required this.isColorable,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isColorable) {
      return AspectRatio(
        aspectRatio: 1,
        child: Consumer(
          builder: (context, ref, child) {
            final selectedColor = ref.watch(selectedColorProvider);
            return Container(
              color: selectedColor != null
                  ? Color(int.parse('0xFF${selectedColor.hex.substring(1)}'))
                  : Colors.white,
              child: PageView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Image.asset(
                    'lib/core/assets/images/store/${index + 1}.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
      ),
    );
  }
}
