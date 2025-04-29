import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart'
    hide ProductVariant;
import 'package:remalux_ar/features/store/domain/models/product_detail.dart'
    as models show ProductVariant;
import 'package:remalux_ar/features/store/presentation/providers/product_detail_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:remalux_ar/features/store/presentation/widgets/reviews_section.dart';
import 'package:remalux_ar/core/services/file_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/features/store/presentation/widgets/paint_calculator_modal.dart';
import 'package:remalux_ar/features/store/presentation/widgets/product_detail_skeleton.dart';
import 'package:remalux_ar/features/home/domain/providers/selected_color_provider.dart';
import 'package:remalux_ar/features/store/presentation/widgets/color_selection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remalux_ar/features/cart/domain/providers/cart_provider.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:remalux_ar/features/store/presentation/widgets/add_to_cart_success_modal.dart';
import 'package:remalux_ar/features/store/presentation/providers/compare_products_provider.dart';
import 'package:remalux_ar/features/store/domain/providers/product_color_selection_provider.dart';
import 'package:remalux_ar/core/services/storage_service.dart';
import 'package:remalux_ar/core/widgets/auth_required_modal.dart';
import 'dart:async';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final int productId;
  final String? initialWeight;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initialWeight,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late ScrollController _scrollController;
  bool _showSafeArea = false;
  String? selectedWeight;
  models.ProductVariant? selectedVariant;
  int quantity = 1;
  final PageController _pageController = PageController();
  Timer? _timer;
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _startAutoSlide();

    // Always set the initial quantity to 1
    quantity = 1;
    _quantityController.text = "1";

    // Set initial weight if provided
    if (widget.initialWeight != null) {
      selectedWeight = widget.initialWeight;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Reset quantity to 1 when dependencies change
    setState(() {
      quantity = 1;
      _quantityController.text = "1";
    });

    // Set selectedVariant based on selectedWeight after dependencies are initialized
    if (selectedWeight != null) {
      final productDetailAsync =
          ref.read(productDetailProvider(widget.productId));
      productDetailAsync.whenData((product) {
        final variant = product.productVariants.firstWhere(
          (v) => v.weight.toString() == selectedWeight,
          orElse: () => product.productVariants.first,
        );
        setState(() {
          selectedVariant = variant;
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    _pageController.dispose();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showSafeArea = _scrollController.offset > 100;
    if (showSafeArea != _showSafeArea) {
      setState(() {
        _showSafeArea = showSafeArea;
      });
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage >= 5) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final productDetailAsync =
        ref.watch(productDetailProvider(widget.productId));

    // Set selectedVariant when product data is loaded and initialWeight is present
    productDetailAsync.whenData((product) {
      if (selectedWeight != null && selectedVariant == null) {
        final variant = product.productVariants.firstWhere(
          (v) => v.weight.toString() == selectedWeight,
          orElse: () => product.productVariants.first,
        );
        setState(() {
          selectedVariant = variant;
        });
      }
    });

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textIconsSecondary),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final productDetailAsync =
                    ref.watch(productDetailProvider(widget.productId));
                return productDetailAsync.when(
                  data: (product) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: SvgPicture.asset(
                              'lib/core/assets/icons/scale.svg',
                              colorFilter: const ColorFilter.mode(
                                AppColors.textIconsSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () {
                              ref
                                  .read(compareProductsProvider.notifier)
                                  .addProduct(product);
                              CustomSnackBar.show(
                                context,
                                message: 'store.product.added_to_compare'.tr(),
                                type: SnackBarType.success,
                              );
                              context.push('/compare-products');
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'lib/core/assets/icons/heart.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.textIconsSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () async {
                        // Check authentication
                        final token = await StorageService.getToken();
                        if (token == null) {
                          if (mounted) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AuthRequiredModal(),
                            );
                          }
                          return;
                        }

                        // User is authenticated, navigate to favorites
                        context.push('/favorites');
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            productDetailAsync.when(
              data: (product) => Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Product Image
                        Stack(
                          children: [
                            SizedBox(
                              height: 400,
                              width: double.infinity,
                              child: product.isColorable
                                  ? Consumer(
                                      builder: (context, ref, child) {
                                        final selectedColor =
                                            ref.watch(selectedColorProvider);
                                        return Container(
                                          color: selectedColor != null
                                              ? Color(int.parse(
                                                  '0xFF${selectedColor.hex.substring(1)}'))
                                              : Colors.white,
                                          alignment: Alignment.center,
                                          child: PageView.builder(
                                            controller: _pageController,
                                            itemCount: 5,
                                            itemBuilder: (context, index) {
                                              return SizedBox(
                                                width: double.infinity,
                                                height: double.infinity,
                                                child: Image.asset(
                                                  'lib/core/assets/images/store/${index + 1}.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    )
                                  : Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Image.network(
                                        product.imageUrl,
                                        width: double.infinity,
                                        height: 300,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {},
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                'lib/core/assets/images/cube.png',
                                                width: 32,
                                                height: 32,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'store.product.visualize'.tr(),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Product Info Container with all content
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B4D8B).withOpacity(0.1),
                                offset: const Offset(0, 1),
                                blurRadius: 5,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Info
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product title
                                    // if (product.isColorable == true) ...[
                                    //   Image.asset(
                                    //     'lib/core/assets/images/color_wheel.png',
                                    //     width: 24,
                                    //     height: 24,
                                    //   ),
                                    //   const SizedBox(height: 8),
                                    // ],
                                    Text(
                                      product.title[currentLocale] ??
                                          product.title['ru'] ??
                                          '',
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'store.product.article'
                                          .tr(args: [product.article]),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Price
                                    Row(
                                      children: [
                                        Text(
                                          selectedVariant != null
                                              ? '${selectedVariant!.price.toInt()} ₸'
                                              : '${product.productVariants.map((v) => v.price).reduce((a, b) => a < b ? a : b).toInt()} - ${product.productVariants.map((v) => v.price).reduce((a, b) => a > b ? a : b).toInt()} ₸',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (selectedVariant?.discount_price !=
                                            null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '${selectedVariant!.discount_price!.toInt()} ₸',
                                            style: TextStyle(
                                              fontSize: 16,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: AppColors.textPrimary
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Color Selection
                                    if (product.isColorable == true) ...[
                                      Text(
                                        'store.product.color'.tr(),
                                        style: GoogleFonts.ysabeau(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            await ref
                                                .read(
                                                    productColorSelectionProvider
                                                        .notifier)
                                                .setProduct(product,
                                                    initialWeight:
                                                        selectedWeight);

                                            if (context.mounted) {
                                              context.push('/colors', extra: {
                                                'productId': product.id,
                                                'fromProductDetail': true,
                                              });
                                            }
                                          } catch (e) {
                                            print('Error saving product: $e');
                                          }
                                        },
                                        child: ColorSelection(
                                          product: product,
                                          initialWeight: selectedWeight,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],

                                    // Weight Selection
                                    Text(
                                      'store.product.weight'.tr(),
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: product.productVariants
                                                .map((variant) {
                                              final isSelected = selectedWeight ==
                                                      variant.weight
                                                          .toString() ||
                                                  (selectedWeight != null &&
                                                      double.parse(
                                                              selectedWeight!) ==
                                                          variant.weight);
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedWeight = variant
                                                          .weight
                                                          .toString();
                                                      selectedVariant = variant;
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? AppColors
                                                                .borderDark
                                                            : const Color(
                                                                0xFFF8F8F8),
                                                      ),
                                                      color: AppColors
                                                          .backgroundLight,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      'store.weight_value'.tr(
                                                          args: [
                                                            variant.weight
                                                                .toString()
                                                          ]),
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList() ??
                                            [],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Usage Rate
                                    Container(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      'store.product.usage_rate_prefix'
                                                          .tr(),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${product.expense.toString()} ',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      'store.product.usage_rate_suffix'
                                                          .tr(),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      'store.product.coverage_calculation_prefix'
                                                          .tr(),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${(selectedWeight != null ? ((double.parse(selectedWeight!) * 1000) / product.expense) : (product.productVariants.first.weight * 1000 / product.expense)).toStringAsFixed(2)} ',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      'store.product.coverage_calculation_suffix'
                                                          .tr(),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Material(
                                            color: const Color(0xFFF8F8F8),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: InkWell(
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
                                                    child: PaintCalculatorModal(
                                                      expense: product.expense,
                                                      selectedWeight:
                                                          selectedWeight ??
                                                              product
                                                                  .productVariants
                                                                  .first
                                                                  .weight
                                                                  .toString(),
                                                    ),
                                                  ),
                                                ).then((result) {
                                                  if (result != null) {
                                                    setState(() {
                                                      if (selectedWeight ==
                                                          null) {
                                                        selectedWeight = product
                                                            .productVariants
                                                            .first
                                                            .weight
                                                            .toString();
                                                        selectedVariant =
                                                            product
                                                                .productVariants
                                                                .first;
                                                      }
                                                      quantity = result as int;
                                                      _quantityController.text =
                                                          quantity.toString();
                                                    });
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.calculate_outlined,
                                                      color:
                                                          AppColors.textPrimary,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'store.product.paint_calculator'
                                                          .tr(),
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      ref
                                                          .read(
                                                              compareProductsProvider
                                                                  .notifier)
                                                          .addProduct(product);
                                                      CustomSnackBar.show(
                                                        context,
                                                        message:
                                                            'store.product.added_to_compare'
                                                                .tr(),
                                                        type: SnackBarType
                                                            .success,
                                                      );
                                                      context.push(
                                                          '/compare-products');
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            width: 44,
                                                            height: 44,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                            decoration:
                                                                const BoxDecoration(
                                                              color: Color(
                                                                  0xFFF8F8F8),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: SvgPicture
                                                                .asset(
                                                              'lib/core/assets/icons/scale.svg',
                                                              width: 24,
                                                              height: 24,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Text(
                                                            'store.product.compare'
                                                                .tr(),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () async {
                                                      // Проверка авторизации
                                                      final token =
                                                          await StorageService
                                                              .getToken();
                                                      if (token == null) {
                                                        if (mounted) {
                                                          showModalBottomSheet(
                                                            context: context,
                                                            isScrollControlled:
                                                                true,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            builder: (context) =>
                                                                const AuthRequiredModal(),
                                                          );
                                                        }
                                                        return;
                                                      }

                                                      // Добавляем в избранное
                                                      try {
                                                        await ref
                                                            .read(
                                                                favoriteProductsProvider
                                                                    .notifier)
                                                            .toggleFavorite(
                                                              product.id,
                                                              context,
                                                              product.title[context
                                                                      .locale
                                                                      .languageCode] ??
                                                                  product.title[
                                                                      'ru'] ??
                                                                  '',
                                                              false, // Мы не знаем текущий статус избранного
                                                            );
                                                      } catch (error) {
                                                        // Ошибка уже обработана в toggleFavorite
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            width: 44,
                                                            height: 44,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                            decoration:
                                                                const BoxDecoration(
                                                              color: Color(
                                                                  0xFFF8F8F8),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: SvgPicture
                                                                .asset(
                                                              'lib/core/assets/icons/heart.svg',
                                                              width: 24,
                                                              height: 24,
                                                              colorFilter:
                                                                  const ColorFilter
                                                                      .mode(
                                                                AppColors
                                                                    .textPrimary,
                                                                BlendMode.srcIn,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Text(
                                                            'store.product.add_to_favorites'
                                                                .tr(),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Description
                                    Text(
                                      'store.product.about_product'.tr(),
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Html(
                                      data:
                                          product.description[currentLocale] ??
                                              product.description['ru'] ??
                                              '',
                                      style: {
                                        "body": Style(
                                          fontSize: FontSize(14),
                                          color: AppColors.textPrimary,
                                          lineHeight: const LineHeight(1.5),
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                        "p": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                        ),
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Usage Area
                                    Text(
                                      'store.product.product_data'.tr(),
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: product.filterData
                                              .map((filter) {
                                            final titleMap = filter['title']
                                                as Map<String, dynamic>;
                                            final valueMap = filter['value']
                                                as Map<String, dynamic>;
                                            final measureMap = filter['measure']
                                                as Map<String, dynamic>?;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '${titleMap[currentLocale] ?? titleMap['ru']}: ',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '${valueMap[currentLocale] ?? valueMap['ru']}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                    if (measureMap != null)
                                                      TextSpan(
                                                        text:
                                                            ' ${measureMap[currentLocale] ?? measureMap['ru']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList() ??
                                          [],
                                    ),
                                    const SizedBox(height: 24),
                                    if (selectedWeight != null)
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  'store.product.coverage_calculation'
                                                      .tr(args: [
                                                ((double.parse(selectedWeight!) *
                                                            1000) /
                                                        product.expense)
                                                    .toStringAsFixed(2)
                                              ]),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 24),

                                    // Reviews
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final reviewsAsync = ref.watch(
                                            productReviewsProvider(
                                                widget.productId));

                                        return reviewsAsync.when(
                                          data: (reviewsResponse) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'store.product.reviews_count'
                                                      .tr(args: [
                                                    reviewsResponse.meta.total
                                                        .toString()
                                                  ]),
                                                  style: GoogleFonts.ysabeau(
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                ReviewsSection(
                                                  reviews: reviewsResponse.data,
                                                  totalReviews: reviewsResponse
                                                      .meta.total,
                                                  productTitle: product.title[
                                                          currentLocale] ??
                                                      product.title['ru'] ??
                                                      '',
                                                  productImage:
                                                      product.imageUrl,
                                                ),
                                              ],
                                            );
                                          },
                                          loading: () => const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                          error: (error, stackTrace) => Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                'store.product.reviews_error'
                                                    .tr(args: [
                                                  error.toString()
                                                ]),
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Certificates
                                    Text(
                                      'store.product.certificates'.tr(),
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Material(
                                      color: const Color(0xFFF8F8F8),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () async {
                                          try {
                                            await FileService.openPdfAsset(
                                                'lib/core/assets/pdf/sert.pdf');
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'store.product.file_error'
                                                        .tr(args: [
                                                  e.toString()
                                                ])),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                'lib/core/assets/icons/file-shield.svg',
                                                width: 24,
                                                height: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'store.product.certificate'
                                                      .tr(),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () async {
                                                  try {
                                                    final filePath =
                                                        await FileService
                                                            .downloadPdfAsset(
                                                      'lib/core/assets/pdf/sert.pdf',
                                                      'certificate.pdf',
                                                    );
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'store.product.file_saved'
                                                                  .tr(args: [
                                                            filePath
                                                          ])),
                                                          backgroundColor:
                                                              Colors.green,
                                                          duration:
                                                              const Duration(
                                                                  seconds: 5),
                                                          action:
                                                              SnackBarAction(
                                                            label:
                                                                'store.product.open'
                                                                    .tr(),
                                                            textColor:
                                                                Colors.white,
                                                            onPressed:
                                                                () async {
                                                              final url =
                                                                  Uri.file(
                                                                      filePath);
                                                              if (await canLaunchUrl(
                                                                  url)) {
                                                                await launchUrl(
                                                                    url);
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'store.product.download_error'
                                                                  .tr(args: [
                                                            e.toString()
                                                          ])),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                child: SvgPicture.asset(
                                                  'lib/core/assets/icons/download.svg',
                                                  width: 24,
                                                  height: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Similar Products
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final similarProductsAsync = ref.watch(
                                            similarProductsProvider(
                                                widget.productId));

                                        return similarProductsAsync.when(
                                          data: (similarProducts) {
                                            if (similarProducts.isEmpty) {
                                              return const SizedBox.shrink();
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'store.product.similar_products'
                                                      .tr(),
                                                  style: GoogleFonts.ysabeau(
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                SizedBox(
                                                  height: 340,
                                                  child: ListView.separated(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        similarProducts.length,
                                                    separatorBuilder:
                                                        (context, index) =>
                                                            const SizedBox(
                                                                width: 12),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final product =
                                                          similarProducts[
                                                              index];
                                                      final variant = product
                                                          .productVariants
                                                          .first;
                                                      return SizedBox(
                                                        width: 240,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            context.push(
                                                                '/products/${product.id}');
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: const Color(
                                                                          0xFF3B4D8B)
                                                                      .withOpacity(
                                                                          0.1),
                                                                  offset:
                                                                      const Offset(
                                                                          0, 1),
                                                                  blurRadius: 5,
                                                                  spreadRadius:
                                                                      0,
                                                                ),
                                                              ],
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius: const BorderRadius
                                                                      .vertical(
                                                                      top: Radius
                                                                          .circular(
                                                                              12)),
                                                                  child: Image
                                                                      .network(
                                                                    product
                                                                        .imageUrl,
                                                                    height: 200,
                                                                    width: double
                                                                        .infinity,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          12),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        product.title[currentLocale] ??
                                                                            product.title['ru'] ??
                                                                            '',
                                                                        maxLines:
                                                                            2,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                          color:
                                                                              AppColors.textPrimary,
                                                                          height:
                                                                              1.2,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              8),
                                                                      Row(
                                                                        children: [
                                                                          Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: const Color(0xFFF8F8F8),
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                            child:
                                                                                const Row(
                                                                              children: [
                                                                                Icon(
                                                                                  Icons.star,
                                                                                  color: Colors.amber,
                                                                                  size: 14,
                                                                                ),
                                                                                SizedBox(width: 4),
                                                                                Text(
                                                                                  '5.0 (4)',
                                                                                  style: TextStyle(
                                                                                    fontSize: 12,
                                                                                    color: AppColors.textPrimary,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              8),
                                                                      Text(
                                                                        '${variant.price.toInt()} - ${variant.price.toInt() + 2000}₸',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                          color:
                                                                              AppColors.textPrimary,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                          loading: () => const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                          error: (error, stackTrace) =>
                                              const SizedBox.shrink(),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 70),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 12,
                        bottom: 12 + MediaQuery.of(context).padding.bottom,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 48,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8F8F8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() {
                                          quantity--;
                                          _quantityController.text =
                                              quantity.toString();
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: InkWell(
                                      onTap: () {
                                        // Set text selection position after a frame has been rendered
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          _quantityController.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: _quantityController
                                                    .text.length),
                                          );
                                        });
                                        _quantityFocusNode.requestFocus();
                                      },
                                      child: TextField(
                                        controller: _quantityController,
                                        focusNode: _quantityFocusNode,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        onChanged: (value) {
                                          final parsedValue =
                                              int.tryParse(value);
                                          if (parsedValue != null &&
                                              parsedValue > 0) {
                                            setState(() {
                                              quantity = parsedValue;
                                            });
                                          } else if (value.isEmpty) {
                                            // If field is empty, reset to 1 after a brief delay
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 100), () {
                                              if (_quantityController
                                                  .text.isEmpty) {
                                                setState(() {
                                                  quantity = 1;
                                                  _quantityController.text =
                                                      "1";
                                                });
                                              }
                                            });
                                          }
                                        },
                                        onSubmitted: (value) {
                                          final parsedValue =
                                              int.tryParse(value);
                                          if (parsedValue == null ||
                                              parsedValue <= 0) {
                                            setState(() {
                                              quantity = 1;
                                              _quantityController.text = "1";
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8F8F8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        quantity++;
                                        _quantityController.text =
                                            quantity.toString();
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Material(
                              color: selectedWeight != null
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: selectedWeight != null
                                    ? () async {
                                        try {
                                          // Check if user is authenticated
                                          final token =
                                              await StorageService.getToken();

                                          if (token == null) {
                                            // User is not authenticated, show auth required modal
                                            if (mounted) {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (context) =>
                                                    const AuthRequiredModal(),
                                              );
                                            }
                                            return;
                                          }

                                          // User is authenticated, proceed with adding to cart
                                          final selectedColor =
                                              ref.read(selectedColorProvider);
                                          await ref
                                              .read(cartProvider.notifier)
                                              .addToCart(
                                                productVariantId:
                                                    selectedVariant!.id,
                                                quantity: quantity,
                                                colorId: selectedColor?.id,
                                              );

                                          if (mounted) {
                                            // Показываем snackbar
                                            CustomSnackBar.show(
                                              context,
                                              message:
                                                  'store.added_to_cart'.tr(),
                                              type: SnackBarType.success,
                                            );

                                            // Показываем модальное окно
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (context) =>
                                                  AddToCartSuccessModal(
                                                productTitle: product
                                                        .title[currentLocale] ??
                                                    product.title['ru'] ??
                                                    '',
                                                productImage: product.imageUrl,
                                                quantity: quantity,
                                                price: (selectedVariant!.price *
                                                        quantity)
                                                    .toString(),
                                              ),
                                            );
                                          }
                                        } catch (error) {
                                          if (mounted) {
                                            CustomSnackBar.show(
                                              context,
                                              message:
                                                  'store.product.add_to_cart_error'
                                                      .tr(args: [
                                                error.toString()
                                              ]),
                                              type: SnackBarType.error,
                                            );
                                          }
                                        }
                                      }
                                    : null,
                                child: SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: Text(
                                      'store.product.add_to_cart'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const ProductDetailSkeleton(),
              error: (error, stackTrace) => Center(
                child: Text(
                    'store.product.reviews_error'.tr(args: [error.toString()])),
              ),
            ),
            // SafeArea overlay
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showSafeArea ? MediaQuery.of(context).padding.top : 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _showSafeArea ? 10 : 0,
                    sigmaY: _showSafeArea ? 10 : 0,
                  ),
                  child: Container(
                    color: Colors.white.withOpacity(_showSafeArea ? 0.95 : 0.0),
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
