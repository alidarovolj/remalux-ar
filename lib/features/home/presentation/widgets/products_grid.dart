import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/widgets/section_widget.dart';
import 'package:remalux_ar/features/home/presentation/providers/products_provider.dart';
import 'package:remalux_ar/features/home/presentation/widgets/product_item.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductsGrid extends ConsumerStatefulWidget {
  const ProductsGrid({super.key});

  @override
  ConsumerState<ProductsGrid> createState() => _ProductsGridState();
}

class _ProductsGridState extends ConsumerState<ProductsGrid> {
  @override
  void initState() {
    super.initState();
    // Force refresh products data after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return SectionWidget(
      title: 'home.products.title'.tr(),
      buttonTitle: 'home.products.view_all'.tr(),
      onButtonPressed: () => context.push('/store'),
      child: SizedBox(
        height: 293,
        child: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const Center(
                child: Text('Нет товаров'),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return SizedBox(
                  width: 180,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => context.push('/products/${product.id}'),
                      child: ProductItem(product: product),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            itemBuilder: (context, index) => const SizedBox(
              width: 180,
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: _ProductItemSkeleton(),
              ),
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Ошибка: $error'),
          ),
        ),
      ),
    );
  }
}

class _ProductItemSkeleton extends StatelessWidget {
  const _ProductItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 16,
                    color: Colors.white,
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
