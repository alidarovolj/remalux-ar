import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/store/domain/models/product_detail.dart';
import 'package:remalux_ar/features/store/presentation/providers/compare_products_provider.dart';
import 'package:go_router/go_router.dart';

class CompareProductsPage extends ConsumerWidget {
  const CompareProductsPage({super.key});

  String _getFilterValue(
      ProductDetail product, String key, String currentLocale) {
    final filter = product.filterData.firstWhere(
      (filter) => filter['key'] == key,
      orElse: () => {
        'value': {currentLocale: '-', 'ru': '-'}
      },
    );

    final value = (filter['value'] as Map<String, dynamic>)[currentLocale] ??
        (filter['value'] as Map<String, dynamic>)['ru'] ??
        '-';

    final measure = filter['measure'] as Map<String, dynamic>?;
    if (measure != null) {
      final measureText = measure[currentLocale] ?? measure['ru'] ?? '';
      return '$value $measureText';
    }

    return value;
  }

  String _getDescription(ProductDetail product, String currentLocale) {
    return product.description[currentLocale] ??
        product.description['ru'] ??
        '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(compareProductsProvider);
    final currentLocale = context.locale.languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'store.compare_products'.tr(),
        showBottomBorder: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Products row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First product
              if (products.isNotEmpty) ...[
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(products[0].imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                ref
                                    .read(compareProductsProvider.notifier)
                                    .removeProduct(products[0]);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        products[0].title[currentLocale] ??
                            products[0].title['ru'] ??
                            '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${products[0].productVariants.map((v) => v.price).reduce((a, b) => a < b ? a : b).toInt()} ₸',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            ' - ',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${products[0].productVariants.map((v) => v.price).reduce((a, b) => a > b ? a : b).toInt()} ₸',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Add to cart
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text('store.product.add_to_cart'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 12),
              // Second product or add button
              Expanded(
                child: products.length > 1
                    ? Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(products[1].imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(compareProductsProvider.notifier)
                                        .removeProduct(products[1]);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            products[1].title[currentLocale] ??
                                products[1].title['ru'] ??
                                '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${products[1].productVariants.map((v) => v.price).reduce((a, b) => a < b ? a : b).toInt()} ₸',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                ' - ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${products[1].productVariants.map((v) => v.price).reduce((a, b) => a > b ? a : b).toInt()} ₸',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Add to cart
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: Text('store.product.add_to_cart'.tr()),
                            ),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () {
                          context.push('/store');
                        },
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 24,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'store.select_product'.tr(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Comparison sections
          if (products.isNotEmpty) ...[
            // Basic info
            _buildComparisonSection(
              'store.article'.tr(),
              [
                _buildSimpleRow(products[0].article),
                products.length > 1
                    ? _buildSimpleRow(products[1].article)
                    : null,
              ],
            ),
            _buildComparisonSection(
              'store.category'.tr(),
              [
                _buildSimpleRow(((products[0].category?['title']
                        as Map<String, dynamic>?)?['ru'] as String?) ??
                    ''),
                products.length > 1
                    ? _buildSimpleRow(((products[1].category?['title']
                            as Map<String, dynamic>?)?['ru'] as String?) ??
                        '')
                    : null,
              ],
            ),
            _buildComparisonSection(
              'store.consumption_rate'.tr(),
              [
                _buildSimpleRow('${products[0].expense} м²/л'),
                products.length > 1
                    ? _buildSimpleRow('${products[1].expense} м²/л')
                    : null,
              ],
            ),
            _buildComparisonSection(
              'store.is_colorable'.tr(),
              [
                _buildSimpleRow(products[0].isColorable
                    ? 'store.yes'.tr()
                    : 'store.no'.tr()),
                products.length > 1
                    ? _buildSimpleRow(products[1].isColorable
                        ? 'store.yes'.tr()
                        : 'store.no'.tr())
                    : null,
              ],
            ),

            // Filter data
            ...products[0].filterData.map((filter) {
              return _buildComparisonSection(
                filter['title'][currentLocale] ?? filter['title']['ru'] ?? '',
                [
                  _buildSimpleRow(
                    filter['value'][currentLocale] ??
                        filter['value']['ru'] ??
                        '-',
                  ),
                  if (products.length > 1)
                    _buildSimpleRow(
                      products[1].filterData.firstWhere(
                                (f) => f['id'] == filter['id'],
                                orElse: () => {
                                  'value': {currentLocale: '-', 'ru': '-'}
                                },
                              )['value'][currentLocale] ??
                          products[1].filterData.firstWhere(
                                (f) => f['id'] == filter['id'],
                                orElse: () => {
                                  'value': {currentLocale: '-', 'ru': '-'}
                                },
                              )['value']['ru'] ??
                          '-',
                    ),
                ],
              );
            }).toList(),

            // Description
            _buildComparisonSection(
              'store.description'.tr(),
              [
                _buildSimpleRow(_getDescription(products[0], currentLocale),
                    isDescription: true),
                products.length > 1
                    ? _buildSimpleRow(
                        _getDescription(products[1], currentLocale),
                        isDescription: true)
                    : null,
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonSection(String title, List<Widget?> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: item ?? const SizedBox(height: 20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSimpleRow(String text, {bool isDescription = false}) {
    if (isDescription) {
      return Html(
        data: text,
        style: {
          "*": Style(
            fontSize: FontSize(13),
            color: AppColors.textPrimary,
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
        },
      );
    }
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
    );
  }
}
