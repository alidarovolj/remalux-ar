import 'package:flutter/material.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';
import 'package:remalux_ar/features/store/presentation/widgets/product_item.dart';

class ProductsGrid extends StatelessWidget {
  final List<ProductVariant> products;
  final void Function(ProductVariant)? onAddToCart;

  const ProductsGrid({
    super.key,
    required this.products,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductItem(
          product: product.attributes['product'] as Product,
          onAddToCart: onAddToCart != null ? () => onAddToCart!(product) : null,
        );
      },
    );
  }
}
