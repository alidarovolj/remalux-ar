import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/cv_wall_painter_service.dart';
import 'dart:math' as math;

/// Computer Vision Wall Painter Screen
/// Использует ML сегментацию с ADE20K датасетом для покраски стен
class CVWallPainterScreen extends StatefulWidget {
  const CVWallPainterScreen({Key? key}) : super(key: key);

  @override
  State<CVWallPainterScreen> createState() => _CVWallPainterScreenState();
}

class _CVWallPainterScreenState extends State<CVWallPainterScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  // CV Service
  final CVWallPainterService _cvService = CVWallPainterService.instance;
  bool _isCVInitialized = false;
  bool _isProcessing = false;
  CVResultDto? _lastCvResult; // Храним последний результат целиком

  // Current painting state
  ui.Image? _segmentationOverlay;
  ui.Image? _paintedOverlay; // This replaces `_wallMask`
  ui.Offset? _lastTapPoint;
  Color _selectedColor = const Color(0xFF2196F3);

  // Performance metrics
  int _lastProcessingTimeMs = 0;
  int _frameCount = 0;

  // UI State
  bool _showColorPalette = false;
  bool _showInstructions = true;
  bool _showDebugInfo = false;
  bool _showSegmentation = true; // Новый переключатель для сегментации

  // Color palette
  static const List<Color> _colorPalette = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFF44336), // Red
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF00BCD4), // Cyan
    Color(0xFF8BC34A), // Light Green
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cvService.stopCameraStream();
    _cameraController?.dispose();
    _cvService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize CV service
      await _cvService.initialize();

      // Set up callbacks for CV service
      _cvService.setResultCallback((result) {
        if (mounted) {
          // New: Create images from raw masks on the main thread
          if (result.segmentationMask != null) {
            _createImageFromMask(result.segmentationMask!, result.maskWidth,
                    result.maskHeight, const Color.fromARGB(100, 0, 255, 0))
                .then((image) {
              if (mounted) {
                setState(() {
                  _segmentationOverlay = image;
                });
              }
            });
          }
          if (result.paintedMask != null) {
            _createImageFromMask(result.paintedMask!, result.maskWidth,
                    result.maskHeight, _selectedColor.withOpacity(0.7))
                .then((image) {
              if (mounted) {
                setState(() {
                  _paintedOverlay = image;
                });
              }
            });
          }

          setState(() {
            _lastCvResult = result; // Сохраняем весь результат
            _lastProcessingTimeMs = result.processingTimeMs;
          });
          debugPrint('✅ CV результат получен: ${result.processingTimeMs}ms');
        }
      });

      _cvService.setErrorCallback((error) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          debugPrint('❌ CV ошибка: $error');
        }
      });

      if (mounted) {
        setState(() {
          _isCVInitialized = _cvService.isInitialized;
        });
      }

      // Initialize camera
      await _initializeCamera();
    } catch (e) {
      debugPrint('❌ Ошибка инициализации сервисов: $e');
      if (mounted) {
        _showErrorDialog('Ошибка инициализации',
            'Не удалось запустить камеру или ML сервис: $e');
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }
      final camera = cameras.first;

      final imageFormatGroup =
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // ОБНОВЛЕНО
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      // Start camera stream for CV service
      await _cameraController!.startImageStream((CameraImage image) {
        if (_isCVInitialized && !_isProcessing) {
          _cvService.updateCameraFrame(image);
        }
      });

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });

        // Start CV processing stream for real-time segmentation visualization
        if (_isCVInitialized) {
          _cvService.startCameraStream();
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка инициализации камеры: $e');
      rethrow;
    }
  }

  Future<void> _onTapScreen(TapDownDetails details) async {
    if (!_isCVInitialized || _isProcessing || _cameraController == null) {
      return;
    }

    try {
      HapticFeedback.lightImpact();

      setState(() {
        _isProcessing = true;
        _lastTapPoint = details.localPosition;
      });

      final stopwatch = Stopwatch()..start();

      // Real ML processing with BiseNet
      debugPrint('🎨 Обрабатываем кадр с DeepLabV3...');

      // Реальная обработка с CV сервисом
      await _cvService.paintWall(details.localPosition, _selectedColor);

      stopwatch.stop();

      debugPrint(
          '🎨 Кадр отправлен в CV сервис за ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ Ошибка обработки касания: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _frameCount++;
        });
      }
    }
  }

  void _onColorSelected(Color color) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedColor = color;
      _showColorPalette = false;
    });
  }

  void _clearPainting() {
    HapticFeedback.mediumImpact();
    setState(() {
      _paintedOverlay = null; // Clear the overlay
      _segmentationOverlay = null; // Also clear segmentation
      _lastTapPoint = null;
      _frameCount = 0;
    });
  }

  Future<ui.Image> _createImageFromMask(
      Uint8List mask, int width, int height, Color color) async {
    final pixels = Uint32List(mask.length);
    for (int i = 0; i < mask.length; i++) {
      if (mask[i] == 1) {
        pixels[i] = color.value;
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    return completer.future;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CV Wall Painter'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: GestureDetector(
                  onTapDown: _onTapScreen,
                  child: Stack(
                    children: [
                      CameraPreview(_cameraController!),

                      // Painted wall overlay
                      if (_paintedOverlay != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WallPainter(
                                imageToPaint: _paintedOverlay!,
                                originalImageSize: _getOriginalImageSize()),
                          ),
                        ),

                      // Segmentation overlay
                      if (_showSegmentation && _segmentationOverlay != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WallPainter(
                                imageToPaint: _segmentationOverlay!,
                                originalImageSize: _getOriginalImageSize(),
                                isSegmentation: true),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Обработка кадра...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions
          if (_showInstructions)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Инструкции:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Наведите камеру на стену\n• Коснитесь стены для покраски\n• Выберите цвет из палитры',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CV: ${_isCVInitialized ? "Готов" : "Загрузка..."}',
                          style: TextStyle(
                            color:
                                _isCVInitialized ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showInstructions = false;
                            });
                          },
                          child: const Text(
                            'Закрыть',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Debug info
          if (_showDebugInfo)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Отладка:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Время: ${_lastProcessingTimeMs}ms',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Кадры: $_frameCount',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Color palette
          if (_showColorPalette)
            Positioned(
              bottom: 160,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выберите цвет:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _colorPalette.length,
                      itemBuilder: (context, index) {
                        final color = _colorPalette[index];
                        final isSelected = color == _selectedColor;

                        return GestureDetector(
                          onTap: () => _onColorSelected(color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Color button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showColorPalette = !_showColorPalette;
                        });
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.palette,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Clear button
                    IconButton(
                      onPressed: _clearPainting,
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    // Info button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showInstructions = !_showInstructions;
                        });
                      },
                      icon: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    // Segmentation toggle button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showSegmentation = !_showSegmentation;
                        });
                      },
                      icon: Icon(
                        _showSegmentation
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: _showSegmentation ? Colors.green : Colors.white,
                        size: 32,
                      ),
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

  Size _getOriginalImageSize() {
    if (_lastCvResult != null) {
      // Используем точные размеры из результата CV
      return Size(_lastCvResult!.imageWidth.toDouble(),
          _lastCvResult!.imageHeight.toDouble());
    }
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Фоллбэк на размер превью, если результата еще нет
      return _cameraController!.value.previewSize!;
    }
    return Size.zero; // Худший случай
  }
}

/// Generic painter for segmentation or painted overlays.
/// Handles correct scaling and aspect ratio.
class WallPainter extends CustomPainter {
  final ui.Image imageToPaint;
  final Size originalImageSize;
  final bool isSegmentation;

  WallPainter({
    required this.imageToPaint,
    required this.originalImageSize,
    this.isSegmentation = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // This is the size of the widget on the screen.
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // This is the original image from the camera that was processed.
    final imageSize = originalImageSize;

    // Calculate how the camera image is fitted onto the screen. Flutter's
    // CameraPreview uses BoxFit.cover.
    final fittedSizes = applyBoxFit(BoxFit.cover, imageSize, size);
    final sourceRect = Alignment.center.inscribe(fittedSizes.source,
        Rect.fromLTWH(0, 0, imageSize.width, imageSize.height));
    final destinationRect = Alignment.center.inscribe(
        fittedSizes.destination, Rect.fromLTWH(0, 0, size.width, size.height));

    // This is the mask/overlay we want to paint.
    final maskRect = Rect.fromLTWH(
        0, 0, imageToPaint.width.toDouble(), imageToPaint.height.toDouble());

    debugPrint("🎨 WallPainter: Canvas size: $size, "
        "Original image size: $originalImageSize, "
        "Mask size: ${imageToPaint.width}x${imageToPaint.height}, "
        "Destination rect: $destinationRect");

    final paint = Paint()
      ..filterQuality = isSegmentation ? FilterQuality.low : FilterQuality.high;

    if (isSegmentation) {
      paint.colorFilter =
          const ColorFilter.mode(Colors.black, BlendMode.dstOut);
    }

    canvas.drawImageRect(
      imageToPaint,
      maskRect,
      destinationRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return oldDelegate.imageToPaint != imageToPaint ||
        oldDelegate.originalImageSize != originalImageSize ||
        oldDelegate.isSegmentation != isSegmentation;
  }
}
