import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/core/widgets/development_notice_modal.dart';
import 'package:remalux_ar/features/home/presentation/widgets/categories_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/products_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/news_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/ideas_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/colors_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/color_detail_modal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remalux_ar/features/home/domain/providers/detailed_colors_provider.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final int _selectedIndex = 0;
  late ScrollController _scrollController;
  bool _showSafeArea = false;
  Color _currentColor = Colors.white;
  Timer? _colorTimer;
  List<Color> _usedColors = [];

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _startColorAnimation() {
    _colorTimer?.cancel();
    _colorTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;

      final colorsAsync = ref.read(detailedColorsProvider);
      colorsAsync.whenData((colors) {
        if (colors.isEmpty) return;

        setState(() {
          final randomColor = colors[Random().nextInt(colors.length)];
          final newColor = _parseHexColor(randomColor.hex);

          // Update current color for the animated background
          _currentColor = newColor;

          // Update used colors list
          if (_usedColors.isEmpty) {
            // Initialize with the first color if empty
            _usedColors.add(newColor);
          } else {
            if (_usedColors.length >= 4) {
              _usedColors.removeLast();
            }
            _usedColors.insert(0, newColor);
          }
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Initialize with first color from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load colors
      ref.read(detailedColorsProvider.notifier).loadColors();

      final colorsAsync = ref.read(detailedColorsProvider);
      colorsAsync.whenData((colors) {
        if (colors.isNotEmpty) {
          final initialColor = colors[0];
          setState(() {
            _currentColor = _parseHexColor(initialColor.hex);
            _usedColors = [_currentColor];
          });
        }
      });
      _startColorAnimation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _colorTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Stack(
              children: [
                // Background Image
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 450,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Room preview background
                      Image.asset(
                        'lib/core/assets/images/room_preview.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                      // Current Color Card
                      Positioned(
                        top: 155,
                        right: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.91),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 23, sigmaY: 23),
                            child: Container(
                              width: 60,
                              height: 80,
                              padding: const EdgeInsets.fromLTRB(
                                  4.6, 4.6, 4.6, 9.21),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6.91),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 0.93,
                                ),
                              ),
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final colorsAsync =
                                      ref.watch(detailedColorsProvider);

                                  return colorsAsync.when(
                                    loading: () => Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 51,
                                            height: 51,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          Container(
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    error: (error, stack) => const SizedBox(),
                                    data: (colors) {
                                      if (colors.isEmpty)
                                        return const SizedBox();

                                      final currentColor = colors.firstWhere(
                                        (color) =>
                                            _parseHexColor(color.hex) ==
                                            _currentColor,
                                        orElse: () => colors[0],
                                      );

                                      return GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            builder: (context) =>
                                                ColorDetailModal(
                                              color: currentColor,
                                            ),
                                          );
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 51,
                                              height: 51,
                                              decoration: BoxDecoration(
                                                color: _currentColor,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            Text(
                                              currentColor.title[context
                                                      .locale.languageCode] ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF333333),
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Hand with phone
                      Align(
                        alignment: const Alignment(0.4, 0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 70),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'lib/core/assets/images/hand.png',
                                height: 400,
                                fit: BoxFit.contain,
                              ),
                              // Animated background circle
                              Positioned(
                                top: 57,
                                left: 27,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    width: 90,
                                    height: 195,
                                    decoration: BoxDecoration(
                                      color: _currentColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 57,
                                left: 27,
                                child: Container(
                                  width: 90,
                                  height: 195,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'lib/core/assets/images/store/1.png',
                                      fit: BoxFit.cover,
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
                ),

                // Color Palette Circles
                Positioned(
                  left: 16,
                  top: 145,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final colorsAsync = ref.watch(detailedColorsProvider);

                      return colorsAsync.when(
                        loading: () => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 180,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        error: (error, stack) => const SizedBox(),
                        data: (colors) => AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 14.56,
                                sigmaY: 14.56,
                              ),
                              child: Container(
                                height: 180,
                                width: 48,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 0.59,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _usedColors
                                      .map((color) => Container(
                                            width: 32,
                                            height: 32,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: color,
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                width: 2,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Main Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),

                    // App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          SizedBox(
                            height: 40,
                            child: SvgPicture.asset(
                              'lib/core/assets/icons/logo.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: SvgPicture.asset(
                                  'lib/core/assets/icons/search.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF1F1F1F),
                                    BlendMode.srcIn,
                                  ),
                                  width: 20,
                                  height: 20,
                                ),
                                onPressed: () {
                                  context.push('/store',
                                      extra: {'autoFocus': true});
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 250),

                    // White Card
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF3B4D8B).withOpacity(0.09),
                                spreadRadius: -0.9,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Text
                              Text(
                                'home.try_colors'.tr(),
                                style: GoogleFonts.ysabeauInfant(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F1F1F),
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'home.try_colors_description'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF1F1F1F),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Visualize Button
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: CustomButton(
                                  label: 'home.visualize'.tr(),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          const DevelopmentNoticeModal(),
                                    );
                                  },
                                  type: ButtonType.normal,
                                  isFullWidth: true,
                                  isBackGradient: true,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // AR Cube Icon
                        Positioned(
                          top: -44,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Image.asset(
                              'lib/core/assets/icons/ar_cube.png',
                              width: 88,
                              height: 88,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Categories Grid
                    const CategoriesGrid(),
                    const SizedBox(height: 16),

                    // Colors Grid
                    const ColorsGrid(),

                    const SizedBox(height: 16),

                    // Ideas Grid
                    const IdeasGrid(),

                    const SizedBox(height: 16),

                    // Products Grid
                    const ProductsGrid(),

                    const SizedBox(height: 16),

                    // News Grid
                    const NewsGrid(),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
          // SafeArea overlay
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSafeArea ? MediaQuery.of(context).padding.top : 0,
            color: Colors.white.withOpacity(_showSafeArea ? 1.0 : 0.0),
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
