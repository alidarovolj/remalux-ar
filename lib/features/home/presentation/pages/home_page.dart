import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/features/home/presentation/widgets/categories_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/products_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/news_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/ideas_grid.dart';
import 'package:remalux_ar/features/home/presentation/widgets/colors_grid.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final int _selectedIndex = 0;
  late ScrollController _scrollController;
  bool _showSafeArea = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                  child: Image.asset(
                    'lib/core/assets/images/room_preview.png',
                    fit: BoxFit.cover,
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
                          horizontal: 16.0, vertical: 8.0),
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
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Color Palette Circles
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 32),
                      child: Column(
                        children: List.generate(
                          4,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: [
                                  const Color(0xFFFBD9B0), // Warmer orange
                                  const Color(0xFFFFC0CB), // Pink
                                  const Color(0xFFDCDCDC), // Light grey
                                  Colors.white,
                                ][index],
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  if (index == 3)
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 38),

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
                              const Text(
                                'Примерьте краски',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F1F1F),
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Подберите оттенок и представьте\nбудущий интерьер',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1F1F1F),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Visualize Button
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: CustomButton(
                                  label: 'Визуализировать',
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
