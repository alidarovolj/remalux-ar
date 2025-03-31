import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/widgets/product_card.dart';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';
import 'package:remalux_ar/core/widgets/favorite_detailed_color_card.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:remalux_ar/features/store/presentation/widgets/product_variant_item.dart';
import 'package:remalux_ar/features/home/domain/providers/detailed_colors_provider.dart';
import 'package:remalux_ar/features/home/data/models/detailed_color_model.dart';
import 'package:remalux_ar/core/widgets/detailed_color_card.dart';
import 'package:remalux_ar/features/home/presentation/widgets/color_detail_modal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

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

  Future<void> _refreshFavorites() async {
    print('🔄 Force refreshing favorites');
    final token = await StorageService.getToken();
    if (token != null) {
      try {
        print('📱 Starting favorites refresh');
        await Future.wait([
          ref.read(favoriteProductsProvider.notifier).loadFavoriteProducts(),
          ref.read(favoriteColorsProvider.notifier).loadFavoriteColors(),
        ]);
        print('✅ Favorites refresh completed successfully');
      } catch (error) {
        print('❌ Favorites refresh failed: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('favorites.error.refresh'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('⚠️ No token found, skipping favorites refresh');
    }
  }

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
    print('📱 FavoritesPage initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFavorites();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshFavorites();
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
          title: 'favorites.title'.tr(),
          showBottomBorder: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
                          Text(
                            'favorites.tabs.products'.tr(),
                            style: const TextStyle(
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
                          Text(
                            'favorites.tabs.colors'.tr(),
                            style: const TextStyle(
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
                      if (products.isEmpty) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Image.asset(
                                'lib/core/assets/images/no-products.png',
                                width: 80,
                                height: 80,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'favorites.empty_products.title'.tr(),
                                style: GoogleFonts.ysabeau(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'favorites.empty_products.description'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                label:
                                    'favorites.empty_products.to_catalog'.tr(),
                                isFullWidth: false,
                                onPressed: () {
                                  context.go('/store');
                                },
                              ),
                              const SizedBox(height: 32),
                              _buildRecommendedProducts(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
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
                                final productData =
                                    product.attributes['product']
                                            as Map<String, dynamic>? ??
                                        {};

                                final productTitle = ((productData['title']
                                                as Map<String, dynamic>?)?[
                                            context.locale.languageCode]
                                        as String?) ??
                                    '';
                                final imageUrl = product.image_url;
                                final rating = product.rating;
                                final reviewsCount = product.reviewsCount;
                                final isFavorite = product.is_favourite;
                                final productValue = product.value;
                                final isColorable =
                                    (productData['is_colorable'] as bool?) ??
                                        false;
                                final priceRange = (productData['price_range']
                                        as List<dynamic>?)
                                    ?.map((price) => (price as num).toDouble())
                                    .toList();

                                return ProductCard(
                                  imageUrl: imageUrl,
                                  title: productTitle,
                                  isColorable: isColorable,
                                  isFavorite: isFavorite,
                                  priceRange: priceRange
                                      ?.map((p) => p.toInt())
                                      .toList(),
                                  rating: rating,
                                  reviewsCount: reviewsCount,
                                  weight: productValue,
                                  onTap: () {
                                    context.push('/products/${product.id}');
                                  },
                                  onFavoritePressed: () async {
                                    try {
                                      await ref
                                          .read(
                                              favoriteProductsProvider.notifier)
                                          .toggleFavorite(
                                            product.id,
                                            context,
                                            productTitle,
                                            product.is_favourite,
                                          );
                                    } catch (error) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Ошибка: $error'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            _buildRecommendedProducts(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                    loading: () => SingleChildScrollView(
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.56,
                            ),
                            itemCount: 6,
                            itemBuilder: (context, index) =>
                                const _ProductSkeletonCard(),
                          ),
                          const SizedBox(height: 32),
                          _buildRecommendedProducts(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'favorites.error.products.title'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            label: 'favorites.error.products.try_again'.tr(),
                            isFullWidth: false,
                            onPressed: () {
                              ref
                                  .read(favoriteProductsProvider.notifier)
                                  .loadFavoriteProducts();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Colors tab
                  favoriteColors.when(
                    data: (colors) {
                      if (colors.isEmpty) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'lib/core/assets/images/no-colors.png',
                                      width: 80,
                                      height: 80,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'favorites.empty_colors.title'.tr(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'favorites.empty_colors.description'.tr(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    CustomButton(
                                      label: 'favorites.empty_colors.to_colors'
                                          .tr(),
                                      isFullWidth: false,
                                      onPressed: () {
                                        context.go('/colors');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildRecommendedColors(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
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
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => ColorDetailModal(
                                        color: DetailedColorModel(
                                          id: color.color.id,
                                          hex: color.color.hex,
                                          title: color.color.title,
                                          ral: color.color.ral,
                                          isFavourite: color.color.isFavourite,
                                          catalog: Catalog(
                                            id: color.color.catalog.id,
                                            title: color.color.catalog.title,
                                            code: color.color.catalog.code,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            _buildRecommendedColors(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                    loading: () => GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) =>
                          const _ColorSkeletonCard(),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'favorites.error.colors.title'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            label: 'favorites.error.colors.try_again'.tr(),
                            isFullWidth: false,
                            onPressed: () {
                              ref
                                  .read(favoriteColorsProvider.notifier)
                                  .loadFavoriteColors();
                            },
                          ),
                        ],
                      ),
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

  Widget _buildRecommendedProducts() {
    final productsAsync = ref.watch(productsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'favorites.recommended.products'.tr(),
            style: GoogleFonts.ysabeau(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        productsAsync.when(
          data: (response) {
            if (response.data.isEmpty) {
              return Center(
                child: Text('favorites.recommended.no_products'.tr()),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.56,
              ),
              itemCount: response.data.length,
              itemBuilder: (context, index) {
                final variant = response.data[index];
                return GestureDetector(
                  onTap: () {
                    final productId = (variant.attributes['product']
                        as Map<String, dynamic>)['id'] as int;
                    context.push('/products/$productId');
                  },
                  child: ProductVariantItem(
                    variant: variant,
                    onAddToCart: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'store.added_to_cart'.tr(args: [
                              variant.attributes['title']
                                  [context.locale.languageCode]
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.56,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => _buildProductSkeleton(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 20,
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedColors() {
    final colorsAsync = ref.watch(detailedColorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'favorites.recommended.colors'.tr(),
            style: GoogleFonts.ysabeau(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        colorsAsync.when(
          data: (colors) {
            if (colors.isEmpty) {
              return Center(
                child: Text('favorites.recommended.no_colors'.tr()),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: colors.length > 4 ? 4 : colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                return DetailedColorCard(
                  color: color,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ColorDetailModal(color: color),
                    );
                  },
                  onFavoritePressed: () async {
                    await ref
                        .read(favoriteColorsProvider.notifier)
                        .toggleFavorite(
                          color.id,
                          context,
                          color.title['ru'] ?? '',
                          color.isFavourite,
                        );
                  },
                );
              },
            );
          },
          loading: () => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => _buildColorSkeleton(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSkeletonCard extends StatelessWidget {
  const _ProductSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 24,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSkeletonCard extends StatelessWidget {
  const _ColorSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
