import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/domain/providers/detailed_colors_provider.dart';

class UnityColorPaletteWidget extends ConsumerStatefulWidget {
  final Function(Color) onColorSelected;
  final Color? selectedColor;
  final bool isEnabled;

  const UnityColorPaletteWidget({
    super.key,
    required this.onColorSelected,
    this.selectedColor,
    this.isEnabled = true,
  });

  @override
  ConsumerState<UnityColorPaletteWidget> createState() =>
      _UnityColorPaletteWidgetState();
}

class _UnityColorPaletteWidgetState
    extends ConsumerState<UnityColorPaletteWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Подписываемся на скролл для пагинации
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMoreColors();
      }
    });

    // Загружаем цвета при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final colorsNotifier = ref.read(detailedColorsProvider.notifier);
      colorsNotifier.loadColors(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreColors() {
    final colorsNotifier = ref.read(detailedColorsProvider.notifier);
    if (!colorsNotifier.isLoading && colorsNotifier.hasMore) {
      colorsNotifier.loadColors(isLoadMore: true);
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

  void _showColorPicker() {
    if (!widget.isEnabled) return;

    Color pickerColor = widget.selectedColor ?? Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Выберите цвет',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Превью текущего цвета
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: pickerColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      '#${pickerColor.red.toRadixString(16).padLeft(2, '0')}${pickerColor.green.toRadixString(16).padLeft(2, '0')}${pickerColor.blue.toRadixString(16).padLeft(2, '0')}'
                          .toUpperCase(),
                      style: TextStyle(
                        color: pickerColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Color picker
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (Color color) {
                    pickerColor = color;
                  },
                  displayThumbColor: true,
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.8,
                  paletteType: PaletteType.hueWheel,
                  labelTypes: const [],
                  portraitOnly: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Отмена',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pickerColor,
                foregroundColor: pickerColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              ),
              child: const Text(
                'Выбрать',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                widget.onColorSelected(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailedColorsAsync = ref.watch(detailedColorsProvider);

    return Container(
      height: 120, // Увеличили высоту для больших цветов
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Text(
                'Выберите цвет:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isEnabled ? Colors.black87 : Colors.grey,
                ),
              ),

              const SizedBox(height: 12),

              // Палитра цветов из API
              Expanded(
                child: detailedColorsAsync.when(
                  data: (colors) => ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: colors.length +
                        (ref.read(detailedColorsProvider.notifier).hasMore
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      // Загрузка следующих цветов
                      if (index == colors.length) {
                        return Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final colorData = colors[index];
                      final color = _hexToColor(colorData.hex);
                      final isSelected =
                          widget.selectedColor?.value == color.value;

                      return GestureDetector(
                        onTap: widget.isEnabled
                            ? () {
                                widget.onColorSelected(color);
                              }
                            : null,
                        child: Container(
                          width: 60, // Увеличенный размер
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(
                                    alpha: widget.isEnabled ? 0.4 : 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Галочка для выбранного цвета
                              if (isSelected)
                                const Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),

                              // Информация о цвете при наведении
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    colorData.ral,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isEnabled ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ошибка загрузки',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
