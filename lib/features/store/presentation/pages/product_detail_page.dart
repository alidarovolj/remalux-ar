import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';
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
  String? selectedWeight;
  ProductVariant? selectedVariant;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.initialWeight;
  }

  @override
  Widget build(BuildContext context) {
    final productDetailAsync =
        ref.watch(productDetailProvider(widget.productId));
    final currentLocale = context.locale.languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'lib/core/assets/icons/scale.svg',
              width: 24,
              height: 24,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: SvgPicture.asset(
              'lib/core/assets/icons/heart.svg',
              width: 24,
              height: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: productDetailAsync.when(
        data: (product) => _buildProductDetail(context, product, currentLocale),
        loading: () => const ProductDetailSkeleton(),
        error: (error, stackTrace) => Center(
          child:
              Text('store.product.reviews_error'.tr(args: [error.toString()])),
        ),
      ),
    );
  }

  Widget _buildProductDetail(
      BuildContext context, ProductDetail product, String currentLocale) {
    // Set initial variant if weight is selected but variant is not
    if (selectedWeight != null && selectedVariant == null) {
      selectedVariant = product.productVariants.firstWhere(
          (v) => v.value == selectedWeight,
          orElse: () => product.productVariants.first);
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: product.isColorable ? 1.5 : 1,
              child: product.isColorable
                  ? Consumer(
                      builder: (context, ref, child) {
                        final selectedColor = ref.watch(selectedColorProvider);
                        return Container(
                          color: selectedColor != null
                              ? Color(int.parse(
                                  '0xFF${selectedColor.hex.substring(1)}'))
                              : Colors.white,
                          child: PageView.builder(
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return Image.asset(
                                'lib/core/assets/images/store/${index + 1}.png',
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        );
                      },
                    )
                  : Image.network(product.imageUrl,
                      width: double.infinity, fit: BoxFit.cover),
            ),

            // AR View Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'lib/core/assets/icons/cube.svg',
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
                        if (product.isColorable) ...[
                          Image.asset(
                            'lib/core/assets/images/color_wheel.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          product.title[currentLocale] ??
                              product.title['ru'] ??
                              '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'store.product.article'.tr(args: [product.article]),
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
                            if (selectedVariant?.discount_price != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${selectedVariant!.discount_price!.toInt()} ₸',
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textPrimary.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Color Selection
                        if (product.isColorable) ...[
                          Text(
                            'store.product.color'.tr(),
                            style: GoogleFonts.ysabeau(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const ColorSelection(),
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
                            children: product.productVariants.map((variant) {
                              final isSelected =
                                  selectedWeight == variant.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedWeight = variant.value;
                                      selectedVariant = variant;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.borderDark
                                            : const Color(0xFFF8F8F8),
                                      ),
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'store.weight_value'
                                          .tr(args: [variant.value]),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Usage Rate
                        Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'store.product.usage_rate'
                                          .tr(args: ['150.00']),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
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
                                      text: 'store.product.coverage_calculation'
                                          .tr(args: ['6.67']),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
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
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom,
                                        ),
                                        child: PaintCalculatorModal(
                                          expense: product.expense,
                                          selectedWeight: selectedWeight ??
                                              product
                                                  .productVariants.first.value,
                                        ),
                                      ),
                                    ).then((result) {
                                      if (result != null) {
                                        setState(() {
                                          if (selectedWeight == null) {
                                            selectedWeight = product
                                                .productVariants.first.value;
                                            selectedVariant =
                                                product.productVariants.first;
                                          }
                                          quantity = result as int;
                                        });
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.calculate_outlined,
                                          color: AppColors.textPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'store.product.paint_calculator'.tr(),
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          // TODO: Implement compare functionality
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF8F8F8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: SvgPicture.asset(
                                                  'lib/core/assets/icons/scale.svg',
                                                  width: 24,
                                                  height: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'store.product.compare'.tr(),
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          // TODO: Implement favorite functionality
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF8F8F8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: SvgPicture.asset(
                                                  'lib/core/assets/icons/heart.svg',
                                                  width: 24,
                                                  height: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'store.product.add_to_favorites'
                                                    .tr(),
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
                          data: product.description[currentLocale] ??
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: product.filterData.map((filter) {
                            final titleMap =
                                filter['title'] as Map<String, dynamic>;
                            final valueMap =
                                filter['value'] as Map<String, dynamic>;
                            final measureMap =
                                filter['measure'] as Map<String, dynamic>?;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${titleMap[currentLocale] ?? titleMap['ru']}: ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${valueMap[currentLocale] ?? valueMap['ru']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (measureMap != null)
                                      TextSpan(
                                        text:
                                            ' ${measureMap[currentLocale] ?? measureMap['ru']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        if (selectedWeight != null)
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'store.product.coverage_calculation'
                                      .tr(args: [
                                    ((double.parse(selectedWeight!) * 1000) /
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
                                productReviewsProvider(widget.productId));

                            return reviewsAsync.when(
                              data: (reviewsResponse) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'store.product.reviews_count'.tr(args: [
                                        reviewsResponse.meta.total.toString()
                                      ]),
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ReviewsSection(
                                      reviews: reviewsResponse.data,
                                      totalReviews: reviewsResponse.meta.total,
                                      productTitle:
                                          product.title[currentLocale] ??
                                              product.title['ru'] ??
                                              '',
                                      productImage: product.imageUrl,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, stackTrace) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'store.product.reviews_error'
                                        .tr(args: [error.toString()]),
                                    style: const TextStyle(color: Colors.red),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('store.product.file_error'
                                        .tr(args: [e.toString()])),
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
                                      'store.product.certificate'.tr(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      try {
                                        final filePath =
                                            await FileService.downloadPdfAsset(
                                          'lib/core/assets/pdf/sert.pdf',
                                          'certificate.pdf',
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'store.product.file_saved'
                                                      .tr(args: [filePath])),
                                              backgroundColor: Colors.green,
                                              duration:
                                                  const Duration(seconds: 5),
                                              action: SnackBarAction(
                                                label:
                                                    'store.product.open'.tr(),
                                                textColor: Colors.white,
                                                onPressed: () async {
                                                  final url =
                                                      Uri.file(filePath);
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(url);
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'store.product.download_error'
                                                      .tr(args: [
                                                e.toString()
                                              ])),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    behavior: HitTestBehavior.opaque,
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
                                similarProductsProvider(widget.productId));

                            return similarProductsAsync.when(
                              data: (similarProducts) {
                                if (similarProducts.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'store.product.similar_products'.tr(),
                                      style: GoogleFonts.ysabeau(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 325,
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        scrollDirection: Axis.horizontal,
                                        itemCount: similarProducts.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final product =
                                              similarProducts[index];
                                          final variant =
                                              product.productVariants.first;
                                          return SizedBox(
                                            width: 240,
                                            child: GestureDetector(
                                              onTap: () {
                                                context.pushReplacement(
                                                    '/products/${product.id}');
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFF3B4D8B)
                                                          .withOpacity(0.1),
                                                      offset:
                                                          const Offset(0, 1),
                                                      blurRadius: 5,
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          const BorderRadius
                                                              .vertical(
                                                              top: Radius
                                                                  .circular(
                                                                      12)),
                                                      child: Image.network(
                                                        product.imageUrl,
                                                        height: 200,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            product.title[
                                                                    currentLocale] ??
                                                                product.title[
                                                                    'ru'] ??
                                                                '',
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              color: AppColors
                                                                  .textPrimary,
                                                              height: 1.2,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Row(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: const Color(
                                                                      0xFFF8F8F8),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child:
                                                                    const Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .star,
                                                                      color: Colors
                                                                          .amber,
                                                                      size: 14,
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            4),
                                                                    Text(
                                                                      '5.0 (4)',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: AppColors
                                                                            .textPrimary,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            '${variant.price.toInt()} - ${variant.price.toInt() + 2000}₸',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColors
                                                                  .textPrimary,
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
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, stackTrace) =>
                                  const SizedBox.shrink(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
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
                          child: Text(
                            quantity.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
                                final selectedColor =
                                    ref.read(selectedColorProvider);
                                await ref.read(cartProvider.notifier).addToCart(
                                      productVariantId: selectedVariant!.id,
                                      quantity: quantity,
                                      colorId: selectedColor?.id,
                                    );

                                if (mounted) {
                                  // Показываем snackbar
                                  CustomSnackBar.show(
                                    context,
                                    message: 'store.product.added_to_cart'.tr(),
                                    type: SnackBarType.success,
                                  );

                                  // Показываем модальное окно
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => AddToCartSuccessModal(
                                      productTitle:
                                          product.title[currentLocale] ??
                                              product.title['ru'] ??
                                              '',
                                      productImage: product.imageUrl,
                                      quantity: quantity,
                                      price: (selectedVariant!.price * quantity)
                                          .toString(),
                                    ),
                                  );
                                }
                              } catch (error) {
                                if (mounted) {
                                  CustomSnackBar.show(
                                    context,
                                    message: 'store.product.add_to_cart_error'
                                        .tr(args: [error.toString()]),
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
    );
  }
}
