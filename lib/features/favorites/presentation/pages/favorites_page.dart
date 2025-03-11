import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/product_card.dart';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';
import 'package:remalux_ar/core/widgets/favorite_detailed_color_card.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  final int? initialTabIndex;

  const FavoritesPage({
    super.key,
    this.initialTabIndex,
  });

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update icon colors
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = ref.watch(favoriteProductsProvider);
    final favoriteColors = ref.watch(favoriteColorsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Избранное',
          showBottomBorder: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.buttonSecondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                labelPadding: EdgeInsets.zero,
                tabs: [
                  Tab(
                    height: 44,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'lib/core/assets/icons/profile/paint-bucket.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              _tabController.index == 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Товары',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    height: 44,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'lib/core/assets/icons/profile/palette.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              _tabController.index == 1
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Цвета',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Products tab
                  favoriteProducts.when(
                    data: (products) {
                      print('=== Favorites Debug Info ===');
                      print('Products length: ${products.length}');
                      if (products.isEmpty) {
                        print('No favorite products found');
                        return const Center(
                          child: Text('У вас нет избранных товаров'),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.56,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final favoriteItem = products[index];
                          final product = favoriteItem.product;
                          final productData = product.attributes['product']
                                  as Map<String, dynamic>? ??
                              {};

                          print('\nProduct ${index + 1} Debug Info:');
                          print('FavoriteItem ID: ${favoriteItem.id}');
                          print('Product Raw Data: $product');
                          print('Product Data: $productData');

                          final productTitle = ((productData['title']
                                      as Map<String, dynamic>?)?['ru']
                                  as String?) ??
                              '';
                          final imageUrl = product.image_url;
                          final price = product.price;
                          final rating = product.rating;
                          final reviewsCount = product.reviewsCount;
                          final isFavorite = product.is_favourite;
                          final productValue = product.value;
                          final isColorable =
                              (productData['is_colorable'] as bool?) ?? false;
                          final priceRange =
                              (productData['price_range'] as List<dynamic>?)
                                  ?.map((price) => (price as num).toDouble())
                                  .toList();

                          print('Extracted Title: $productTitle');
                          print('Product Value: $productValue');
                          print('Product Price: $price');
                          print('Price Range: $priceRange');
                          print('Product Image URL: $imageUrl');
                          print('Product Rating: $rating');
                          print('Product Reviews Count: $reviewsCount');
                          print('Is Favorite: $isFavorite');
                          print('Is Colorable: $isColorable');
                          print('=========================');

                          return ProductCard(
                            imageUrl: imageUrl,
                            title: productTitle,
                            isColorable: isColorable,
                            isFavorite: isFavorite,
                            priceRange:
                                priceRange?.map((p) => p.toInt()).toList(),
                            rating: rating,
                            reviewsCount: reviewsCount,
                            weight: productValue,
                            onTap: () {
                              context.push(
                                '/products/${product.id}',
                                extra: {'initialWeight': product.value},
                              );
                            },
                            onFavoritePressed: () async {
                              try {
                                await ref
                                    .read(favoriteProductsProvider.notifier)
                                    .toggleFavorite(
                                      product.id,
                                      context,
                                      productTitle,
                                      product.is_favourite,
                                    );
                              } catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка: $error'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text('Error: $error'),
                    ),
                  ),

                  // Colors tab
                  favoriteColors.when(
                    data: (colors) {
                      if (colors.isEmpty) {
                        return const Center(
                          child: Text('У вас нет избранных цветов'),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: colors.length,
                        itemBuilder: (context, index) {
                          final color = colors[index];
                          return FavoriteDetailedColorCard(
                            color: color,
                            onTap: () {
                              // TODO: Implement color details navigation
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text('Error: $error'),
                    ),
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
