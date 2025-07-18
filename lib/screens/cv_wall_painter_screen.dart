import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/cv_wall_painter_service.dart';
import '../core/services/segmentation_service.dart';
import '../core/services/wall_segmentation_service.dart';
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
  CameraImage? _lastCameraImage;

  // Key for camera preview widget
  final GlobalKey _cameraPreviewKey = GlobalKey();

  // CV Service
  final CVWallPainterService _cvService = CVWallPainterService.instance;
  bool _isCVInitialized = false;
  bool _isServiceBusy = false;
  CVResultDto? _lastCvResult; // Храним последний результат целиком

  // Segmentation Services
  final SegmentationService _segmentationService = SegmentationService();
  final WallSegmentationService _wallSegmentationService =
      WallSegmentationService();
  bool _isSegmentationInitialized = false;
  bool _isWallSegmentationInitialized = false;
  Uint8List? _currentWallMask; // Маска стены от модели сегментации

  // Модели сегментации
  int _currentModelIndex =
      2; // 0 - standard, 1 - specialized, 2 - mobile optimized
  final List<String> _modelNames = [
    'Стандартная (ADE20K)',
    'Специализированная',
    'Мобильная оптимизация'
  ];
  final List<Color> _modelColors = [Colors.orange, Colors.blue, Colors.green];

  // Current painting state
  ui.Image? _segmentationOverlay;
  ui.Image?
      _combinedPaintedOverlay; // Единое изображение для всех покрашенных областей
  ui.Offset? _lastTapPoint;
  Color _selectedColor = const Color(0xFF2196F3);

  // Performance metrics
  int _lastProcessingTimeMs = 0;
  int _frameCount = 0;
  int _segmentationFrameCount = 0; // Счётчик для периодической сегментации

  // UI State
  bool _showColorPalette = false;
  bool _showInstructions = true;
  bool _showDebugInfo = false;
  bool _showSegmentation = true; // Включено для визуальной обратной связи
  bool _showPaintLoader = false;

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
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _cvService.dispose();

    // Dispose segmentation services
    if (_isWallSegmentationInitialized) {
      _wallSegmentationService.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.stopImageStream();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize CV service
      await _cvService.initialize();

      // Initialize Segmentation services
      try {
        if (_currentModelIndex == 0) {
          // Standard ADE20K model
          await _segmentationService.loadModel();
          _isSegmentationInitialized = true;
          debugPrint('✅ Standard segmentation service initialized');
        } else {
          // Specialized or Mobile models
          await _wallSegmentationService.loadModel(
              modelIndex: _currentModelIndex);
          _isWallSegmentationInitialized = true;
          debugPrint(
              '✅ ${_modelNames[_currentModelIndex]} segmentation service initialized');
        }
      } catch (e) {
        debugPrint(
            '⚠️ Failed to load ${_modelNames[_currentModelIndex]} model, falling back to standard: $e');
        _currentModelIndex = 0;
        await _segmentationService.loadModel();
        _isSegmentationInitialized = true;
        debugPrint('✅ Fallback segmentation service initialized');
      }

      // Set up callbacks for CV service
      _cvService.setResultCallback((result) {
        if (!mounted) {
          _isServiceBusy = false;
          return;
        }

        _prepareImagesFromCvResult(result).then((images) async {
          final (segmentationOverlay, paintedOverlay) = images;

          if (mounted) {
            // Merge the new painted overlay onto the combined one
            if (paintedOverlay != null) {
              final newCombinedOverlay = await _mergeOverlays(
                baseImage: _combinedPaintedOverlay,
                newOverlay: paintedOverlay,
              );
              setState(() {
                _combinedPaintedOverlay = newCombinedOverlay;
              });
            }

            setState(() {
              if (segmentationOverlay != null) {
                _segmentationOverlay = segmentationOverlay;
              }
              // Не сбрасываем предыдущий segmentationOverlay если новый пустой
              _showPaintLoader = false;
              _lastCvResult = result;
              _lastProcessingTimeMs = result.processingTimeMs;
            });
            debugPrint(
                '✅ CV результат получен и UI обновлен: ${result.processingTimeMs}ms');
          }
        }).whenComplete(() {
          _isServiceBusy = false;
        });
      });

      _cvService.setErrorCallback((error) {
        if (mounted) {
          setState(() {
            _showPaintLoader = false;
          });
          debugPrint('❌ CV ошибка: $error');
        }
        _isServiceBusy = false;
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

  Future<(ui.Image?, ui.Image?)> _prepareImagesFromCvResult(
      CVResultDto result) async {
    ui.Image? segmentationOverlay;
    ui.Image? paintedOverlay;

    // Проверяем качество segmentation маски перед созданием overlay
    bool shouldCreateSegmentationOverlay = false;
    if (result.segmentationMask != null) {
      final wallPixelCount =
          result.segmentationMask!.where((p) => p == 1).length;
      final wallPercentage = wallPixelCount / result.segmentationMask!.length;
      shouldCreateSegmentationOverlay =
          wallPercentage > 0.05 && wallPercentage < 0.95;

      if (!shouldCreateSegmentationOverlay) {
        debugPrint(
            '⚠️ Skipping segmentation overlay: ${(wallPercentage * 100).toStringAsFixed(1)}% walls');
      }
    }

    // Use Future.wait to create images in parallel for better performance
    await Future.wait([
      if (shouldCreateSegmentationOverlay && result.segmentationMask != null)
        _createImageFromMask(result.segmentationMask!, result.maskWidth,
                result.maskHeight, const Color.fromARGB(128, 33, 150, 243))
            .then((img) => segmentationOverlay = img),
      if (result.paintedMask != null)
        _createImageFromMask(result.paintedMask!, result.maskWidth,
                result.maskHeight, _selectedColor.withOpacity(0.7))
            .then((img) => paintedOverlay = img),
    ]);

    return (segmentationOverlay, paintedOverlay);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('❌ No cameras found on this device.');
        if (mounted) {
          _showErrorDialog(
              'Нет камеры', 'На этом устройстве не найдено доступных камер.');
        }
        return;
      }

      final camera = _cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first);

      // Dispose existing controller before creating a new one
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      final imageFormatGroup =
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.low, // ОБНОВЛЕНО
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      // Ensure the widget is still mounted before starting the stream
      if (!mounted) return;
      await _cameraController!.startImageStream((CameraImage image) {
        if (!mounted) return;
        _lastCameraImage = image;

        // Process CV for paint detection
        if (_isCVInitialized && !_isServiceBusy) {
          final didStart = _cvService.processCameraFrame(image);
          if (didStart) {
            _isServiceBusy = true;
          }
        }

        // Временно отключаем новую сегментацию - используем только старую модель в изоляте
        // Process segmentation every 30 frames to get wall mask (было 10)
        // _segmentationFrameCount++;
        // if (_isSegmentationInitialized && _segmentationFrameCount % 30 == 0) {
        //   _updateWallMask(image);
        // }
      });

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Ошибка инициализации камеры: $e');
      if (mounted) {
        _showErrorDialog(
            'Ошибка камеры', 'Не удалось инициализировать камеру: $e');
      }
    }
  }

  /// Обновляет маску стены с помощью модели сегментации
  void _updateWallMask(CameraImage image) {
    try {
      Uint8List? mask;

      // Используем текущую выбранную модель
      if (_currentModelIndex == 0 && _isSegmentationInitialized) {
        mask = _segmentationService.processCameraImage(image);
      } else if (_currentModelIndex > 0 && _isWallSegmentationInitialized) {
        mask = _wallSegmentationService.processCameraImage(image);
      }

      if (mask != null && mounted) {
        // Проверяем качество маски перед использованием
        final wallPixelCount = mask.where((p) => p == 1).length;
        final wallPercentage = wallPixelCount / mask.length;

        if (wallPercentage > 0.05 && wallPercentage < 0.95) {
          // Используем маску только если она содержит разумное количество стен
          setState(() {
            _currentWallMask = mask;
          });
          final modelType = _modelNames[_currentModelIndex];
          debugPrint(
              '✅ Wall mask updated using $modelType model (${mask.length} pixels, ${(wallPercentage * 100).toStringAsFixed(1)}% walls)');
        } else {
          // Не используем плохую маску, оставляем null для fallback
          setState(() {
            _currentWallMask = null;
          });
          debugPrint(
              '⚠️ Wall mask quality poor (${(wallPercentage * 100).toStringAsFixed(1)}% walls), skipping update');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating wall mask: $e');
    }
  }

  Future<void> _onTapScreen(TapDownDetails details) async {
    if (!_isCVInitialized ||
        _isServiceBusy ||
        _cameraController == null ||
        _lastCameraImage == null) {
      return;
    }

    HapticFeedback.lightImpact();

    // Get the size of the CameraPreview widget
    final RenderBox? previewBox =
        _cameraPreviewKey.currentContext?.findRenderObject() as RenderBox?;
    if (previewBox == null || !previewBox.hasSize) return;
    final previewSize = previewBox.size;

    final didStart = _cvService.paintWall(
      _lastCameraImage!,
      details.localPosition,
      previewSize,
      _selectedColor,
      wallMask: null, // Временно отключаем новую сегментацию
      maskWidth: null,
      maskHeight: null,
    );

    if (didStart) {
      _isServiceBusy = true;
      setState(() {
        _showPaintLoader = true;
        _lastTapPoint = details.localPosition;
      });
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
      _combinedPaintedOverlay = null; // Очищаем единый холст
      _segmentationOverlay = null; // Also clear segmentation
      _lastTapPoint = null;
      _frameCount = 0;
    });
  }

  Future<ui.Image> _mergeOverlays(
      {ui.Image? baseImage, required ui.Image newOverlay}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Используем размеры нового оверлея для результирующего изображения
    final targetWidth = newOverlay.width;
    final targetHeight = newOverlay.height;

    // If there's a base image, draw it first scaled to target size
    if (baseImage != null) {
      final srcRect = Rect.fromLTWH(
          0, 0, baseImage.width.toDouble(), baseImage.height.toDouble());
      final dstRect =
          Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
      canvas.drawImageRect(baseImage, srcRect, dstRect, Paint());
    }

    // Draw the new overlay on top.
    canvas.drawImage(newOverlay, Offset.zero, Paint());

    // End recording and return the new combined image.
    final picture = recorder.endRecording();
    return await picture.toImage(targetWidth, targetHeight);
  }

  Future<ui.Image> _createImageFromMask(
      Uint8List mask, int width, int height, Color color) async {
    final pixels = Uint32List(mask.length);
    for (int i = 0; i < mask.length; i++) {
      if (mask[i] == 1) {
        pixels[i] = color.value;
      } else {
        // Делаем пиксель полностью прозрачным вместо черного
        pixels[i] = 0x00000000; // Прозрачный черный (ARGB)
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
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
                  key: _cameraPreviewKey,
                  onTapDown: _onTapScreen,
                  child: Stack(
                    children: [
                      CameraPreview(_cameraController!),

                      // Combined painted wall overlay
                      if (_combinedPaintedOverlay != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WallPainter(
                              imageToPaint: _combinedPaintedOverlay!,
                            ),
                          ),
                        ),

                      // Segmentation overlay
                      if (_showSegmentation && _segmentationOverlay != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WallPainter(
                              imageToPaint: _segmentationOverlay!,
                            ),
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
          if (_showPaintLoader)
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
                    Text(
                      'Модель: ${_modelNames[_currentModelIndex]}',
                      style: TextStyle(
                        color: _modelColors[_currentModelIndex],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

                    // Model switch button
                    IconButton(
                      onPressed: () async {
                        if (_isServiceBusy)
                          return; // Не переключаем во время обработки

                        setState(() {
                          _currentModelIndex =
                              (_currentModelIndex + 1) % _modelNames.length;
                        });

                        // Перезагружаем модель
                        try {
                          if (_currentModelIndex == 0) {
                            await _segmentationService.loadModel();
                            _isSegmentationInitialized = true;
                            debugPrint(
                                '✅ Switched to ${_modelNames[_currentModelIndex]} model');
                          } else {
                            await _wallSegmentationService.loadModel(
                                modelIndex: _currentModelIndex);
                            _isWallSegmentationInitialized = true;
                            debugPrint(
                                '✅ Switched to ${_modelNames[_currentModelIndex]} model');
                          }
                        } catch (e) {
                          debugPrint('❌ Failed to switch model: $e');
                          // Возвращаем назад при ошибке
                          setState(() {
                            _currentModelIndex =
                                (_currentModelIndex - 1 + _modelNames.length) %
                                    _modelNames.length;
                          });
                        }
                      },
                      icon: Icon(
                        _currentModelIndex == 0
                            ? Icons.tune
                            : _currentModelIndex == 1
                                ? Icons.auto_awesome
                                : Icons.speed,
                        color: _modelColors[_currentModelIndex],
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

  WallPainter({
    required this.imageToPaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final srcRect = Rect.fromLTWH(
        0, 0, imageToPaint.width.toDouble(), imageToPaint.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(imageToPaint, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant WallPainter oldDelegate) {
    return oldDelegate.imageToPaint != imageToPaint;
  }
}
