import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// --- Data Transfer Objects (DTOs) ---

/// DTO для передачи данных из изолята в основной поток.
class CVResultDto {
  final Uint8List? segmentationMask;
  final Uint8List? paintedMask;
  final int processingTimeMs;
  final int maskWidth;
  final int maskHeight;
  final int imageWidth;
  final int imageHeight;

  CVResultDto({
    this.segmentationMask,
    this.paintedMask,
    required this.processingTimeMs,
    required this.maskWidth,
    required this.maskHeight,
    required this.imageWidth,
    required this.imageHeight,
  });
}

/// DTO для безопасной передачи данных кадра в изолят
class _CameraImageDTO {
  final List<Uint8List> planes;
  final int height;
  final int width;
  final ImageFormatGroup imageFormatGroup;

  _CameraImageDTO({
    required this.planes,
    required this.height,
    required this.width,
    required this.imageFormatGroup,
  });
}

/// DTO для передачи данных в изолят.
class IsolateInput {
  final _CameraImageDTO cameraImage;
  final ui.Offset? tapPoint;
  final ui.Color? color;
  IsolateInput(this.cameraImage, {this.tapPoint, this.color});
}

/// DTO для передачи данных для инициализации в изолят
class IsolateInitData {
  final SendPort toIsolate;
  final Uint8List modelBytes;
  final List<String> labels;

  IsolateInitData(this.toIsolate, this.modelBytes, this.labels);
}

// --- CV Wall Painter Service ---

class CVWallPainterService {
  static CVWallPainterService? _instance;
  static CVWallPainterService get instance =>
      _instance ??= CVWallPainterService._internal();

  CVWallPainterService._internal();

  // Состояние
  bool _isInitialized = false;
  CVResultDto? _lastResult;
  final Completer<void> _isolateReady = Completer<void>();
  Isolate? _isolate;
  SendPort? _sendPort;
  List<String> _labels = [];

  // Управление потоком кадров
  IsolateInput? _lastFrame;
  Timer? _cameraStreamTimer;

  bool get isInitialized => _isInitialized;
  CVResultDto? get lastResult => _lastResult;

  Function(CVResultDto)? _resultCallback;
  Function(String)? _errorCallback;

  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('🎨 Инициализация CV Wall Painter Service (с изолятом)');

    try {
      // 1. Загрузка модели и меток в основном потоке
      final modelData =
          await rootBundle.load('assets/ml/deeplabv3_ade20k_fp16.tflite');
      final labelsData =
          await rootBundle.loadString('assets/ml/ade20k_labels.txt');
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      // 2. Запуск изолята
      final fromIsolate = ReceivePort();
      final initData = IsolateInitData(
          fromIsolate.sendPort, modelData.buffer.asUint8List(), _labels);

      _isolate = await Isolate.spawn(_isolateEntry, initData);

      // 3. Обмен портами с изолятом
      fromIsolate.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          _isolateReady.complete();
        } else if (message is CVResultDto) {
          _lastResult = message;
          _resultCallback?.call(message);
        } else if (message is String) {
          _errorCallback?.call(message);
        }
      });

      await _isolateReady.future;
      _isInitialized = true;
      debugPrint('✅ CV Wall Painter Service и изолят готовы');
    } catch (e, s) {
      debugPrint('❌ Ошибка инициализации CV сервиса: $e\n$s');
      _errorCallback?.call('Ошибка инициализации: $e');
      rethrow;
    }
  }

  void setResultCallback(Function(CVResultDto) callback) {
    _resultCallback = callback;
  }

  void setErrorCallback(Function(String) callback) {
    _errorCallback = callback;
  }

  void startCameraStream() {
    debugPrint('📹 Обработка камеры управляется `updateCameraFrame`');
    _cameraStreamTimer?.cancel();
    _cameraStreamTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_lastFrame != null && _sendPort != null) {
        _sendPort!.send(_lastFrame);
        _lastFrame = null;
      }
    });
  }

  void stopCameraStream() {
    _cameraStreamTimer?.cancel();
  }

  void updateCameraFrame(CameraImage image) {
    if (!_isInitialized) return;
    final dto = _createImageDTO(image);
    if (dto != null) {
      _lastFrame = IsolateInput(dto);
    }
  }

  Future<void> paintWall(ui.Offset tapPoint, ui.Color color) async {
    if (!_isInitialized || _lastFrame == null) return;
    _sendPort?.send(IsolateInput(_lastFrame!.cameraImage,
        tapPoint: tapPoint, color: color));
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isInitialized = false;
    _cameraStreamTimer?.cancel();
    debugPrint('⏹️ CV сервис и изолят остановлены');
  }

  _CameraImageDTO? _createImageDTO(CameraImage image) {
    if (image.planes.isEmpty) return null;
    return _CameraImageDTO(
      planes: image.planes.map((p) => p.bytes).toList(),
      height: image.height,
      width: image.width,
      imageFormatGroup: image.format.group,
    );
  }

  // --- Isolate Logic ---

  static void _isolateEntry(IsolateInitData initData) async {
    final fromIsolate = ReceivePort();
    initData.toIsolate.send(fromIsolate.sendPort);

    Interpreter? interpreter;
    try {
      interpreter = Interpreter.fromBuffer(initData.modelBytes);
    } catch (e, s) {
      debugPrint('❌ Isolate: Не удалось создать Interpreter: $e\n$s');
      initData.toIsolate.send('ERROR: Failed to create interpreter');
      return;
    }

    final labels = initData.labels;

    await for (final input in fromIsolate) {
      if (input is IsolateInput) {
        final stopwatch = Stopwatch()..start();
        final result = _processFrame(input, interpreter, labels);
        stopwatch.stop();

        if (result != null) {
          final dto = CVResultDto(
            segmentationMask: result['segmentation_mask'],
            paintedMask: result['painted_mask'],
            processingTimeMs: stopwatch.elapsedMilliseconds,
            maskWidth: result['mask_width'],
            maskHeight: result['mask_height'],
            imageWidth: result['image_width'],
            imageHeight: result['image_height'],
          );
          initData.toIsolate.send(dto);
        }
      }
    }
  }

  static Map<String, dynamic>? _processFrame(
      IsolateInput input, Interpreter interpreter, List<String> labels) {
    try {
      final img.Image? baseImage = _convertCameraImage(input.cameraImage);
      if (baseImage == null) return null;

      final inputShape = interpreter.getInputTensor(0).shape;
      final modelInputSize = inputShape[1];
      final preprocessedImage = _preprocessImage(baseImage, modelInputSize);

      final inputBytes = _imageToFloat32List(preprocessedImage);
      final reshapedInput = inputBytes.reshape(inputShape);

      final outputShape = interpreter.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape(outputShape);

      interpreter.run(reshapedInput, output);

      final wallClassIndex = labels.indexOf('wall');
      if (wallClassIndex == -1) return null;

      final segmentationMask = _postprocessOutput(
          output[0], modelInputSize, modelInputSize, wallClassIndex);

      final wallPixelCount = segmentationMask.where((p) => p == 1).length;
      debugPrint(
          '🖼️ Isolate: Mask created with $wallPixelCount wall pixels out of ${segmentationMask.length}.');

      Uint8List? paintedMask;
      if (input.tapPoint != null && input.color != null) {
        paintedMask = _floodFill(
          segmentationMask,
          modelInputSize,
          modelInputSize,
          (input.tapPoint!.dx * (modelInputSize / baseImage.width)).toInt(),
          (input.tapPoint!.dy * (modelInputSize / baseImage.height)).toInt(),
        );
      }

      return {
        'segmentation_mask': segmentationMask,
        'painted_mask': paintedMask,
        'mask_width': modelInputSize,
        'mask_height': modelInputSize,
        'image_width': baseImage.width,
        'image_height': baseImage.height,
      };
    } catch (e, s) {
      debugPrint('❌ Ошибка в processFrame: $e\n$s');
      return null;
    }
  }

  static Float32List _imageToFloat32List(img.Image image) {
    var convertedBytes = Float32List(1 * image.height * image.width * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < image.height; i++) {
      for (var j = 0; j < image.width; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return convertedBytes;
  }

  static img.Image _preprocessImage(img.Image baseImage, int targetSize) {
    return img.copyResizeCropSquare(baseImage, size: targetSize);
  }

  static Uint8List _postprocessOutput(
      List<List<List<double>>> output, int width, int height, int classIndex) {
    final mask = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (output[y][x][classIndex] > 0.5) {
          mask[y * width + x] = 1;
        }
      }
    }
    return mask;
  }

  static Uint8List _floodFill(
      Uint8List mask, int width, int height, int startX, int startY) {
    if (startX < 0 || startX >= width || startY < 0 || startY >= height) {
      return Uint8List(0);
    }
    final filledMask = Uint8List(mask.length);
    final queue = <(int, int)>[];
    final startIndex = startY * width + startX;
    if (mask[startIndex] != 1) return Uint8List(0);
    queue.add((startX, startY));
    filledMask[startIndex] = 1;
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeAt(0);
      for (var d in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final nextX = x + d.$1;
        final nextY = y + d.$2;
        if (nextX >= 0 && nextX < width && nextY >= 0 && nextY < height) {
          final nextIndex = nextY * width + nextX;
          if (mask[nextIndex] == 1 && filledMask[nextIndex] == 0) {
            filledMask[nextIndex] = 1;
            queue.add((nextX, nextY));
          }
        }
      }
    }
    return filledMask;
  }

  static img.Image? _convertCameraImage(_CameraImageDTO dto) {
    if (dto.imageFormatGroup == ImageFormatGroup.yuv420) {
      return _convertYUV420(dto);
    } else if (dto.imageFormatGroup == ImageFormatGroup.bgra8888) {
      return img.Image.fromBytes(
        width: dto.width,
        height: dto.height,
        bytes: dto.planes[0].buffer,
        order: img.ChannelOrder.bgra,
      );
    }
    return null;
  }

  static img.Image _convertYUV420(_CameraImageDTO image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].length ~/ (height / 2);
    final int uvPixelStride = uvRowStride ~/ (width / 2);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final out = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvx = (x / 2).floor();
        final int uvy = (y / 2).floor();
        final int uvIndex = uvy * uvRowStride + uvx * uvPixelStride;
        final yValue = yPlane[yIndex];
        final uValue = uPlane[uvIndex];
        final vValue = vPlane[uvIndex];
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();
        out.setPixelRgb(x, y, r, g, b);
      }
    }
    return out;
  }
}
