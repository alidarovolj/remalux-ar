import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/features/home/domain/providers/colors_provider.dart';
import 'package:remalux_ar/features/home/domain/providers/detailed_colors_provider.dart';
import 'package:remalux_ar/features/home/presentation/widgets/color_card_skeleton.dart';
import 'package:remalux_ar/features/home/presentation/widgets/main_color_skeleton.dart';
import 'package:remalux_ar/features/home/presentation/widgets/color_detail_modal.dart';
import 'package:remalux_ar/core/widgets/detailed_color_card.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/favorites/domain/providers/favorites_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';

class ColorsPage extends ConsumerStatefulWidget {
  final int? mainColorId;

  const ColorsPage({
    super.key,
    this.mainColorId,
  });

  @override
  ConsumerState<ColorsPage> createState() => _ColorsPageState();
}

class _ColorsPageState extends ConsumerState<ColorsPage> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  Timer? _debounceTimer;
  int? _selectedColorId;
  String currentLocale = 'ru';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _selectedColorId = widget.mainColorId;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreColors();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentLocale = context.locale.languageCode;
      });
      final colorsNotifier = ref.read(detailedColorsProvider.notifier);
      colorsNotifier.loadColors(
        additionalParams: _selectedColorId != null
            ? {'parentId': _selectedColorId.toString()}
            : null,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = context.locale.languageCode;
    if (currentLocale != newLocale) {
      setState(() {
        currentLocale = newLocale;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadMoreColors() {
    final colorsNotifier = ref.read(detailedColorsProvider.notifier);
    if (!colorsNotifier.isLoading && colorsNotifier.hasMore) {
      colorsNotifier.loadColors(isLoadMore: true);
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.length >= 3 || value.isEmpty) {
        final colorsNotifier = ref.read(detailedColorsProvider.notifier);
        colorsNotifier.resetAndSearch(value);
      }
    });
  }

  void _onMainColorTap(int? colorId) {
    setState(() {
      _selectedColorId = colorId;
    });

    final colorsNotifier = ref.read(detailedColorsProvider.notifier);
    ref.read(currentPageProvider.notifier).state = 1;

    if (colorId != null) {
      colorsNotifier.loadColors(
        additionalParams: {'parentId': colorId.toString()},
      );
    } else {
      colorsNotifier.loadColors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColorsAsync = ref.watch(colorsProvider);
    final detailedColorsAsync = ref.watch(detailedColorsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: 'home.colors.page_title'.tr(),
        showBottomBorder: true,
        showFavoritesButton: true,
      ),
      body: Column(
        children: [
          // Search and Main Colors Container
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'home.colors.search_placeholder'.tr(),
                        hintStyle: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.5),
                          fontSize: 15,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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

                // Main Colors Grid
                mainColorsAsync.when(
                  data: (colors) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        // All Colors Item
                        GestureDetector(
                          onTap: () => _onMainColorTap(null),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedColorId == null
                                        ? const Color(0xFF1F1F1F)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'lib/core/assets/images/colors/all.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (_selectedColorId == null)
                                      const Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF1F1F1F),
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'home.colors.all_colors'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1F1F1F),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Color Items
                        ...colors.map((color) => GestureDetector(
                              onTap: () => _onMainColorTap(color.id),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedColorId == color.id
                                              ? const Color(0xFF1F1F1F)
                                              : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.asset(
                                              'lib/core/assets/images/colors/${_getImageName(color.title['en']?.toLowerCase() ?? '')}',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          if (_selectedColorId == color.id)
                                            const Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF1F1F1F),
                                                size: 20,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'home.colors.color_names.${color.title['en']?.toLowerCase() ?? ''}'
                                          .tr(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  loading: () => const MainColorSkeleton(),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ],
            ),
          ),

          // Detailed Colors Grid
          Expanded(
            child: detailedColorsAsync.when(
              data: (colors) => LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 48) / 2;
                  final aspectRatio = width / 174;

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: colors.length +
                        (ref.read(detailedColorsProvider.notifier).hasMore
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index == colors.length) {
                        return const ColorCardSkeleton();
                      }

                      final color = colors[index];
                      return DetailedColorCard(
                        color: color,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                ColorDetailModal(color: color),
                          );
                        },
                        onFavoritePressed: () async {
                          await ref
                              .read(favoriteColorsProvider.notifier)
                              .toggleFavorite(
                                color.id,
                                context,
                                'home.colors.color_names.${color.title['en']?.toLowerCase() ?? ''}'
                                    .tr(),
                                color.isFavourite,
                              );
                          ref
                              .read(detailedColorsProvider.notifier)
                              .loadColors();
                        },
                      );
                    },
                  );
                },
              ),
              loading: () => LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 48) / 2;
                  final aspectRatio = width / 174;

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const ColorCardSkeleton(),
                  );
                },
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getImageName(String colorName) {
    final colorKey = colorName.toLowerCase();
    switch (colorKey) {
      case 'grey':
        return 'grey.png';
      case 'blue':
        return 'Blue.png';
      case 'pink':
        return 'Pink.png';
      case 'orange':
        return 'Coral.png';
      case 'purple':
        return 'Purple.png';
      case 'brown':
        return 'Brown.png';
      case 'white':
        return 'aqua.png';
      case 'green':
        return 'Green.png';
      case 'yellow':
        return 'Yellow.png';
      default:
        return 'grey.png';
    }
  }
}
