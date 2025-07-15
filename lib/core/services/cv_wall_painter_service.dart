import 'dart:async';
import 'dart:io';
import 'dart:isolate';
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

  // ML Configuration - Reverting to the stable DeepLabV3 model for stability.
  static const String _modelPath =
      'assets/ml/deeplabv3_ade20k_fp16.tflite'; // ОБНОВЛЕНО
  static const String _labelsPath =
      'assets/ml/ade20k_labels.txt'; // НУЖЕН НОВЫЙ ФАЙЛ ЛЕЙБЛОВ

  // DeepLabV3 Model parameters
  static const int _inputWidth = 513; // ОБНОВЛЕНО
  static const int _inputHeight = 513; // ОБНОВЛЕНО
  // В ADE20K 'wall' имеет индекс 12
  static const int _wallClassIndex = 12; // ОБНОВЛЕНО
  static const double _confidenceThreshold = 0.5; // Standard threshold
  static const int _numThreads = 4;

  // Performance settings - Adjusted for DeepLabV3
  static const int _maxProcessingWidth = 513; // ОБНОВЛЕНО
  static const int _maxProcessingHeight = 513; // ОБНОВЛЕНО
  static const Duration _processingInterval = Duration(milliseconds: 200);

  // Service state
  bool _isInitialized = false;
  Interpreter? _interpreter;
  // IsolateInterpreter disabled for stability.
  // IsolateInterpreter? _isolateInterpreter;
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
  CVWallPaintResult? get lastResult => _lastResult; // Public getter
  int get lastProcessingTimeMs => _lastProcessingTimeMs;
  double get lastConfidence => _lastConfidence;
  int get processedFrames => _processedFrames;
  List<PaintedArea> get paintedAreas => List.unmodifiable(_paintedAreas);

  /// Initialize the CV Wall Painter service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(
          '🎨 Инициализация CV Wall Painter Service (DeepLabV3 - Stable)');

      // Load labels
      await _loadLabels();

      // Initialize DeepLabV3 TensorFlow Lite model
      await _initializeModel();

      _isInitialized = true;
      debugPrint('✅ CV Wall Painter Service готов (DeepLabV3 - Stable)');
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
      debugPrint(
          '📋 Загружено ${_labels.length} классов, "красим": ${_labels[0]}');
    } catch (e) {
      debugPrint('⚠️ Не удалось загрузить labels.txt: $e');
      // Fallback labels
      _labels = [
        'background',
        'aeroplane',
        'bicycle',
        'bird',
        'boat',
        'bottle'
      ];
    }
  }

  /// Initialize TensorFlow Lite model
  Future<void> _initializeModel() async {
    try {
      debugPrint('🧠 Загрузка DeepLabV3 модели (на CPU)...');

      final options = InterpreterOptions()..threads = _numThreads;

      // Create the main interpreter for main thread execution.
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);

      // Get I/O shapes from the model and allocate tensors.
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      _interpreter!.allocateTensors();

      debugPrint('📐 Input shape (NHWC): $_inputShape');
      debugPrint('📐 Output shape: $_outputShape');
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
      final rgbImage = await _convertCameraImage(_currentCameraImage!);
      if (rgbImage == null) {
        _isProcessing = false;
        return;
      }

      // Resize for performance
      final processedImage = _resizeImage(rgbImage);

      // Run inference in the background
      final segmentationMaskBytes = await _runInference(processedImage);
      if (segmentationMaskBytes == null) {
        _isProcessing = false;
        return;
      }

      // Create segmentation visualization
      final segmentationOverlay = await _createSegmentationVisualization(
          segmentationMaskBytes, processedImage.width, processedImage.height);

      // Apply paint color if seed point is provided
      ui.Image? paintedImage;

      // NEW: Create a painted overlay image instead of a path
      final paintedOverlay = await _createPaintedOverlay(
          segmentationMaskBytes, processedImage.width, processedImage.height);

      stopwatch.stop();

      // Update metrics
      _lastProcessingTimeMs = stopwatch.elapsedMilliseconds;
      _processedFrames++;

      // Create result object
      final result = CVWallPaintResult(
        originalImage: processedImage,
        segmentationOverlay: segmentationOverlay,
        paintedImage: paintedImage,
        paintedOverlay: paintedOverlay, // NEW
        processingTimeMs: _lastProcessingTimeMs,
      );

      _lastResult = result;

      // Send result to UI
      _onResultCallback?.call(result);

      // Clear one-time seed point
      _currentSeedPoint = null;
    } catch (e) {
      debugPrint('❌ Ошибка обработки кадра: $e');
      _onErrorCallback?.call('Ошибка обработки кадра: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Converts the image to a byte list (Float32List) for the model input.
  /// Normalization to [0, 1] is a common practice.
  Uint8List _imageToUint8List(img.Image image, int width, int height) {
    final resizedImage = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
    final bytes = Uint8List(1 * width * height * 3);
    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = resizedImage.getPixel(x, y);
        bytes[i++] = pixel.r.toInt();
        bytes[i++] = pixel.g.toInt();
        bytes[i++] = pixel.b.toInt();
      }
    }
    return bytes;
  }

  /// NEW: Creates a painted overlay as a ui.Image
  Future<ui.Image> _createPaintedOverlay(
    Uint8List segmentationMask,
    int width,
    int height,
  ) async {
    // These are the values we will pass to the isolate.
    // They are all "sendable" types (int, Uint8List).
    final int colorValue = _currentPaintColor.value;
    final int wallIndex = _wallClassIndex;

    // Isolate.run will take care of spawning the isolate and passing the message.
    final pngBytes = await Isolate.run(() {
      // This code runs in the new isolate.
      // It can only access the variables passed to it.
      final image = img.Image(width: width, height: height, numChannels: 4);
      final color = ui.Color(colorValue);

      // Make it semi-transparent for better visualization
      const double paintOpacity = 0.7;
      final int red = color.red;
      final int green = color.green;
      final int blue = color.blue;
      final int alpha = (color.alpha * paintOpacity).toInt();

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final index = y * width + x;
          if (segmentationMask[index] == wallIndex) {
            image.setPixelRgba(x, y, red, green, blue, alpha);
          }
        }
      }
      return img.encodePng(image);
    });

    // This code runs back in the main isolate.
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Convert CameraImage to img.Image (RGB)
  Future<img.Image?> _convertCameraImage(CameraImage cameraImage) async {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(cameraImage);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка конвертации изображения: $e');
      _onErrorCallback?.call('Ошибка конвертации изображения: $e');
      return null;
    }
  }

  img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  img.Image _convertYUV420(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final yuv420Image = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        final r = (yp + 1.402 * (vp - 128)).toInt().clamp(0, 255);
        final g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128))
            .toInt()
            .clamp(0, 255);
        final b = (yp + 1.772 * (up - 128)).toInt().clamp(0, 255);

        yuv420Image.setPixelRgb(x, y, r, g, b);
      }
    }
    return yuv420Image;
  }

  /// Resize image for model input
  img.Image _resizeImage(img.Image image) {
    final currentWidth = image.width;
    final currentHeight = image.height;

    // If image is already smaller than our processing size, no need to resize.
    if (currentWidth <= _maxProcessingWidth &&
        currentHeight <= _maxProcessingHeight) {
      return image;
    }

    final aspectRatio = currentWidth / currentHeight;
    int newWidth, newHeight;

    if (currentWidth > currentHeight) {
      // Landscape or square
      newWidth = _maxProcessingWidth;
      newHeight = (newWidth / aspectRatio).round();
    } else {
      // Portrait
      newHeight = _maxProcessingHeight;
      newWidth = (newHeight * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Runs inference on the given image using the isolate interpreter.
  Future<Uint8List?> _runInference(img.Image image) async {
    if (_interpreter == null) {
      debugPrint('❌ Interpreter не инициализирован.');
      return null;
    }

    // --- NEW LOGIC FOR DYNAMIC SHAPE & UINT8 INPUT ---

    // 1. Resize input tensor for dynamic model
    final inputHeight = image.height;
    final inputWidth = image.width;
    try {
      _interpreter!.resizeInputTensor(0, [1, inputHeight, inputWidth, 3]);
      _interpreter!.allocateTensors();
    } catch (e) {
      debugPrint("❌ Ошибка при изменении размера тензора: $e");
      return null;
    }

    // 2. Prepare Uint8 input data
    final inputBytes = _imageToUint8List(image, inputWidth, inputHeight);
    final input = inputBytes.reshape([1, inputHeight, inputWidth, 3]);

    // 3. Prepare output buffer (model output is int64)
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.filled(outputShape.reduce((a, b) => a * b), 0)
        .reshape(outputShape);

    // 4. Run inference
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      debugPrint("❌ Ошибка при выполнении модели в основном потоке: $e");
      return null;
    }

    // 5. Post-process the output
    // The output is a segmentation mask with class indices (int64).
    // Flatten it and convert to Uint8List.
    final segmentationMask = Uint8List(outputShape[1] * outputShape[2]);
    int i = 0;
    for (final pixelRow in output[0]) {
      // output is List<List<int>>
      for (final classIndex in pixelRow) {
        segmentationMask[i++] = classIndex.toInt();
      }
    }
    return segmentationMask;
  }

  /// Convert img.Image to byte list for TensorFlow Lite model
  Uint8List _imageToByteList(img.Image image) {
    final byteList = Uint8List(image.length);
    for (int i = 0; i < image.length; i++) {
      byteList[i] = image.getBytes()[i];
    }
    return byteList;
  }

  /// Create a visual representation of the segmentation mask
  Future<ui.Image> _createSegmentationVisualization(
      Uint8List segmentationMask, int width, int height) async {
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

    final pixels = Uint8List(width * height * 4);
    for (int i = 0; i < pixels.length; i += 4) {
      final y = i ~/ (width * 4);
      final x = (i % (width * 4)) ~/ 4;
      final classIndex = segmentationMask[y * width + x];
      final color = classColors[classIndex.clamp(0, classColors.length - 1)];
      pixels[i] = color.r.toInt();
      pixels[i + 1] = color.g.toInt();
      pixels[i + 2] = color.b.toInt();
      pixels[i + 3] = color.a.toInt();
    }

    // Create ui.Image from pixels
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

  /// Applies paint color to a given path on an image
  Future<ui.Image> _applyPaintColor(img.Image image, ui.Color color) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    // This part needs to be adapted to use the new overlay method,
    // not a path. For now, it is not called.
    // canvas.drawImage(image, ui.Offset.zero, ui.Paint());
    // canvas.drawPath(
    //     wallMask,
    //     ui.Paint()
    //       ..color = color
    //       ..style = ui.PaintingStyle.fill);

    return recorder.endRecording().toImage(image.width, image.height);
  }

  /// Adds a painted area to the list
  void _addPaintedArea(ui.Offset point, ui.Color color) {
    // For now, we don't store the path to avoid complexity.
    // This can be added back later if needed.
    _paintedAreas.add(PaintedArea(
        seedPoint: point, color: color, timestamp: DateTime.now(), path: null));
  }

  /// Calculate confidence of the wall segmentation
  double _calculateConfidence(Uint8List segmentationMask, int wallClassIndex) {
    if (segmentationMask.isEmpty) return 0.0;
    int wallPixels =
        segmentationMask.where((pixel) => pixel == wallClassIndex).length;
    return wallPixels / segmentationMask.length;
  }

  /// Convert img.Image to ui.Image
  Future<ui.Image> _convertImageToUiImage(img.Image image) async {
    final bytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 CV Wall Painter Service disposing');
    _processingTimer?.cancel();
    _interpreter?.close();
    debugPrint('🧹 CV Wall Painter Service disposed');
  }
}

/// Represents the result of a wall painting operation
class CVWallPaintResult {
  final img.Image originalImage;
  final ui.Image segmentationOverlay;
  final ui.Image? paintedImage;
  final ui.Image? paintedOverlay; // NEW
  final int processingTimeMs;

  CVWallPaintResult({
    required this.originalImage,
    required this.segmentationOverlay,
    this.paintedImage,
    this.paintedOverlay, // NEW
    required this.processingTimeMs,
  });
}

/// Represents a painted area on the wall
class PaintedArea {
  final ui.Offset seedPoint;
  final ui.Color color;
  final DateTime timestamp;
  final ui.Path? path;

  PaintedArea(
      {required this.seedPoint,
      required this.color,
      required this.timestamp,
      this.path});
}
