import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/presentation/widgets/product_variant_item.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:remalux_ar/features/store/presentation/widgets/store_categories_grid.dart';
import 'package:remalux_ar/features/store/presentation/widgets/filters_modal.dart';
import 'package:remalux_ar/features/store/presentation/widgets/single_filter_modal.dart';
import 'package:remalux_ar/features/store/presentation/widgets/sorting_modal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remalux_ar/features/home/domain/providers/selected_color_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:remalux_ar/features/auth/domain/providers/auth_provider.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart' as auth_state;
import 'package:remalux_ar/features/profile/presentation/pages/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/features/store/presentation/providers/store_providers.dart';
import 'package:remalux_ar/features/store/presentation/widgets/single_filter_modal.dart';
import 'package:remalux_ar/features/store/presentation/widgets/sorting_modal.dart';
import 'package:remalux_ar/features/store/presentation/widgets/store_categories_grid.dart';
import 'package:remalux_ar/features/home/presentation/providers/categories_provider.dart';
import 'package:remalux_ar/features/profile/presentation/pages/profile_page.dart';

class StorePage extends ConsumerStatefulWidget {
  final int? initialCategoryId;
  final bool autoFocus;

  const StorePage({
    super.key,
    this.initialCategoryId,
    this.autoFocus = false,
  });

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force refresh products and filters
      ref.invalidate(productsProvider);
      ref.invalidate(filtersProvider);

      if (widget.initialCategoryId != null) {
        ref
            .read(selectedFiltersProvider.notifier)
            .toggleFilter(widget.initialCategoryId!, isCategory: true);
        _fetchProducts();
      }
      if (widget.autoFocus) {
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final shouldExpandHeader = _scrollController.offset < 100;
    if (shouldExpandHeader != _isHeaderExpanded) {
      setState(() {
        _isHeaderExpanded = shouldExpandHeader;
      });
    }
  }

  void _onSearchChanged(String value) {
    // Cancel any previous timer
    _debounceTimer?.cancel();

    // Start a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final productsNotifier = ref.read(productsProvider.notifier);
      final selectedFilters = ref.read(selectedFiltersProvider);
      final selectedSorting = ref.read(sortingProvider);
      final selectedCategory =
          ref.read(selectedFiltersProvider.notifier).selectedCategory;

      // Create query parameters map
      final Map<String, dynamic> queryParams = {};

      // Add search parameter if 3 or more characters
      if (value.length >= 3) {
        queryParams['searchKeyword'] = value;
      } else if (value.length < 3 && value.isNotEmpty) {
        // If less than 3 characters but not empty, don't send request
        return;
      }
      // If empty, continue without search parameter

      // Add category filter if selected
      if (selectedCategory != null) {
        queryParams['filters[product.category_id]'] =
            selectedCategory.toString();
      }

      // Add existing filter parameters
      if (selectedFilters.isNotEmpty) {
        for (final id in selectedFilters) {
          queryParams['filter_ids[$id]'] = id.toString();
        }
      }

      // Add sorting parameter if selected
      if (selectedSorting != null) {
        queryParams['order_by'] = selectedSorting;
      }

      print('Search query params: $queryParams'); // Debug print

      // Fetch products with updated parameters
      productsNotifier.fetchProducts(
        queryParams: queryParams.isEmpty ? null : queryParams,
      );
    });
  }

  void _fetchProducts() {
    final productsNotifier = ref.read(productsProvider.notifier);
    final selectedFilters = ref.read(selectedFiltersProvider);
    final selectedSorting = ref.read(sortingProvider);
    final selectedCategory =
        ref.read(selectedFiltersProvider.notifier).selectedCategory;

    // Create query parameters map
    final Map<String, dynamic> queryParams = {};

    // Add category filter if selected
    if (selectedCategory != null) {
      queryParams['filters[product.category_id]'] = selectedCategory.toString();
    }

    // Add existing filter parameters
    if (selectedFilters.isNotEmpty) {
      for (final id in selectedFilters) {
        queryParams['filter_ids[$id]'] = id.toString();
      }
    }

    // Add sorting parameter if selected
    if (selectedSorting != null) {
      queryParams['order_by'] = selectedSorting;
    }

    print('Search query params: $queryParams'); // Debug print

    // Fetch products with updated parameters
    productsNotifier.fetchProducts(
      queryParams: queryParams.isEmpty ? null : queryParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final filtersAsync = ref.watch(filtersProvider);
    final selectedColor = ref.watch(selectedColorProvider);
    final currentLocale = context.locale.languageCode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        // appBar: const CustomAppBar(
        //   title: 'Каталог',
        //   showBottomBorder: true,
        //   showFavoritesButton: true,
        // ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // Main content
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Spacer for fixed header
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _isHeaderExpanded
                          ? (470 + (selectedColor != null ? 64 : 0))
                          : (176 + (selectedColor != null ? 64 : 0)),
                    ),
                  ),

                  // Products count and sorting
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      child: Row(
                        children: [
                          Text(
                            productsAsync.when(
                              data: (response) => 'store.products_count'
                                  .tr(args: [response.meta.total.toString()]),
                              loading: () => '',
                              error: (_, __) =>
                                  'store.products_count'.tr(args: ['0']),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary.withOpacity(0.5),
                            ),
                          ),
                          productsAsync.maybeWhen(
                            loading: () => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 80,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            orElse: () => const SizedBox(),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const SortingModal(),
                              );
                            },
                            child: Consumer(
                              builder: (context, ref, child) {
                                final selectedSorting =
                                    ref.watch(sortingProvider);
                                final isActive = selectedSorting != null;

                                return Row(
                                  children: [
                                    Icon(
                                      Icons.sort,
                                      size: 16,
                                      color: isActive
                                          ? AppColors.borderDark
                                          : AppColors.textPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: isActive
                                          ? BoxDecoration(
                                              color: AppColors.backgroundLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            )
                                          : null,
                                      child: Text(
                                        'store.sorting'.tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isActive
                                              ? AppColors.borderDark
                                              : AppColors.textPrimary,
                                          fontWeight: isActive
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),

                  // Products Grid
                  productsAsync.when(
                    data: (response) {
                      if (response.data.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'store.no_products_found'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'store.try_different_filters'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        AppColors.textPrimary.withOpacity(0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.all(12),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.56,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final variant = response.data[index];
                              return GestureDetector(
                                onTap: () {
                                  final productId =
                                      (variant.attributes['product']
                                          as Map<String, dynamic>)['id'] as int;
                                  context.push(
                                    '/products/$productId',
                                    extra: {'initialWeight': variant.value},
                                  );
                                },
                                child: ProductVariantItem(
                                  variant: variant,
                                  onAddToCart: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Added ${variant.attributes['title'][currentLocale] ?? variant.attributes['title']['ru'] ?? ''} to cart'),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: response.data.length,
                          ),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.56,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductSkeleton(),
                          childCount: 6,
                        ),
                      ),
                    ),
                    error: (error, stackTrace) => SliverToBoxAdapter(
                      child: Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),
                ],
              ),

              // Fixed header with SafeArea for top
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isHeaderExpanded
                        ? (395 +
                            MediaQuery.of(context).padding.top +
                            (selectedColor != null ? 64 : 12.5))
                        : (165 +
                            MediaQuery.of(context).padding.top +
                            (selectedColor != null ? 64 : 12.5)),
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo and icons
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            height: 40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (Navigator.of(context).canPop())
                                  Positioned(
                                    left: 0,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back_ios,
                                        size: 20,
                                        color: AppColors.textPrimary,
                                      ),
                                      onPressed: () => context.pop(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final selectedCategory = ref
                                            .watch(selectedFiltersProvider
                                                .notifier)
                                            .selectedCategory;
                                        final categoriesAsync =
                                            ref.watch(categoriesProvider);
                                        final currentLocale =
                                            context.locale.languageCode;

                                        return categoriesAsync.when(
                                          data: (categories) {
                                            if (selectedCategory != null) {
                                              final category =
                                                  categories.firstWhere(
                                                (cat) =>
                                                    cat.id == selectedCategory,
                                                orElse: () => categories.first,
                                              );
                                              return Text(
                                                category.title[currentLocale] ??
                                                    category.title['ru'] ??
                                                    '',
                                                style: GoogleFonts.ysabeau(
                                                  fontSize: 23,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            } else {
                                              return SvgPicture.asset(
                                                'lib/core/assets/icons/logo.svg',
                                                height: 40,
                                              );
                                            }
                                          },
                                          loading: () => SvgPicture.asset(
                                            'lib/core/assets/icons/logo.svg',
                                            height: 40,
                                          ),
                                          error: (_, __) => SvgPicture.asset(
                                            'lib/core/assets/icons/logo.svg',
                                            height: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          context.push('/compare-products');
                                        },
                                        icon: SvgPicture.asset(
                                          'lib/core/assets/icons/scale.svg',
                                          width: 24,
                                          height: 24,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final userAsync =
                                              ref.watch(userProvider);
                                          return userAsync.when(
                                            data: (user) => IconButton(
                                              onPressed: () {
                                                if (user != null) {
                                                  context.push('/favorites');
                                                } else {
                                                  context.push('/login');
                                                }
                                              },
                                              icon: SvgPicture.asset(
                                                'lib/core/assets/icons/heart.svg',
                                                width: 24,
                                                height: 24,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  AppColors.textPrimary,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            loading: () => IconButton(
                                              onPressed: () {},
                                              icon: SvgPicture.asset(
                                                'lib/core/assets/icons/heart.svg',
                                                width: 24,
                                                height: 24,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  AppColors.textPrimary,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            error: (_, __) => IconButton(
                                              onPressed: () =>
                                                  context.push('/login'),
                                              icon: SvgPicture.asset(
                                                'lib/core/assets/icons/heart.svg',
                                                width: 24,
                                                height: 24,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  AppColors.textPrimary,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Search
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: widget.autoFocus,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'store.search_products'.tr(),
                                hintStyle: TextStyle(
                                  color: AppColors.textPrimary.withOpacity(0.5),
                                  fontSize: 15,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: SvgPicture.asset(
                                    'lib/core/assets/icons/search.svg',
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.textPrimary,
                                      BlendMode.srcIn,
                                    ),
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Categories (animated)
                        if (_isHeaderExpanded)
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isHeaderExpanded ? 1.0 : 0.0,
                              child: const SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StoreCategoriesGrid(),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Filters (always visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          DraggableScrollableSheet(
                                        initialChildSize: 0.9,
                                        maxChildSize: 0.9,
                                        minChildSize: 0.5,
                                        builder: (context, scrollController) =>
                                            const FiltersModal(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final selectedFilters = ref
                                                .watch(selectedFiltersProvider);
                                            return Container(
                                              height: 32,
                                              width: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8F8F8),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border:
                                                    selectedFilters.isNotEmpty
                                                        ? Border.all(
                                                            color: AppColors
                                                                .borderDark,
                                                            width: 1)
                                                        : null,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.tune,
                                                  size: 16,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final selectedFilters = ref
                                                .watch(selectedFiltersProvider);
                                            if (selectedFilters.isEmpty) {
                                              return const SizedBox();
                                            }

                                            return Positioned(
                                              top: -6,
                                              right: -6,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    selectedFilters.length
                                                        .toString(),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final filtersAsync =
                                        ref.watch(filtersProvider);
                                    final selectedFilters =
                                        ref.watch(selectedFiltersProvider);

                                    return filtersAsync.when(
                                      data: (filters) => Row(
                                        children: filters.map((filter) {
                                          // Count how many values of this filter are selected
                                          final selectedCount = filter.values
                                              .where((value) => selectedFilters
                                                  .contains(value.id))
                                              .length;

                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (context) => Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom:
                                                          MediaQuery.of(context)
                                                              .viewInsets
                                                              .bottom,
                                                    ),
                                                    child: SingleFilterModal(
                                                      filter: filter,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: _buildFilterButton(
                                                filter.title[currentLocale] ??
                                                    filter.title['ru'] ??
                                                    '',
                                                selectedCount > 0,
                                                selectedCount: selectedCount,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      loading: () => const SizedBox(),
                                      error: (_, __) => const SizedBox(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Selected color section
                        if (selectedColor != null)
                          Container(
                            padding: const EdgeInsets.only(
                                right: 12, left: 12, bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Color preview
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                        '0xFF${selectedColor.hex.substring(1)}')),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Color info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedColor.title[currentLocale] ??
                                            selectedColor.title['ru'] ??
                                            '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedColor.ral,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Action buttons
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8F8F8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          // TODO: Implement favorite toggle
                                        },
                                        icon: SvgPicture.asset(
                                          'lib/core/assets/icons/heart.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.textPrimary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8F8F8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          context.push('/colors');
                                        },
                                        icon: SvgPicture.asset(
                                          'lib/core/assets/icons/refresh.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.textPrimary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8F8F8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          ref
                                              .read(selectedColorProvider
                                                  .notifier)
                                              .clearColor();
                                        },
                                        icon: SvgPicture.asset(
                                          'lib/core/assets/icons/close.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.textPrimary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title, bool isExpanded,
      {int selectedCount = 0}) {
    return Container(
      padding: const EdgeInsets.only(top: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8),
              border: isExpanded
                  ? Border.all(color: AppColors.borderDark, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpanded
                        ? AppColors.borderDark
                        : AppColors.textPrimary,
                    fontWeight:
                        isExpanded ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: isExpanded
                        ? AppColors.borderDark
                        : AppColors.textPrimary,
                  ),
                ],
              ],
            ),
          ),
          if (selectedCount > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    selectedCount.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
            // Image skeleton
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            // Title skeleton
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
            // Subtitle skeleton
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
            // Price skeleton
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
            // Button skeleton
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
}
