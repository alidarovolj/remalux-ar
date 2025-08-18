import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/ar/domain/providers/ar_provider.dart';
import 'package:remalux_ar/features/ar/presentation/widgets/color_palette_widget.dart';
import 'package:remalux_ar/features/ar/presentation/widgets/ar_controls_widget.dart';
import 'package:remalux_ar/features/ar/presentation/widgets/ar_loading_widget.dart';

class ArPage extends ConsumerStatefulWidget {
  final Color? initialColor;

  const ArPage({super.key, this.initialColor});

  @override
  ConsumerState<ArPage> createState() => _ArPageState();
}

class _ArPageState extends ConsumerState<ArPage> {
  @override
  void initState() {
    super.initState();
    // Устанавливаем начальный цвет если он был передан
    if (widget.initialColor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(arProvider.notifier).selectColor(widget.initialColor!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final arState = ref.watch(arProvider);
    final arNotifier = ref.read(arProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black, // Черный фон для всего экрана
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Unity AR Widget на весь экран
          if (arState.errorMessage == null)
            EmbedUnity(
              onMessageFromUnity: (message) {
                _handleUnityMessage(message, arNotifier);
              },
            ),

          // Черная маска с прозрачным окном поверх камеры
          if (arState.errorMessage == null)
            Positioned.fill(
              child: CustomPaint(
                painter: _CameraMaskPainter(),
              ),
            ),

          // Loading Overlay
          if (arState.isLoading) const ArLoadingWidget(),

          // Error State
          if (arState.errorMessage != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка AR',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      arState.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Вернуться'),
                    ),
                  ],
                ),
              ),
            ),

          // UI Controls
          if (arState.isUnityLoaded && arState.errorMessage == null)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ArControlsWidget(),
            ),

          // Color Palette внутри рамки
          if (arState.isUnityLoaded && arState.errorMessage == null)
            Positioned(
              bottom: 160, // Увеличил отступ снизу для нового дизайна
              left: 42, // +10 для новых отступов
              right: 42, // +10 для новых отступов
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(25),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const ColorPaletteWidget(),
              ),
            ),

          // Paint Toggle Button внутри рамки
          if (arState.isUnityLoaded && arState.errorMessage == null)
            Positioned(
              bottom: 80, // Увеличил отступ снизу для нового дизайна
              left: 42, // +10 для новых отступов
              right: 42, // +10 для новых отступов
              child: Center(
                child: _buildPaintToggleButton(arState, arNotifier),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'AR Окрашивание',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPaintToggleButton(ArState arState, ArNotifier arNotifier) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(30),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            arNotifier.setPaintingMode(!arState.isPainting);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: arState.isPainting
                    ? [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8)
                      ]
                    : [Colors.grey.shade700, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  arState.isPainting ? Icons.brush : Icons.brush_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  arState.isPainting
                      ? 'Рисование включено'
                      : 'Включить рисование',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleUnityMessage(dynamic message, ArNotifier arNotifier) {
    try {
      // Обработка сообщений от Unity
      if (message is String) {
        if (message.contains('error')) {
          arNotifier.setError('Ошибка в Unity: $message');
        } else if (message.contains('ready') ||
            message.contains('loaded') ||
            message.contains('onUnityReady')) {
          // Убеждаемся что Unity помечен как загруженный
          arNotifier.setLoading(false);
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка обработки сообщения от Unity: $e');
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как использовать AR'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Наведите камеру на стену',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('Убедитесь, что стена хорошо освещена и видна камере.'),
              SizedBox(height: 16),
              Text(
                '2. Выберите цвет',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('Используйте палитру внизу экрана для выбора цвета краски.'),
              SizedBox(height: 16),
              Text(
                '3. Включите рисование',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'Нажмите кнопку "Включить рисование" чтобы начать окрашивание.'),
              SizedBox(height: 16),
              Text(
                '4. Наслаждайтесь результатом',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('AR покажет как будет выглядеть стена в выбранном цвете.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter для создания черной маски с прозрачным окном
class _CameraMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Создаем полный черный прямоугольник
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Создаем прямоугольник для прозрачного окна
    const margin = EdgeInsets.only(left: 26, right: 26, top: 36, bottom: 36);
    final windowRect = Rect.fromLTWH(
      margin.left,
      margin.top,
      size.width - margin.left - margin.right,
      size.height - margin.top - margin.bottom,
    );

    // Создаем скругленный прямоугольник для окна
    final windowRRect = RRect.fromRectAndRadius(
      windowRect,
      const Radius.circular(16),
    );

    // Создаем путь с вырезом
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(windowRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
