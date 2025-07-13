import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// CV Wall Painter Service
/// Предоставляет сервис для покраски стен с использованием Computer Vision
/// и ADE20K датасета через TensorFlow Lite модель
class CVWallPainterService {
  static CVWallPainterService? _instance;
  static CVWallPainterService get instance =>
      _instance ??= CVWallPainterService._internal();

  CVWallPainterService._internal();

  // ML Configuration - BiseNet от Qualcomm
  static const String _modelPath = 'assets/Models/BiseNet.tflite';
  static const String _onnxModelPath = 'Models/BiseNet.onnx';
  static const String _labelsPath = 'assets/ml/labels.txt';

  // BiseNet Model parameters (оптимизированы для мобильных)
  static const int _inputWidth = 960; // BiseNet input: 720x960
  static const int _inputHeight = 720;
  static const int _wallClassIndex = 0; // 'wall' class для сегментации
  static const double _confidenceThreshold =
      0.6; // Повышенный порог для BiseNet
  static const int _numThreads = 4;

  // Performance settings - BiseNet оптимизация
  static const int _maxProcessingWidth =
      480; // Увеличиваем разрешение для BiseNet
  static const int _maxProcessingHeight = 360;
  static const Duration _processingInterval =
      Duration(milliseconds: 100); // Быстрее благодаря BiseNet

  // Service state
  bool _isInitialized = false;
  Interpreter? _interpreter;
  List<String> _labels = [];
  Timer? _processingTimer;
  bool _isProcessing = false;

  // Model I/O
  List<int>? _inputShape;
  List<int>? _outputShape;

  // Current processing
  CameraImage? _currentCameraImage;
  ui.Offset? _currentSeedPoint;
  ui.Color _currentPaintColor = const ui.Color(0xFF2196F3);

  // Result cache
  CVWallPaintResult? _lastResult;
  final List<PaintedArea> _paintedAreas = [];

  // Performance metrics
  int _lastProcessingTimeMs = 0;
  double _lastConfidence = 0.0;
  int _processedFrames = 0;

  // Callbacks
  Function(CVWallPaintResult)? _onResultCallback;
  Function(String)? _onErrorCallback;

  bool get isInitialized => _isInitialized;
  int get lastProcessingTimeMs => _lastProcessingTimeMs;
  double get lastConfidence => _lastConfidence;
  int get processedFrames => _processedFrames;
  List<PaintedArea> get paintedAreas => List.unmodifiable(_paintedAreas);

  /// Initialize the CV Wall Painter service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🎨 Инициализация CV Wall Painter Service (BiseNet)');

      // Load labels
      await _loadLabels();

      // Initialize BiseNet TensorFlow Lite model
      await _initializeModel();

      _isInitialized = true;
      debugPrint('✅ CV Wall Painter Service готов (BiseNet от Qualcomm)');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации CV сервиса: $e');
      _onErrorCallback?.call('Ошибка инициализации: $e');
      rethrow;
    }
  }

  /// Load class labels from assets
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      debugPrint('📋 Загружено ${_labels.length} классов, wall: ${_labels[0]}');
    } catch (e) {
      debugPrint('⚠️ Не удалось загрузить labels.txt: $e');
      // Fallback labels
      _labels = ['wall', 'building', 'sky', 'floor', 'tree', 'ceiling'];
    }
  }

  /// Initialize TensorFlow Lite model
  Future<void> _initializeModel() async {
    try {
      debugPrint('🧠 Загрузка BiseNet модели от Qualcomm...');

      final options = InterpreterOptions();
      options.threads = _numThreads;

      // Platform-specific optimizations
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final gpuDelegate = GpuDelegate();
          options.addDelegate(gpuDelegate);
          debugPrint('🚀 Android GPU ускорение включено');
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          options.threads = 2; // Conservative for iOS
          debugPrint('🍎 iOS CPU оптимизация');
        }
      } catch (e) {
        debugPrint('⚠️ Ускорение недоступно: $e');
      }

      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      _interpreter!.allocateTensors();

      // Get model shapes
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('📐 Input shape: $_inputShape');
      debugPrint('📐 Output shape: $_outputShape');

      // Validate model
      if (_inputShape == null || _outputShape == null) {
        throw Exception('Некорректные размеры модели');
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки модели: $e');
      rethrow;
    }
  }

  /// Set result callback
  void setResultCallback(Function(CVWallPaintResult) callback) {
    _onResultCallback = callback;
  }

  /// Set error callback
  void setErrorCallback(Function(String) callback) {
    _onErrorCallback = callback;
  }

  /// Start processing camera stream
  void startCameraStream() {
    if (!_isInitialized) return;

    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(_processingInterval, (timer) {
      if (!_isProcessing && _currentCameraImage != null) {
        _processCurrentFrame();
      }
    });

    debugPrint('📹 Запуск обработки камеры');
  }

  /// Stop processing camera stream
  void stopCameraStream() {
    _processingTimer?.cancel();
    _processingTimer = null;
    debugPrint('⏹️ Остановка обработки камеры');
  }

  /// Update camera frame
  void updateCameraFrame(CameraImage cameraImage) {
    if (_isInitialized && !_isProcessing) {
      _currentCameraImage = cameraImage;
    }
  }

  /// Paint wall at specified point
  Future<void> paintWall(ui.Offset tapPoint, ui.Color color) async {
    if (!_isInitialized || _isProcessing) return;

    _currentSeedPoint = tapPoint;
    _currentPaintColor = color;

    // Trigger immediate processing
    await _processCurrentFrame();
  }

  /// Process current camera frame
  Future<void> _processCurrentFrame() async {
    if (_isProcessing || _currentCameraImage == null) return;

    _isProcessing = true;
    final stopwatch = Stopwatch()..start();

    try {
      // Convert camera image to processable format
      final rgbImage = _convertCameraImage(_currentCameraImage!);
      if (rgbImage == null) {
        _isProcessing = false;
        return;
      }

      // Resize for performance
      final processedImage = _resizeImage(rgbImage);

      // Run segmentation
      final segmentationMask = await _runSegmentation(processedImage);
      if (segmentationMask == null) {
        _isProcessing = false;
        return;
      }

      // Extract wall regions
      final wallMask = _extractWallMask(segmentationMask);

      // Create segmentation visualization
      final segmentationOverlay = await _createSegmentationVisualization(
          segmentationMask, processedImage.width, processedImage.height);

      // Apply paint color if seed point is provided
      ui.Image? paintedImage;
      if (_currentSeedPoint != null) {
        paintedImage = await _applyPaintColor(
            processedImage, wallMask, _currentSeedPoint!, _currentPaintColor);

        // Add to painted areas
        _addPaintedArea(_currentSeedPoint!, _currentPaintColor);
      }

      stopwatch.stop();

      // Update metrics
      _lastProcessingTimeMs = stopwatch.elapsedMilliseconds;
      _lastConfidence = _calculateConfidence(wallMask);
      _processedFrames++;

      // Create result
      final result = CVWallPaintResult(
        originalImage: await _convertToUiImage(processedImage),
        paintedImage: paintedImage,
        segmentationOverlay: segmentationOverlay,
        wallMask: _convertMaskToPath(wallMask),
        seedPoint: _currentSeedPoint,
        paintColor: _currentPaintColor,
        processingTimeMs: _lastProcessingTimeMs,
        confidence: _lastConfidence,
        wallAreas: _findWallAreas(wallMask),
      );

      _lastResult = result;
      _onResultCallback?.call(result);

      // Reset seed point after processing
      _currentSeedPoint = null;
    } catch (e) {
      debugPrint('❌ Ошибка обработки кадра: $e');
      _onErrorCallback?.call('Ошибка обработки: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert camera image to RGB format
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      // Debug camera format (temporarily disabled to reduce spam)
      // debugPrint('📷 Camera format: ${cameraImage.format.group}');
      // debugPrint('📷 Planes: ${cameraImage.planes.length}');

      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToRGB(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRAToRGB(cameraImage);
      } else {
        debugPrint(
            '❌ Неподдерживаемый формат камеры: ${cameraImage.format.group}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Ошибка конвертации изображения: $e');
      return null;
    }
  }

  /// Convert YUV420 to RGB
  img.Image _convertYUV420ToRGB(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;

        // UV indices for subsampled planes
        final uvY = y ~/ 2;
        final uvX = x ~/ 2;

        // Check if UV planes are interleaved (iOS format)
        int uIndex, vIndex;
        if (uPlane.bytesPerPixel == 2) {
          // Interleaved UV (UVUV...)
          final uvIndex = uvY * uPlane.bytesPerRow + uvX * 2;
          uIndex = uvIndex;
          vIndex = uvIndex + 1;
        } else {
          // Separate U and V planes
          uIndex = uvY * uPlane.bytesPerRow + uvX;
          vIndex = uvY * vPlane.bytesPerRow + uvX;
        }

        if (yIndex < yPlane.bytes.length &&
            uIndex < uPlane.bytes.length &&
            (uPlane.bytesPerPixel == 2
                ? vIndex < uPlane.bytes.length
                : vIndex < vPlane.bytes.length)) {
          final yValue = yPlane.bytes[yIndex];
          final uValue = uPlane.bytes[uIndex];
          final vValue = uPlane.bytesPerPixel == 2
              ? uPlane.bytes[vIndex]
              : vPlane.bytes[vIndex];

          // YUV to RGB conversion
          final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
          final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128))
              .clamp(0, 255)
              .toInt();
          final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

          image.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    return image;
  }

  /// Convert BGRA to RGB
  img.Image _convertBGRAToRGB(CameraImage cameraImage) {
    final bytes = cameraImage.planes[0].bytes;
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  /// Resize image for processing
  img.Image _resizeImage(img.Image image) {
    final currentWidth = image.width;
    final currentHeight = image.height;

    if (currentWidth <= _maxProcessingWidth &&
        currentHeight <= _maxProcessingHeight) {
      return image;
    }

    final aspectRatio = currentWidth / currentHeight;
    int newWidth, newHeight;

    if (aspectRatio > 1) {
      newWidth = _maxProcessingWidth;
      newHeight = (_maxProcessingWidth / aspectRatio).round();
    } else {
      newHeight = _maxProcessingHeight;
      newWidth = (_maxProcessingHeight * aspectRatio).round();
    }

    return img.copyResize(image, width: newWidth, height: newHeight);
  }

  /// Run segmentation on image
  Future<List<List<double>>?> _runSegmentation(img.Image image) async {
    if (_interpreter == null || _inputShape == null || _outputShape == null) {
      return null;
    }

    try {
      // Prepare input
      final inputData = _prepareInput(image);
      if (inputData == null) return null;

      // Prepare output
      final outputData = _prepareOutput();

      // Run inference
      _interpreter!.run(inputData, outputData);

      // Convert output to segmentation mask
      return _parseOutput(outputData, image.width, image.height);
    } catch (e) {
      debugPrint('❌ Ошибка ML inference: $e');
      return null;
    }
  }

  /// Prepare input for model
  Float32List? _prepareInput(img.Image image) {
    if (_inputShape == null || _inputShape!.length != 4) return null;

    final inputHeight = _inputShape![1];
    final inputWidth = _inputShape![2];
    final channels = _inputShape![3];

    // Resize to model input size
    final resizedImage =
        img.copyResize(image, width: inputWidth, height: inputHeight);

    // Convert to float32 array
    final inputSize = inputHeight * inputWidth * channels;
    final input = Float32List(inputSize);

    int pixelIndex = 0;
    for (int y = 0; y < inputHeight; y++) {
      for (int x = 0; x < inputWidth; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Normalize to [0, 1] range
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  /// Prepare output buffer
  Float32List _prepareOutput() {
    if (_outputShape == null) return Float32List(0);

    final outputSize = _outputShape!.fold(1, (prev, element) => prev * element);
    return Float32List(outputSize);
  }

  /// Parse model output
  List<List<double>> _parseOutput(
      Float32List outputData, int width, int height) {
    // Convert flattened output to 2D segmentation probabilities
    final segmentationMask = <List<double>>[];

    // This is a simplified version - actual implementation depends on model output format
    for (int y = 0; y < height; y++) {
      final row = <double>[];
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (index < outputData.length) {
          row.add(outputData[index]);
        } else {
          row.add(0.0);
        }
      }
      segmentationMask.add(row);
    }

    return segmentationMask;
  }

  /// Extract wall mask from segmentation
  List<List<bool>> _extractWallMask(List<List<double>> segmentation) {
    final wallMask = <List<bool>>[];

    for (final row in segmentation) {
      final boolRow = <bool>[];
      for (final value in row) {
        boolRow.add(value > _confidenceThreshold);
      }
      wallMask.add(boolRow);
    }

    return wallMask;
  }

  /// Apply paint color to wall areas
  Future<ui.Image> _applyPaintColor(
    img.Image originalImage,
    List<List<bool>> wallMask,
    ui.Offset seedPoint,
    ui.Color paintColor,
  ) async {
    final paintedImage = img.Image.from(originalImage);

    // Convert seed point to mask coordinates
    final maskX =
        (seedPoint.dx / originalImage.width * wallMask[0].length).round();
    final maskY =
        (seedPoint.dy / originalImage.height * wallMask.length).round();

    // Check if seed point is on wall
    if (maskY < wallMask.length &&
        maskX < wallMask[0].length &&
        wallMask[maskY][maskX]) {
      // Apply color to wall areas with alpha blending
      for (int y = 0; y < originalImage.height; y++) {
        for (int x = 0; x < originalImage.width; x++) {
          final maskY = (y / originalImage.height * wallMask.length).round();
          final maskX = (x / originalImage.width * wallMask[0].length).round();

          if (maskY < wallMask.length &&
              maskX < wallMask[0].length &&
              wallMask[maskY][maskX]) {
            final originalPixel = originalImage.getPixel(x, y);
            final blendedColor = _blendColors(
              img.ColorRgb8(originalPixel.r.toInt(), originalPixel.g.toInt(),
                  originalPixel.b.toInt()),
              img.ColorRgb8(paintColor.red, paintColor.green, paintColor.blue),
              0.6, // Alpha for paint
            );
            paintedImage.setPixel(x, y, blendedColor);
          }
        }
      }
    }

    return _convertToUiImage(paintedImage);
  }

  /// Blend two colors with alpha
  img.Color _blendColors(img.Color original, img.Color paint, double alpha) {
    final r = ((1 - alpha) * original.r + alpha * paint.r).round();
    final g = ((1 - alpha) * original.g + alpha * paint.g).round();
    final b = ((1 - alpha) * original.b + alpha * paint.b).round();
    return img.ColorRgb8(r, g, b);
  }

  /// Convert image to UI Image
  Future<ui.Image> _convertToUiImage(img.Image image) async {
    final bytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Convert mask to UI Path
  ui.Path _convertMaskToPath(List<List<bool>> mask) {
    final path = ui.Path();

    for (int y = 0; y < mask.length; y++) {
      for (int x = 0; x < mask[0].length; x++) {
        if (mask[y][x]) {
          path.addRect(ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.0, 1.0));
        }
      }
    }

    return path;
  }

  /// Calculate confidence score
  double _calculateConfidence(List<List<bool>> mask) {
    int totalPixels = 0;
    int wallPixels = 0;

    for (final row in mask) {
      for (final pixel in row) {
        totalPixels++;
        if (pixel) wallPixels++;
      }
    }

    return totalPixels > 0 ? wallPixels / totalPixels : 0.0;
  }

  /// Create colorful segmentation visualization
  Future<ui.Image> _createSegmentationVisualization(
      List<List<double>> segmentation, int width, int height) async {
    // Define colors for different classes (like in the image shown)
    final classColors = [
      img.ColorRgb8(0, 0, 0), // 0: background (black)
      img.ColorRgb8(255, 0, 0), // 1: wall (red)
      img.ColorRgb8(0, 255, 0), // 2: floor (green)
      img.ColorRgb8(0, 0, 255), // 3: ceiling (blue)
      img.ColorRgb8(255, 255, 0), // 4: door (yellow)
      img.ColorRgb8(255, 0, 255), // 5: window (magenta)
      img.ColorRgb8(0, 255, 255), // 6: cabinet (cyan)
      img.ColorRgb8(128, 128, 128), // 7: bed (gray)
      img.ColorRgb8(255, 128, 0), // 8: chair (orange)
      img.ColorRgb8(128, 255, 0), // 9: sofa (lime)
      img.ColorRgb8(128, 0, 255), // 10: table (purple)
      img.ColorRgb8(255, 128, 128), // 11: other (light red)
    ];

    final overlayImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Map coordinates to segmentation mask
        final segY = (y / height * segmentation.length)
            .clamp(0, segmentation.length - 1)
            .toInt();
        final segX = (x / width * segmentation[0].length)
            .clamp(0, segmentation[0].length - 1)
            .toInt();

        // Get the class with highest probability
        int maxClass = 0;
        double maxProb = segmentation[segY][segX];

        // For BiseNet output, we might need to process multiple channels
        // For now, use simple thresholding
        if (maxProb > _confidenceThreshold) {
          maxClass = 1; // Wall class
        }

        // Apply color with transparency for overlay
        final color = classColors[maxClass.clamp(0, classColors.length - 1)];
        if (maxClass > 0) {
          // Apply semi-transparent color for detected classes
          overlayImage.setPixelRgba(x, y, color.r, color.g, color.b, 128);
        } else {
          // Transparent for background
          overlayImage.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    return _convertToUiImage(overlayImage);
  }

  /// Find wall areas
  List<WallArea> _findWallAreas(List<List<bool>> mask) {
    // Simplified implementation - returns single area
    return [
      WallArea(
        bounds: ui.Rect.fromLTWH(
            0, 0, mask[0].length.toDouble(), mask.length.toDouble()),
        confidence: _lastConfidence,
        pixelCount: mask.expand((row) => row).where((pixel) => pixel).length,
      )
    ];
  }

  /// Add painted area to history
  void _addPaintedArea(ui.Offset point, ui.Color color) {
    _paintedAreas.add(PaintedArea(
      point: point,
      color: color,
      timestamp: DateTime.now(),
    ));
  }

  /// Clear all painted areas
  void clearPaintedAreas() {
    _paintedAreas.clear();
  }

  /// Get last result
  CVWallPaintResult? getLastResult() {
    return _lastResult;
  }

  /// Dispose resources
  void dispose() {
    _processingTimer?.cancel();
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _paintedAreas.clear();
    debugPrint('🧹 CV Wall Painter Service disposed');
  }
}

/// CV Wall Paint Result
class CVWallPaintResult {
  final ui.Image originalImage;
  final ui.Image? paintedImage;
  final ui.Image? segmentationOverlay; // Цветная визуализация сегментации
  final ui.Path wallMask;
  final ui.Offset? seedPoint;
  final ui.Color paintColor;
  final int processingTimeMs;
  final double confidence;
  final List<WallArea> wallAreas;

  CVWallPaintResult({
    required this.originalImage,
    this.paintedImage,
    this.segmentationOverlay,
    required this.wallMask,
    this.seedPoint,
    required this.paintColor,
    required this.processingTimeMs,
    required this.confidence,
    required this.wallAreas,
  });
}

/// Wall Area
class WallArea {
  final ui.Rect bounds;
  final double confidence;
  final int pixelCount;

  WallArea({
    required this.bounds,
    required this.confidence,
    required this.pixelCount,
  });
}

/// Painted Area
class PaintedArea {
  final ui.Offset point;
  final ui.Color color;
  final DateTime timestamp;

  PaintedArea({
    required this.point,
    required this.color,
    required this.timestamp,
  });
}
