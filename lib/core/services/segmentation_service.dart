/*
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Сервис для AI сегментации стен.
/// Эта версия была упрощена для устранения ошибок зависимостей.
/// Исполнение модели происходит в основном потоке.
class SegmentationService {
  static SegmentationService? _instance;
  static SegmentationService get instance =>
      _instance ??= SegmentationService._internal();

  SegmentationService._internal();

  // Модель сегментации
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Параметры модели
  List<int>? _inputShape;
  List<int>? _outputShape;
  TfLiteType? _inputType;
  TfLiteType? _outputType;

  // Callback для результатов
  Function(ui.Image? overlayImage)? _onSegmentationResult;

  // Отслеживание состояния обработки, чтобы избежать одновременных запусков
  bool _isProcessing = false;

  Future<bool> initialize({
    String modelPath = 'assets/ml/segformer.tflite',
    Function(ui.Image? overlayImage)? onSegmentationResult,
  }) async {
    if (_isInitialized) return true;

    try {
      debugPrint("🤖 SegmentationService: Загрузка модели $modelPath");

      _onSegmentationResult = onSegmentationResult;

      final interpreterOptions = InterpreterOptions();
      _interpreter =
          await Interpreter.fromAsset(modelPath, options: interpreterOptions);
      _interpreter!.allocateTensors();

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      _inputShape = inputTensor.shape;
      _inputType = inputTensor.type;
      _outputShape = outputTensor.shape;
      _outputType = outputTensor.type;

      debugPrint('✅ SegmentationService инициализирован');
      debugPrint('   - Input Shape: $_inputShape, Type: $_inputType');
      debugPrint('   - Output Shape: $_outputShape, Type: $_outputType');

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка инициализации SegmentationService: $e');
      return false;
    }
  }

  Future<void> processFrame(CameraImage cameraImage) async {
    if (!_isInitialized || _isProcessing) return;

    _isProcessing = true;

    try {
      final stopwatch = Stopwatch()..start();

      // 1. Конвертация изображения с камеры
      final inputImage = _convertCameraImage(cameraImage);
      if (inputImage == null) return;

      // 2. Предобработка изображения и подготовка входного тензора
      // Предполагается, что модель Segformer принимает на вход 224x224
      final inputTensor =
          _preprocessImage(inputImage, _inputShape![1], _inputShape![2]);

      // 3. Подготовка выходного тензора
      final outputBuffer =
          List.filled(_outputShape!.reduce((a, b) => a * b), 0.0)
              .reshape(_outputShape!);
      final outputs = <int, Object>{0: outputBuffer};

      // 4. Запуск модели
      _interpreter!.runForMultipleInputs([inputTensor], outputs);

      // 5. Постобработка результата для получения маски сегментации
      final segmentationMask = _postProcessOutput(outputBuffer);

      stopwatch.stop();
      debugPrint(
          "⏱️ Время выполнения сегментации: ${stopwatch.elapsedMilliseconds}ms");

      // 6. Создание визуального оверлея из маски
      if (_onSegmentationResult != null) {
        final overlay = await _createOverlayFromMask(
            segmentationMask, _outputShape![2], _outputShape![1]);
        _onSegmentationResult!(overlay);
      }
    } catch (e) {
      debugPrint('❌ Ошибка при обработке кадра в сегментации: $e');
      _onSegmentationResult?.call(null);
    } finally {
      _isProcessing = false;
    }
  }

  /// Подготавливает изображение для модели.
  Float32List _preprocessImage(
      img.Image image, int targetWidth, int targetHeight) {
    final resizedImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );

    // Нормализация значений пикселей в диапазон [-1, 1], как ожидает SegFormer
    final imageBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final floatBytes = Float32List(targetWidth * targetHeight * 3);
    for (int i = 0; i < imageBytes.length; i++) {
      floatBytes[i] = (imageBytes[i] / 127.5) - 1.0;
    }

    return floatBytes;
  }

  /// Конвертирует выходные данные модели в 2D маску сегментации.
  Uint8List _postProcessOutput(List<dynamic> output) {
    // Предполагается, что выход имеет форму [1, высота, ширина, 1]
    // и содержит оценки классов.
    final reshapedOutput = output[0] as List<List<List<double>>>;
    final height = reshapedOutput.length;
    final width = reshapedOutput[0].length;

    final mask = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Для Segformer значение > 0 часто указывает на целевой класс (стена)
        if (reshapedOutput[y][x][0] > 0.0) {
          mask[y * width + x] = 1; // Класс 1 для Стены
        } else {
          mask[y * width + x] = 0; // Класс 0 для Фона
        }
      }
    }
    return mask;
  }

  Future<ui.Image> _createOverlayFromMask(
      Uint8List mask, int width, int height) async {
    final completer = Completer<ui.Image>();
    final color =
        ui.Color.fromARGB(128, 255, 0, 0); // Полупрозрачный красный для стен

    // Используем Isolate.run для ресурсоемкой операции создания изображения
    final pngBytes = await Isolate.run(() {
      final image = img.Image(width: width, height: height, numChannels: 4);
      for (int i = 0; i < mask.length; i++) {
        if (mask[i] == 1) {
          // Если пиксель - это стена
          final index = i;
          final x = index % width;
          final y = index ~/ width;
          image.setPixelRgba(x, y, color.red, color.green, color.blue, color.alpha);
        }
      }
      return img.encodePng(image);
    });

    ui.instantiateImageCodec(Uint8List.fromList(pngBytes)).then((codec) {
      codec.getNextFrame().then((frame) => completer.complete(frame.image));
    });

    return completer.future;
  }

  img.Image? _convertCameraImage(CameraImage cameraImage) {
    // Эта логика конвертации должна быть надежной.
    // Для простоты предполагаем формат BGRA на iOS/macOS.
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: cameraImage.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    }
    // TODO: Добавить конвертацию из YUV420 для Android, если потребуется.
    debugPrint("Неподдерживаемый формат изображения: ${cameraImage.format.group}");
    return null; // При необходимости обработать другие форматы
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
    debugPrint("🤖 SegmentationService выгружен.");
  }
}
*/
