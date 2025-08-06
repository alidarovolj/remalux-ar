import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:remalux_ar/features/ar/domain/providers/ar_provider.dart';

class ColorPaletteWidget extends ConsumerWidget {
  const ColorPaletteWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arState = ref.watch(arProvider);
    final arNotifier = ref.read(arProvider.notifier);

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Color palette
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: arState.availableColors.length,
                  itemBuilder: (context, index) {
                    final color = arState.availableColors[index];
                    final isSelected = color == arState.selectedColor;

                    return _buildColorItem(
                      color: color,
                      isSelected: isSelected,
                      onTap: () {
                        print('🎨 Пользователь выбрал цвет: $color');
                        arNotifier.selectColor(color);
                      },
                    );
                  },
                ),
              ),

              // Color picker button
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

              GestureDetector(
                onTap: () => _showColorPicker(context, arState, arNotifier),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorItem({
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }

  void _showColorPicker(
      BuildContext context, ArState arState, ArNotifier arNotifier) {
    Color pickerColor = arState.selectedColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Выберите цвет краски',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current color preview
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
                onColorChanged: (color) {
                  pickerColor = color;
                },
                pickerAreaHeightPercent: 0.8,
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hueWheel,
                labelTypes: const [],
                portraitOnly: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print('🎨 Пользователь выбрал кастомный цвет: $pickerColor');
              arNotifier.selectColor(pickerColor);
              Navigator.pop(context);
            },
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
          ),
        ],
      ),
    );
  }
}
