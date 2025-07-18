import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
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
  final ui.Size? previewSize; // РАЗМЕР ВИДЖЕТА КАМЕРЫ
  final ui.Color? color;
  final Uint8List? wallMask; // Маска стены от сегментации
  final int? maskWidth; // Ширина маски
  final int? maskHeight; // Высота маски

  IsolateInput(
    this.cameraImage, {
    this.tapPoint,
    this.previewSize,
    this.color,
    this.wallMask,
    this.maskWidth,
    this.maskHeight,
  });
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
  bool _isBusy = false;

  // Управление потоком кадров
  // IsolateInput? _lastFrame;
  // Timer? _cameraStreamTimer;

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
          _isBusy = false;
          _resultCallback?.call(message);
        } else if (message is String) {
          _isBusy = false;
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

  bool processCameraFrame(CameraImage image) {
    if (!_isInitialized || _isBusy) return false;

    _isBusy = true;
    final dto = _createImageDTO(image);
    if (dto != null) {
      _sendPort?.send(IsolateInput(dto));
      return true;
    } else {
      _isBusy = false;
      return false;
    }
  }

  bool paintWall(
    CameraImage image,
    ui.Offset tapPoint,
    ui.Size previewSize,
    ui.Color color, {
    Uint8List? wallMask,
    int? maskWidth,
    int? maskHeight,
  }) {
    if (!_isInitialized || _isBusy) return false;

    _isBusy = true;
    final dto = _createImageDTO(image);
    if (dto != null) {
      _sendPort?.send(IsolateInput(
        dto,
        tapPoint: tapPoint,
        previewSize: previewSize,
        color: color,
        wallMask: wallMask,
        maskWidth: maskWidth,
        maskHeight: maskHeight,
      ));
      return true;
    } else {
      _isBusy = false;
      return false;
    }
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isInitialized = false;
    _isBusy = false;
    debugPrint('⏹️ CV сервис и изолят остановлены');
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

        // КОНВЕРТАЦИЯ ПЕРЕНЕСЕНА В ИЗОЛЯТ
        final img.Image? baseImage = _convertCameraImage(input.cameraImage);
        if (baseImage == null) {
          initData.toIsolate.send('ERROR: Failed to convert camera image.');
          continue;
        }

        final result = _processImage(
          baseImage,
          interpreter,
          labels,
          input.tapPoint,
          input.previewSize,
          input.color,
          wallMask: input.wallMask,
          maskWidth: input.maskWidth,
          maskHeight: input.maskHeight,
        );

        stopwatch.stop();

        if (result != null) {
          final dto = CVResultDto(
            segmentationMask: result['segmentation_mask'],
            paintedMask: result['painted_mask'],
            processingTimeMs: stopwatch.elapsedMilliseconds,
            maskWidth: result['mask_width'],
            maskHeight: result['mask_height'],
            imageWidth: baseImage.width,
            imageHeight: baseImage.height,
          );
          initData.toIsolate.send(dto);
        }
      }
    }
  }

  static Map<String, dynamic>? _processImage(
    img.Image baseImage,
    Interpreter interpreter,
    List<String> labels,
    ui.Offset? tapPoint,
    ui.Size? previewSize,
    ui.Color? color, {
    Uint8List? wallMask,
    int? maskWidth,
    int? maskHeight,
  }) {
    try {
      // Use provided wall mask or create one using the model
      Uint8List segmentationMask;
      int effectiveMaskWidth;
      int effectiveMaskHeight;

      if (wallMask != null && maskWidth != null && maskHeight != null) {
        // Проверяем качество переданной маски
        final wallPixelCount = wallMask.where((p) => p == 1).length;
        final wallPercentage = wallPixelCount / wallMask.length;

        // Используем переданную маску только если она содержит разумное количество стен (1-80%)
        if (wallPercentage > 0.05 && wallPercentage < 0.95) {
          segmentationMask = wallMask;
          effectiveMaskWidth = maskWidth;
          effectiveMaskHeight = maskHeight;
          debugPrint(
              '🖼️ Isolate: Using provided wall mask (${maskWidth}x${maskHeight}, ${(wallPercentage * 100).toStringAsFixed(1)}% walls)');
        } else {
          debugPrint(
              '⚠️ Isolate: Wall mask quality poor (${(wallPercentage * 100).toStringAsFixed(1)}% walls), falling back to model');
          // Fallback to model-based segmentation
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

          segmentationMask = _postprocessOutput(
              output[0], modelInputSize, modelInputSize, wallClassIndex);
          effectiveMaskWidth = modelInputSize;
          effectiveMaskHeight = modelInputSize;
        }
      } else {
        // Fallback to the original model-based segmentation
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

        segmentationMask = _postprocessOutput(
            output[0], modelInputSize, modelInputSize, wallClassIndex);
        effectiveMaskWidth = modelInputSize;
        effectiveMaskHeight = modelInputSize;
      }

      final wallPixelCount = segmentationMask.where((p) => p == 1).length;
      debugPrint(
          '🖼️ Isolate: Mask created with $wallPixelCount wall pixels out of ${segmentationMask.length}.');

      // --- Flood Fill ---
      Uint8List? paintedMask;
      if (tapPoint != null && previewSize != null) {
        final transformedPoint = _transformTapPoint(tapPoint, previewSize,
            Size(baseImage.width.toDouble(), baseImage.height.toDouble()));

        final int tapX =
            (transformedPoint.dx * (effectiveMaskWidth / baseImage.width))
                .toInt();
        final int tapY =
            (transformedPoint.dy * (effectiveMaskHeight / baseImage.height))
                .toInt();
        paintedMask = _floodFill(segmentationMask, effectiveMaskWidth,
            effectiveMaskHeight, tapX, tapY);

        if (paintedMask != null) {
          final paintedPixelCount = paintedMask.where((p) => p == 1).length;
          final paintPercentage =
              (paintedPixelCount / paintedMask.length * 100).toStringAsFixed(1);
          debugPrint(
              '🎨 Paint applied: $paintedPixelCount/${paintedMask.length} pixels ($paintPercentage%)');
          debugPrint(
              '📍 Tap coordinates: screen($tapPoint) -> image($tapX, $tapY)');
        }
      }

      return {
        'segmentation_mask': segmentationMask,
        'painted_mask': paintedMask,
        'mask_width': effectiveMaskWidth,
        'mask_height': effectiveMaskHeight,
        'image_width': baseImage.width,
        'image_height': baseImage.height,
      };
    } catch (e, s) {
      debugPrint('❌ Isolate: Ошибка обработки кадра: $e\n$s');
      return null;
    }
  }

  /// Трансформирует координаты касания с экрана в координаты изображения камеры,
  /// учитывая масштабирование BoxFit.cover
  static ui.Offset _transformTapPoint(
      ui.Offset tapPoint, ui.Size previewSize, ui.Size imageSize) {
    final fittedSizes = applyBoxFit(BoxFit.cover, imageSize, previewSize);
    final sourceRect = Alignment.center.inscribe(fittedSizes.source,
        Rect.fromLTWH(0, 0, imageSize.width, imageSize.height));
    final destinationRect = Alignment.center.inscribe(fittedSizes.destination,
        Rect.fromLTWH(0, 0, previewSize.width, previewSize.height));

    // Координаты касания относительно destinationRect
    final double relativeX = tapPoint.dx - destinationRect.left;
    final double relativeY = tapPoint.dy - destinationRect.top;

    // Масштабируем обратно в систему координат sourceRect
    final double scaledX =
        (relativeX / destinationRect.width) * sourceRect.width;
    final double scaledY =
        (relativeY / destinationRect.height) * sourceRect.height;

    // Возвращаем абсолютные координаты в исходном изображении
    return ui.Offset(scaledX + sourceRect.left, scaledY + sourceRect.top);
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

  static img.Image? _convertCameraImage(_CameraImageDTO imageDto) {
    if (imageDto.imageFormatGroup == ImageFormatGroup.yuv420) {
      return _convertYUV420(imageDto);
    } else if (imageDto.imageFormatGroup == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(imageDto);
    } else {
      debugPrint("Unsupported image format: ${imageDto.imageFormatGroup}");
      return null;
    }
  }

  static img.Image _convertBGRA8888(_CameraImageDTO image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].buffer,
      order: img.ChannelOrder.bgra,
    );
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
      final int uvRow = uvRowStride * (y ~/ 2);
      for (int x = 0; x < width; x++) {
        final int uvCol = uvPixelStride * (x ~/ 2);
        final int yIndex = y * width + x;

        final yValue = yPlane[yIndex];
        final uValue = uPlane[uvRow + uvCol];
        final vValue = vPlane[uvRow + uvCol];

        final c = yuvToRgb(yValue, uValue, vValue);
        out.setPixelRgba(
            x, y, (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF, 255);
      }
    }
    return out;
  }
}

/// YUV to RGB Conversion
/// Sourced from https://github.com/flutter/flutter/issues/26348
int yuvToRgb(int y, int u, int v) {
  // Convert yuv pixel to rgb
  int r = (y + (1.370705 * (v - 128))).round();
  int g = (y - (0.337633 * (u - 128)) - (0.698001 * (v - 128))).round();
  int b = (y + (1.732446 * (u - 128))).round();

  // Clipping RGB values to be inside bound [0, 255]
  r = r.clamp(0, 255);
  g = g.clamp(0, 255);
  b = b.clamp(0, 255);

  return 0xff000000 | (b << 16) | (g << 8) | r;
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
