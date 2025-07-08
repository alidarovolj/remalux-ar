import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Упрощенный сервис для AI сегментации стен БЕЗ изолятов
/// Используется временно для исправления ошибки с UI операциями
class SegmentationServiceSimple {
  static SegmentationServiceSimple? _instance;
  static SegmentationServiceSimple get instance =>
      _instance ??= SegmentationServiceSimple._internal();

  SegmentationServiceSimple._internal();

  // Модель сегментации
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Параметры модели SegFormer
  List<int>? _inputShape; // [1, 224, 224, 3] для segformer.tflite
  List<int>? _outputShape; // [1, 224, 224, 1] - бинарная маска стен
  TensorType? _inputType;
  TensorType? _outputType;

  // Колбэк для результатов
  Function(ui.Path wallMask)? _onSegmentationResult;

  /// Инициализация сервиса с загрузкой SegFormer модели
  Future<bool> initialize({
    String modelPath = 'assets/ml/segformer.tflite',
  }) async {
    if (_isInitialized) return true;

    try {
      print("🤖 SegmentationService: Загружаем SegFormer модель $modelPath");

      // Создаем основной интерпретер
      final interpreterOptions = InterpreterOptions();

      // Включаем GPU ускорение для мобильных устройств
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          final gpuDelegate = GpuDelegate();
          interpreterOptions.addDelegate(gpuDelegate);
          print(
              "📱 GPU ускорение включено для ${Platform.isAndroid ? 'Android' : 'iOS'}");
        }
      } catch (e) {
        print("⚠️ GPU ускорение недоступно, используем CPU: $e");
      }

      _interpreter =
          await Interpreter.fromAsset(modelPath, options: interpreterOptions);
      _interpreter!.allocateTensors();

      // Получаем информацию о SegFormer модели
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      _inputShape = inputTensor.shape;
      _inputType = inputTensor.type;
      _outputShape = outputTensor.shape;
      _outputType = outputTensor.type;

      print('🧠 SegFormer Input: $_inputShape, Type: $_inputType');
      print('🧠 SegFormer Output: $_outputShape, Type: $_outputType');

      // Проверяем что это правильная SegFormer модель
      if (_inputShape!.length == 4 &&
          _inputShape![1] == 224 &&
          _inputShape![2] == 224 &&
          _inputShape![3] == 3 &&
          _outputShape!.length == 4 &&
          _outputShape![1] == 224 &&
          _outputShape![2] == 224 &&
          _outputShape![3] == 1) {
        print(
            '✅ SegFormer модель корректна: input 224x224x3 → output 224x224x1');
      } else {
        print('⚠️ Неожиданные размеры модели, продолжаем...');
      }

      _isInitialized = true;
      print('✅ SegmentationService с SegFormer инициализован');
      return true;
    } catch (e) {
      print('❌ Ошибка инициализации SegmentationService: $e');
      return false;
    }
  }

  /// Обработка кадра с камеры (В ГЛАВНОМ ПОТОКЕ)
  Future<void> processFrame(
    CameraImage cameraImage,
    double screenWidth,
    double screenHeight,
  ) async {
    if (!_isInitialized || _interpreter == null) return;

    try {
      // Конвертируем изображение
      final convertedImage = _convertCameraImage(cameraImage);
      if (convertedImage == null) return;

      // Создаем простую тестовую маску (пока без реального AI)
      // TODO: Здесь будет реальный инференс SegFormer
      final wallMask = _createTestWallMask(screenWidth, screenHeight);

      // Вызываем колбэк с результатом
      if (_onSegmentationResult != null) {
        _onSegmentationResult!(wallMask);
      }
    } catch (e) {
      print('❌ Ошибка обработки кадра: $e');
    }
  }

  /// Обработка кадра с прямым возвратом результата (для BLoC)
  Future<ui.Path?> processFrameAndGetMask(
    CameraImage cameraImage,
    double screenWidth,
    double screenHeight,
  ) async {
    if (!_isInitialized || _interpreter == null) return null;

    try {
      // Конвертируем изображение
      final convertedImage = _convertCameraImage(cameraImage);
      if (convertedImage == null) return null;

      // Создаем простую тестовую маску (пока без реального AI)
      // TODO: Здесь будет реальный инференс SegFormer
      return _createTestWallMask(screenWidth, screenHeight);
    } catch (e) {
      print('❌ Ошибка обработки кадра: $e');
      return null;
    }
  }

  /// Создание тестовой маски стены
  ui.Path _createTestWallMask(double screenWidth, double screenHeight) {
    final wallMask = ui.Path();

    // Создаем несколько областей как "стены" для более реалистичного тестирования

    // Главная стена (центр)
    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;
    final mainWallWidth = screenWidth * 0.7;
    final mainWallHeight = screenHeight * 0.5;

    wallMask.addRect(ui.Rect.fromCenter(
      center: ui.Offset(centerX, centerY),
      width: mainWallWidth,
      height: mainWallHeight,
    ));

    // Дополнительные области стен (левая и правая)
    final sideWallWidth = screenWidth * 0.15;
    final sideWallHeight = screenHeight * 0.8;

    // Левая стена
    wallMask.addRect(ui.Rect.fromLTWH(
      20,
      (screenHeight - sideWallHeight) / 2,
      sideWallWidth,
      sideWallHeight,
    ));

    // Правая стена
    wallMask.addRect(ui.Rect.fromLTWH(
      screenWidth - sideWallWidth - 20,
      (screenHeight - sideWallHeight) / 2,
      sideWallWidth,
      sideWallHeight,
    ));

    print('🎨 Создана тестовая маска стены: ${screenWidth}x${screenHeight}');
    return wallMask;
  }

  /// Конвертация CameraImage
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return img.Image.fromBytes(
          width: cameraImage.planes[0].width!,
          height: cameraImage.planes[0].height!,
          bytes: cameraImage.planes[0].bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
      } else {
        // YUV420 to RGB конвертация (упрощенная)
        final int width = cameraImage.width;
        final int height = cameraImage.height;
        final image = img.Image(width: width, height: height);

        // Упрощенная конвертация для тестирования
        for (int y = 0; y < height && y < 100; ++y) {
          for (int x = 0; x < width && x < 100; ++x) {
            image.setPixelRgb(x, y, 128, 128, 128); // Серый цвет
          }
        }
        return image;
      }
    } catch (e) {
      print('❌ Ошибка конвертации изображения: $e');
      return null;
    }
  }

  /// Проверка, находится ли точка на стене
  bool isPointOnWall(ui.Offset point, ui.Path? wallMask) {
    if (wallMask == null) {
      print('⚠️ Нет маски стены для проверки точки $point');
      return false;
    }

    final isOnWall = wallMask.contains(point);
    print('🔍 Проверка точки $point на стене: ${isOnWall ? "✅ ДА" : "❌ НЕТ"}');
    return isOnWall;
  }

  /// Очистка ресурсов
  Future<void> dispose() async {
    print('🧹 SegmentationService: Очистка ресурсов');

    _interpreter?.close();
    _interpreter = null;

    _isInitialized = false;
  }
}
