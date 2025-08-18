import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/domain/providers/detailed_colors_provider.dart';
import 'package:remalux_ar/features/home/domain/providers/colors_provider.dart';
import 'dart:async';

class ArColorBottomSheet extends ConsumerStatefulWidget {
  final Function(Color) onColorSelected;
  final Color? selectedColor;
  final int? preselectedMainColorId;
  final String? categoryName;

  const ArColorBottomSheet({
    super.key,
    required this.onColorSelected,
    this.selectedColor,
    this.preselectedMainColorId,
    this.categoryName,
  });

  @override
  ConsumerState<ArColorBottomSheet> createState() => _ArColorBottomSheetState();
}

class _ArColorBottomSheetState extends ConsumerState<ArColorBottomSheet> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  Timer? _debounceTimer;
  int? _selectedMainColorId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();

    // Устанавливаем предвыбранную категорию
    _selectedMainColorId = widget.preselectedMainColorId;

    // Подписываемся на скролл для пагинации
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreColors();
      }
    });

    // Загружаем цвета при инициализации с фильтрацией если нужно
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final colorsNotifier = ref.read(detailedColorsProvider.notifier);
      Map<String, dynamic>? additionalParams;
      if (_selectedMainColorId != null) {
        additionalParams = {
          'filters[parentColor.id]': _selectedMainColorId.toString()
        };
      }
      colorsNotifier.loadColors(
        forceRefresh: true,
        additionalParams: additionalParams,
      );
    });
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

        // Add filter parameters if a main color is selected
        Map<String, dynamic>? additionalParams;
        if (_selectedMainColorId != null) {
          additionalParams = {
            'filters[parentColor.id]': _selectedMainColorId.toString()
          };
        }

        colorsNotifier.resetAndSearch(value,
            additionalParams: additionalParams);
      }
    });
  }

  void _onMainColorTap(int? colorId) {
    setState(() {
      _selectedMainColorId = colorId;
    });

    final colorsNotifier = ref.read(detailedColorsProvider.notifier);

    // Preserve current search query
    final currentSearchQuery = _searchController.text;

    if (colorId != null) {
      colorsNotifier.resetAndSearch(currentSearchQuery,
          additionalParams: {'filters[parentColor.id]': colorId.toString()});
    } else {
      colorsNotifier.resetAndSearch(currentSearchQuery);
    }
  }

  // Конвертируем HEX цвет из API в Color
  Color _hexToColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey; // Fallback цвет
    }
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

  @override
  Widget build(BuildContext context) {
    final mainColorsAsync = ref.watch(colorsProvider);
    final detailedColorsAsync = ref.watch(detailedColorsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.categoryName ?? 'Все цвета',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Поиск цветов...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main colors filter - показываем только если не выбрана конкретная категория
          if (widget.preselectedMainColorId == null) ...[
            mainColorsAsync.when(
              data: (colors) => Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All colors
                      GestureDetector(
                        onTap: () => _onMainColorTap(null),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedMainColorId == null
                                        ? const Color(0xFF1F1F1F)
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'lib/core/assets/images/colors/all.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Все',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Color categories
                      ...colors.map((color) => GestureDetector(
                            onTap: () => _onMainColorTap(color.id),
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedMainColorId == color.id
                                            ? const Color(0xFF1F1F1F)
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        'lib/core/assets/images/colors/${_getImageName(color.title['en']?.toLowerCase() ?? '')}',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    color.title['ru'] ??
                                        color.title['en'] ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              loading: () => Container(
                height: 120,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Container(
                height: 120,
                child: const Center(child: Text('Ошибка загрузки категорий')),
              ),
            ),

            // Divider
            const Divider(height: 1),
          ],

          // Colors grid
          Expanded(
            child: detailedColorsAsync.when(
              data: (colors) => GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: colors.length +
                    (ref.read(detailedColorsProvider.notifier).hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == colors.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final colorData = colors[index];
                  final color = _hexToColor(colorData.hex);
                  final isSelected = widget.selectedColor?.value == color.value;

                  return GestureDetector(
                    onTap: () {
                      widget.onColorSelected(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1F1F1F)
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Color circle
                          Expanded(
                            flex: 3,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    )
                                  : null,
                            ),
                          ),

                          // Color info
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [
                                  Text(
                                    colorData.title['ru'] ??
                                        colorData.title['en'] ??
                                        'Цвет',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    colorData.ral,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text('Ошибка загрузки цветов'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(detailedColorsProvider.notifier)
                            .loadColors(forceRefresh: true);
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
