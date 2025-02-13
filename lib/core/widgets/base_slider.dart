import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/providers/requests/banner_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CarouselWithIndicator extends ConsumerStatefulWidget {
  final String? module;
  final bool showIndicators;

  const CarouselWithIndicator({
    super.key,
    this.module,
    this.showIndicators = true,
  });

  @override
  ConsumerState<CarouselWithIndicator> createState() =>
      _CarouselWithIndicatorState();
}

class _CarouselWithIndicatorState extends ConsumerState<CarouselWithIndicator> {
  int _current = 0;

  Future<void> _handleBannerTap(BannerModel banner) async {
    if (banner.linkType == 'external') {
      final url = banner.linkValue;
      if (await canLaunch(url)) {
        await launch(url);
      }
    }
    // Handle other link types here if needed
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider(widget.module));

    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            CarouselSlider(
              items: banners.map((banner) {
                return GestureDetector(
                  onTap: () => _handleBannerTap(banner),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppLength.xs),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                          Radius.circular(AppLength.xxs)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          Image.network(
                            banner.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, size: 40),
                              );
                            },
                          ),
                          // Overlay with Title, Description, and Button
                          Positioned.fill(
                            child: Container(
                              padding: const EdgeInsets.all(AppLength.xs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.7, vertical: 4.7),
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppLength.four),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(200),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Image.network(
                                              banner.partner.imageUrl,
                                              height: AppLength.body,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(Icons.error,
                                                    size: AppLength.xs);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Title
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    child: Text(
                                      banner.title,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: AppLength.lg,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppLength.tiny),
                                  // Description
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    child: Text(
                                      banner.description,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: AppLength.sm,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              options: CarouselOptions(
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                aspectRatio: 2,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                viewportFraction: 1,
                enlargeFactor: 0.2,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
            if (widget.showIndicators && banners.length > 1) ...[
              const SizedBox(height: AppLength.tiny),
              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: banners.asMap().entries.map((entry) {
                  return GestureDetector(
                    child: Container(
                      width: AppLength.xs,
                      height: AppLength.xs,
                      margin: const EdgeInsets.symmetric(
                          vertical: AppLength.tiny, horizontal: AppLength.tiny),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.dividerColor
                                : AppColors.primary)
                            .withOpacity(_current == entry.key ? 0.9 : 0.2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppLength.xxxl)
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
