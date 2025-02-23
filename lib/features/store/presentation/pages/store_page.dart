import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/presentation/widgets/product_variant_item.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';

class StorePage extends ConsumerWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final filtersAsync = ref.watch(filtersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Каталог',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement search
            },
            icon: const Icon(
              Icons.search,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            height: 56,
            color: Colors.white,
            child: filtersAsync.when(
              data: (filters) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected =
                        ref.watch(selectedFiltersProvider).contains(filter.id);
                    return FilterChip(
                      label: Text(filter.title['ru'] ?? ''),
                      selected: isSelected,
                      onSelected: (selected) {
                        final selectedFilters =
                            List<int>.from(ref.read(selectedFiltersProvider));
                        if (selected) {
                          selectedFilters.add(filter.id);
                        } else {
                          selectedFilters.remove(filter.id);
                        }
                        ref.read(selectedFiltersProvider.notifier).state =
                            selectedFilters;
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),

          // Products
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Text('No products found'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.56,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final variant = products[index];
                    return ProductVariantItem(
                      variant: variant,
                      onAddToCart: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Added ${variant.product.title['ru']} to cart'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
