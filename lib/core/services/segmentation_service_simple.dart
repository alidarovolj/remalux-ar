import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:remalux_ar/core/utils/image_converter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SegmentationResult {
  final ui.Path path;
  final List<List<int>> rawMask;
  final int maskWidth;
  final int maskHeight;

  SegmentationResult({
    required this.path,
    required this.rawMask,
    required this.maskWidth,
    required this.maskHeight,
  });
}

/// Упрощенный сервис для AI сегментации стен
class SegmentationServiceSimple {
  static SegmentationServiceSimple? _instance;
  static SegmentationServiceSimple get instance =>
      _instance ??= SegmentationServiceSimple._internal();

  SegmentationServiceSimple._internal();

  // Модель сегментации
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Параметры модели SegFormer
  final int _modelWidth = 224;
  final int _modelHeight = 224;

  // Последняя рассчитанная сырая маска
  SegmentationResult? _lastResult;

  // Тензоры ввода/вывода
  late Tensor _inputTensor;
  late Tensor _outputTensor;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      debugPrint("🤖 SegmentationService: Загружаем модель segformer.tflite");
      final options = InterpreterOptions();

      // Используем делегат GPU для ускорения, если доступен
      if (Platform.isAndroid) {
        options.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        options.addDelegate(GpuDelegate());
      }

      _interpreter = await Interpreter.fromAsset('assets/ml/segformer.tflite',
          options: options);

      _inputTensor = _interpreter!.getInputTensor(0);
      _outputTensor = _interpreter!.getOutputTensor(0);

      _isInitialized = true;
      debugPrint('✅ Модель segformer.tflite загружена успешно.');
      debugPrint(
          '🧠 SegFormer Input: ${_inputTensor.shape}, Type: ${_inputTensor.type}');
      debugPrint(
          '🧠 SegFormer Output: ${_outputTensor.shape}, Type: ${_outputTensor.type}');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки AI модели: $e');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  Future<SegmentationResult?> processCameraImage(
      CameraImage image, double screenWidth, double screenHeight) async {
    if (!_isInitialized || _interpreter == null) return null;

    final preprocessedImage = _preprocessCameraImage(image);
    if (preprocessedImage == null) return null;

    // Запуск модели
    final inputs = [preprocessedImage.reshape(_inputTensor.shape)];
    final outputBuffer = List.filled(_modelWidth * _modelHeight, 0.0)
        .reshape(_outputTensor.shape);

    final outputs = <int, Object>{0: outputBuffer};

    _interpreter!.runForMultipleInputs(inputs, outputs);

    final rawMask = _postProcessOutput(outputBuffer);

    final labeledMask = _findAndLabelConnectedComponents(rawMask);

    final path = _convertRawMaskToPath(labeledMask, screenWidth, screenHeight);

    _lastResult = SegmentationResult(
      path: path,
      rawMask: labeledMask,
      maskWidth: _modelWidth,
      maskHeight: _modelHeight,
    );

    return _lastResult;
  }

  /// Находит и маркирует связанные компоненты (например, отдельные стены)
  List<List<int>> _findAndLabelConnectedComponents(List<List<int>> mask) {
    int height = mask.length;
    if (height == 0) return mask;
    int width = mask[0].length;
    if (width == 0) return mask;

    List<List<int>> labeledMask =
        List.generate(height, (_) => List.generate(width, (_) => 0));
    int currentLabel = 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Если пиксель - это стена (значение 1) и он еще не был помечен
        if (mask[y][x] == 1 && labeledMask[y][x] == 0) {
          _labelComponent(mask, labeledMask, x, y, width, height, currentLabel);
          currentLabel++;
        }
      }
    }
    return labeledMask;
  }

  /// Итеративная функция для пометки одной связанной компоненты
  void _labelComponent(
      List<List<int>> originalMask,
      List<List<int>> labeledMask,
      int x,
      int y,
      int width,
      int height,
      int label) {
    final stack = <(int, int)>[];
    stack.add((x, y));

    while (stack.isNotEmpty) {
      final (curX, curY) = stack.removeLast();

      if (curX < 0 ||
          curX >= width ||
          curY < 0 ||
          curY >= height ||
          originalMask[curY][curX] != 1 || // Ищем "1" для segformer
          labeledMask[curY][curX] != 0) {
        continue;
      }

      labeledMask[curY][curX] = label;

      stack.add((curX + 1, curY));
      stack.add((curX - 1, curY));
      stack.add((curX, curY + 1));
      stack.add((curX, curY - 1));
    }
  }

  Float32List? _preprocessCameraImage(CameraImage image) {
    final img.Image? rgbImage = ImageConverter.convertCameraImage(image);
    if (rgbImage == null) return null;

    // Поворот и обрезка
    final img.Image rotatedImage = img.copyRotate(rgbImage, angle: 90);
    final img.Image resizedImage =
        img.copyResize(rotatedImage, width: _modelWidth, height: _modelHeight);

    // Нормализация пикселей
    final imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final floatBytes = Float32List(_modelWidth * _modelHeight * 3);
    for (int i = 0; i < imageBytes.length; i++) {
      // Нормализация в диапазон [-1, 1] для Segformer
      floatBytes[i] = (imageBytes[i] / 127.5) - 1.0;
    }

    return floatBytes;
  }

  /// Постобработка вывода модели: преобразование в 2D-массив (маску)
  List<List<int>> _postProcessOutput(List<dynamic> output) {
    final maskData = output[0] as List<List<List<double>>>;
    final rawMask = List.generate(
        _modelHeight, (y) => List.generate(_modelWidth, (x) => 0));

    for (int y = 0; y < _modelHeight; y++) {
      for (int x = 0; x < _modelWidth; x++) {
        // Для segformer, если значение > 0, считаем что это стена
        if (maskData[y][x][0] > 0.0) {
          rawMask[y][x] = 1;
        }
      }
    }
    return rawMask;
  }

  /// Преобразует сырую маску в объект Path для отрисовки
  ui.Path _convertRawMaskToPath(
      List<List<int>> rawMask, double screenWidth, double screenHeight) {
    final path = ui.Path();
    final modelHeight = rawMask.length;
    if (modelHeight == 0) return path;
    final modelWidth = rawMask[0].length;
    if (modelWidth == 0) return path;

    final double scaleX = screenWidth / modelWidth;
    final double scaleY = screenHeight / modelHeight;

    for (int y = 0; y < modelHeight; y++) {
      for (int x = 0; x < modelWidth; x++) {
        if (rawMask[y][x] != 0) {
          // Рисуем прямоугольник для каждого пикселя маски
          path.addRect(Rect.fromLTWH(
            x * scaleX,
            y * scaleY,
            scaleX,
            scaleY,
          ));
        }
      }
    }
    return path;
  }

  /// Получает путь для закрашенной стены по точке на экране
  ui.Path? getPaintedWallPath(
      ui.Offset screenPoint, double screenWidth, double screenHeight) {
    if (_lastResult == null) return null;

    final modelPoint =
        _screenToModelCoordinates(screenPoint, screenWidth, screenHeight);
    if (modelPoint == null) return null;

    final int x = modelPoint.dx.toInt();
    final int y = modelPoint.dy.toInt();

    final floodFillMask = _floodFill(
      _lastResult!.rawMask, // Маска уже с уникальными ID
      x,
      y,
      _lastResult!.maskWidth,
      _lastResult!.maskHeight,
    );

    if (floodFillMask == null) return null; // Точка не на стене

    // Конвертируем новую маску залитой области в Path
    final paintedPath =
        _convertRawMaskToPath(floodFillMask, screenWidth, screenHeight);

    return paintedPath;
  }

  /// Алгоритм заливки (Flood Fill) для поиска связанной области
  List<List<int>>? _floodFill(
    List<List<int>> mask,
    int startX,
    int startY,
    int width,
    int height,
  ) {
    if (startX < 0 || startX >= width || startY < 0 || startY >= height) {
      return null;
    }

    final targetValue = mask[startY][startX];
    if (targetValue == 0) {
      return null; // Нельзя залить фон
    }

    final filledMask =
        List.generate(height, (_) => List.generate(width, (_) => 0));

    // Очередь для итеративной заливки
    final pointsQueue = Queue<(int, int)>();
    pointsQueue.add((startX, startY));

    // Множество для отслеживания уже посещенных точек
    final visited = <(int, int)>{(startX, startY)};

    while (pointsQueue.isNotEmpty) {
      final (x, y) = pointsQueue.removeFirst();
      filledMask[y][x] = targetValue;

      // Проверяем 4-х соседей
      final neighbors = [(x, y - 1), (x, y + 1), (x - 1, y), (x + 1, y)];

      for (final (nx, ny) in neighbors) {
        if (nx >= 0 &&
            nx < width &&
            ny >= 0 &&
            ny < height &&
            mask[ny][nx] == targetValue &&
            !visited.contains((nx, ny))) {
          visited.add((nx, ny));
          pointsQueue.add((nx, ny));
        }
      }
    }
    return filledMask;
  }

  /// Преобразует координаты экрана в координаты на маске модели
  ui.Offset? _screenToModelCoordinates(
    ui.Offset screenPoint,
    double screenWidth,
    double screenHeight,
  ) {
    if (_lastResult == null) return null;
    final modelWidth = _lastResult!.maskWidth;
    final modelHeight = _lastResult!.maskHeight;

    final double x = (screenPoint.dx / screenWidth) * modelWidth;
    final double y = (screenPoint.dy / screenHeight) * modelHeight;

    if (x >= 0 && x < modelWidth && y >= 0 && y < modelHeight) {
      return ui.Offset(x.floor().toDouble(), y.floor().toDouble());
    }
    return null;
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
    _instance = null;
  }
}
