import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';
import 'package:remalux_ar/features/store/domain/models/review.dart';
import 'package:remalux_ar/features/store/presentation/providers/product_detail_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:remalux_ar/features/store/presentation/widgets/reviews_section.dart';
import 'package:remalux_ar/core/services/file_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/features/store/presentation/widgets/paint_calculator_modal.dart';
import 'package:remalux_ar/features/store/presentation/widgets/review_modal.dart';
import 'package:remalux_ar/features/store/presentation/widgets/product_detail_skeleton.dart';

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
        data: (product) => _buildProductDetail(context, product),
        loading: () => const ProductDetailSkeleton(),
        error: (error, stackTrace) => Center(
          child: Text('Ошибка при загрузке: $error'),
        ),
      ),
    );
  }

  Widget _buildProductDetail(BuildContext context, ProductDetail product) {
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
              aspectRatio: 1,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
              ),
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
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'lib/core/assets/icons/cube.svg',
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Визуализировать',
                            style: TextStyle(
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
                          product.title['ru'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Артикул: ${product.article}',
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
                            'Цвет',
                            style: GoogleFonts.ysabeau(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.white,
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFFEEEEEE),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                // TODO: Implement color selection
                              },
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: const Center(
                                  child: Text(
                                    'Выберите цвет',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.links,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Weight Selection
                        Text(
                          'Вес',
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
                                      horizontal: 16,
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
                                      '${variant.value} кг',
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
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Норма расхода: ',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '150.00 г/м2',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Расчет площади покрытия краской: ',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '6.67 кг/м2',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
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
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calculate_outlined,
                                          color: AppColors.textPrimary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Калькулятор краски',
                                          style: TextStyle(
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
                                              const Text(
                                                'Сравнить',
                                                style: TextStyle(
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
                                              const Text(
                                                'В избранное',
                                                style: TextStyle(
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
                          'О продукте',
                          style: GoogleFonts.ysabeau(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Html(
                          data: product.description['ru'] ?? '',
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
                          'Данные продукта',
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
                                      text: '${titleMap['ru']}: ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${valueMap['ru']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (measureMap != null)
                                      TextSpan(
                                        text: ' ${measureMap['ru']}',
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
                                const TextSpan(
                                  text: 'Расчет площади покрытия краской: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${((double.parse(selectedWeight!) * 1000) / product.expense).toStringAsFixed(2)} м2',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Reviews
                        Consumer(
                          builder: (context, ref, child) {
                            print(
                                '🔍 Loading reviews for product ${widget.productId}');
                            final reviewsAsync = ref.watch(
                                productReviewsProvider(widget.productId));

                            return reviewsAsync.when(
                              data: (reviewsResponse) {
                                print(
                                    '✅ Reviews loaded: ${reviewsResponse.data.length} reviews');
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Отзывы (${reviewsResponse.meta.total})',
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
                                      productTitle: product.title['ru'] ?? '',
                                      productImage: product.imageUrl,
                                    ),
                                  ],
                                );
                              },
                              loading: () {
                                print('⏳ Loading reviews...');
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              error: (error, stackTrace) {
                                print('❌ Error loading reviews: $error');
                                print('Stack trace: $stackTrace');
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Ошибка при загрузке отзывов: $error',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Certificates
                        Text(
                          'Сертификаты продукции',
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
                                    content:
                                        Text('Ошибка при открытии файла: $e'),
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
                                  const Expanded(
                                    child: Text(
                                      'Сертификат',
                                      style: TextStyle(
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
                                                  'Файл сохранен в: $filePath'),
                                              backgroundColor: Colors.green,
                                              duration:
                                                  const Duration(seconds: 5),
                                              action: SnackBarAction(
                                                label: 'Открыть',
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
                                                  'Ошибка при скачивании файла: $e'),
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
                                      'Похожие товары',
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
                                                  '/products/${product.id}',
                                                );
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
                          ? () {
                              // TODO: Implement add to cart
                            }
                          : null,
                      child: const SizedBox(
                        height: 48,
                        child: Center(
                          child: Text(
                            'В корзину',
                            style: TextStyle(
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
