import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:remalux_ar/blocs/ar_wall_painter/ar_wall_painter.dart';

enum PaintStrokeType {
  main, // Основной мазок
  connecting, // Соединительный мазок
  drip, // Потек
}

class ARWallPainterScreen extends StatelessWidget {
  const ARWallPainterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ARWallPainterBloc()..add(const InitializeARWallPainter()),
      child: const _ARWallPainterView(),
    );
  }
}

class _ARWallPainterView extends StatefulWidget {
  const _ARWallPainterView();

  @override
  State<_ARWallPainterView> createState() => _ARWallPainterViewState();
}

class _ARWallPainterViewState extends State<_ARWallPainterView> {
  // Предустановленные цвета
  final List<Color> _presetColors = [
    const Color(0xFF2196F3), // Синий
    const Color(0xFF4CAF50), // Зеленый
    const Color(0xFFF44336), // Красный
    const Color(0xFFFF9800), // Оранжевый
    const Color(0xFF9C27B0), // Фиолетовый
    const Color(0xFFFFEB3B), // Желтый
  ];

  final GlobalKey _cameraKey = GlobalKey();
  late final ARWallPainterBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ARWallPainterBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ARWallPainterBloc, ARWallPainterState>(
      listener: (context, state) {
        // Обработка ошибок
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Камера или заглушка
              _buildCameraView(state),

              // Оверлей для рисования
              if (state.isReady) _buildPaintingOverlay(context, state),

              // Сегментация (если включена)
              if (state.showSegmentationOverlay && state.wallMask != null)
                _buildSegmentationOverlay(state),

              // UI контролы
              if (state.isUIVisible) _buildUIControls(state),

              // Состояние загрузки
              if (state.isInitializing) _buildLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraView(ARWallPainterState state) {
    if (!state.isCameraInitialized || state.cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Positioned.fill(
      child: CameraPreview(
        state.cameraController!,
        key: _cameraKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Запускаем обработку кадра только один раз при готовности
            if (state.isReady &&
                !state.isProcessingFrame &&
                !_isStreamStarted) {
              _startFrameProcessing(
                  constraints.maxWidth, constraints.maxHeight);
            }
            return Container();
          },
        ),
      ),
    );
  }

  bool _isStreamStarted = false;

  void _startFrameProcessing(double width, double height) {
    if (_isStreamStarted) return; // Предотвращаем повторный запуск

    // Сохраняем блок до асинхронного вызова
    final bloc = context.read<ARWallPainterBloc>();

    // Запускаем обработку кадра с задержкой для избежания перегрузки
    Future.delayed(const Duration(milliseconds: 100), () {
      if (bloc.state.cameraController != null &&
          bloc.state.isReady &&
          !_isStreamStarted) {
        try {
          bloc.state.cameraController!.startImageStream((image) {
            bloc.add(ProcessCameraFrame(
              cameraImage: image,
              screenWidth: width,
              screenHeight: height,
            ));
          });
          _isStreamStarted = true;
        } catch (e) {
          // Логируем ошибку, но не падаем
          print('⚠️ Ошибка запуска камеры: $e');
        }
      }
    });
  }

  Widget _buildPaintingOverlay(BuildContext context, ARWallPainterState state) {
    return Positioned.fill(
      child: GestureDetector(
        onTapUp: (details) {
          final RenderBox box =
              _cameraKey.currentContext!.findRenderObject() as RenderBox;
          context.read<ARWallPainterBloc>().add(
                PaintWallAtPoint(
                  details.localPosition,
                  box.size.width,
                  box.size.height,
                ),
              );
        },
        child: CustomPaint(
          painter: WallPainter(
            paintedPath: state.paintedWallPath,
            color: state.selectedColor,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildSegmentationOverlay(ARWallPainterState state) {
    return Positioned.fill(
      child: CustomPaint(
        painter: SegmentationPainter(
          wallMask: state.wallMask!,
          confidence: state.aiConfidence,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildUIControls(ARWallPainterState state) {
    return SafeArea(
      child: Column(
        children: [
          // Верхняя панель
          _buildTopPanel(state),

          const Spacer(),

          // Нижняя панель
          _buildBottomPanel(state),
        ],
      ),
    );
  }

  Widget _buildTopPanel(ARWallPainterState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Кнопка назад
          _buildControlButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),

          const Spacer(),

          // Индикатор состояния AI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: state.isAIModelLoaded ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.isAIModelLoaded ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  state.isAIModelLoaded ? 'AI готов' : 'AI ошибка',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Переключатель сегментации
          _buildControlButton(
            icon: state.showSegmentationOverlay
                ? Icons.visibility
                : Icons.visibility_off,
            onPressed: () {
              context.read<ARWallPainterBloc>().add(
                    const ToggleSegmentationOverlay(),
                  );
            },
          ),

          // Переключатель UI
          _buildControlButton(
            icon: Icons.more_vert,
            onPressed: () {
              context.read<ARWallPainterBloc>().add(
                    const ToggleUIVisibility(),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ARWallPainterState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Палитра цветов
          _buildColorPalette(state),

          const SizedBox(height: 16),

          // Кнопки действий
          _buildActionButtons(state),
        ],
      ),
    );
  }

  Widget _buildColorPalette(ARWallPainterState state) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ..._presetColors.map((color) => _buildColorButton(color, state)),
          _buildCustomColorButton(state),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color, ARWallPainterState state) {
    final isSelected = state.selectedColor == color;
    return GestureDetector(
      onTap: () {
        context.read<ARWallPainterBloc>().add(ChangeSelectedColor(color));
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomColorButton(ARWallPainterState state) {
    return GestureDetector(
      onTap: () => _showColorPicker(state),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.green, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.palette, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildActionButtons(ARWallPainterState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.clear,
          label: 'Очистить',
          onPressed: state.paintedWallPath != null
              ? () => context
                  .read<ARWallPainterBloc>()
                  .add(const ClearPaintedWall())
              : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Инициализация AR...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(ARWallPainterState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: state.selectedColor,
            onColorChanged: (color) {
              context.read<ARWallPainterBloc>().add(ChangeSelectedColor(color));
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bloc.add(const DisposeARWallPainter());
    super.dispose();
  }
}

/// Painter для отображения закрашенной стены
class WallPainter extends CustomPainter {
  final ui.Path? paintedPath;
  final Color color;

  WallPainter({
    required this.paintedPath,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (paintedPath == null) return;

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(paintedPath!, paint);
  }

  @override
  bool shouldRepaint(WallPainter oldDelegate) {
    return oldDelegate.paintedPath != paintedPath || oldDelegate.color != color;
  }
}

/// Painter для отображения сегментации стен
class SegmentationPainter extends CustomPainter {
  final ui.Path wallMask;
  final double confidence;

  SegmentationPainter({
    required this.wallMask,
    required this.confidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawPath(wallMask, paint);

    // Рамка
    final borderPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(wallMask, borderPaint);
  }

  @override
  bool shouldRepaint(SegmentationPainter oldDelegate) {
    return oldDelegate.wallMask != wallMask ||
        oldDelegate.confidence != confidence;
  }
}
