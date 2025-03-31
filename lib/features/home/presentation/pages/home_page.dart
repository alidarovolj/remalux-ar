import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
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
                        child: Consumer(
                          builder: (context, ref, child) {
                            final colorsAsync =
                                ref.watch(detailedColorsProvider);

                            return colorsAsync.when(
                              loading: () => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 50,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 4),
                                        child: Container(
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              error: (error, stack) => const SizedBox(),
                              data: (colors) {
                                if (colors.isEmpty) return const SizedBox();

                                final currentColor = colors.firstWhere(
                                  (color) =>
                                      _parseHexColor(color.hex) ==
                                      _currentColor,
                                  orElse: () => colors[0],
                                );

                                return AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: 1.0,
                                  child: GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (context) => ColorDetailModal(
                                          color: currentColor,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromRGBO(
                                                59, 77, 139, 0.1),
                                            blurRadius: 5,
                                            offset: Offset(0, 1),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: _currentColor,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6, horizontal: 4),
                                            child: Text(
                                              currentColor.title[context
                                                      .locale.languageCode] ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Hand with phone
                      Center(
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
                            height: 176,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                4,
                                (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        error: (error, stack) => const SizedBox(),
                        data: (colors) => AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 55.0,
                                sigmaY: 55.0,
                              ),
                              child: Container(
                                height: 176,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _usedColors
                                      .map((color) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: color,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    spreadRadius: 0,
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
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
                            child: Image.asset(
                              'lib/core/assets/images/logos/main.png',
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
                                style: const TextStyle(
                                  fontSize: 24,
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
                                  fontSize: 16,
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
                                  onPressed: () {},
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
