import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:remalux_ar/core/utils/image_converter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Специализированный сервис для сегментации стен
/// Использует оптимизированную модель и постобработку
class WallSegmentationService {
  late Interpreter _interpreter;
  late Map<String, dynamic> _config;
  late Map<int, int> _classMapping;
  late List<int> _inputShape;
  late List<int> _outputShape;

  bool _isModelLoaded = false;

  static const String modelPath =
      'assets/ml/wall_segmentation_specialized.tflite';
  static const String configPath = 'assets/ml/wall_model_config.json';
  static const String mappingPath = 'assets/ml/wall_segmentation_mapping.json';

  // Public getters
  int? get maskWidth => _outputShape.isNotEmpty ? _outputShape[2] : null;
  int? get maskHeight => _outputShape.isNotEmpty ? _outputShape[1] : null;
  bool get isModelLoaded => _isModelLoaded;

  /// Загружает специализированную модель сегментации стен
  Future<void> loadModel({int modelIndex = 1}) async {
    try {
      debugPrint('🚀 Loading specialized wall segmentation model...');

      // Выбираем модель в зависимости от индекса
      String selectedModelPath;
      String selectedConfigPath;

      switch (modelIndex) {
        case 1:
          selectedModelPath = 'assets/ml/wall_segmentation_specialized.tflite';
          selectedConfigPath = 'assets/ml/wall_model_config.json';
          break;
        case 2:
          selectedModelPath =
              'assets/ml/wall_segmentation_mobile_optimized.tflite';
          selectedConfigPath =
              'assets/ml/wall_segmentation_mobile_optimized_config.json';
          break;
        default:
          selectedModelPath = modelPath;
          selectedConfigPath = configPath;
      }

      debugPrint('📱 Selected model: $selectedModelPath');

      // Загружаем конфигурацию
      await _loadConfig(selectedConfigPath);

      // Загружаем маппинг классов
      await _loadClassMapping();

      // Настраиваем интерпретатор с оптимизациями
      final options = InterpreterOptions();

      if (_config['performance']['use_xnnpack'] == true) {
        try {
          final delegate = XNNPackDelegate();
          options.addDelegate(delegate);
          debugPrint('✓ XNNPACK delegate enabled');
        } catch (e) {
          debugPrint('⚠️ XNNPACK delegate not available: $e');
        }
      }

      _interpreter =
          await Interpreter.fromAsset(selectedModelPath, options: options);

      _inputShape = _interpreter.getInputTensor(0).shape;
      _outputShape = _interpreter.getOutputTensor(0).shape;

      _isModelLoaded = true;

      debugPrint('✅ Wall segmentation model loaded successfully');
      debugPrint(
          '📊 Model info: ${_config['model_info']['name']} v${_config['model_info']['version']}');
      debugPrint('🔧 Input shape: $_inputShape');
      debugPrint('🔧 Output shape: $_outputShape');
      debugPrint('🎯 Expected accuracy: ${_config['performance']['accuracy']}');
      debugPrint('⚡ Expected FPS: ${_config['performance']['expected_fps']}');
    } catch (e) {
      debugPrint('❌ Failed to load wall segmentation model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  /// Загружает конфигурацию модели
  Future<void> _loadConfig(String configPath) async {
    final configRaw = await rootBundle.loadString(configPath);
    _config = json.decode(configRaw);
  }

  /// Загружает маппинг классов
  Future<void> _loadClassMapping() async {
    final mappingRaw = await rootBundle.loadString(mappingPath);
    final mappingData = json.decode(mappingRaw);

    _classMapping = {};
    final classMap = mappingData['class_mapping'] as Map<String, dynamic>;
    classMap.forEach((key, value) {
      _classMapping[int.parse(key)] = value as int;
    });

    debugPrint('📋 Class mapping loaded: ${_classMapping.length} classes');
  }

  /// Обрабатывает кадр камеры и возвращает маску стен
  Uint8List? processCameraImage(CameraImage cameraImage) {
    if (!_isModelLoaded) {
      debugPrint('⚠️ Model not loaded, skipping processing');
      return null;
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Конвертируем изображение камеры
      final image = ImageConverter.convertCameraImage(cameraImage);
      if (image == null) {
        debugPrint('⚠️ Failed to convert camera image');
        return null;
      }

      // Изменяем размер согласно требованиям модели
      final inputSize = _config['model_info']['input_size'];
      final resizedImage = img.copyResize(
        image,
        width: inputSize[1],
        height: inputSize[0],
        interpolation: img.Interpolation.linear,
      );

      // Предобработка изображения
      final inputBuffer = _preprocessImage(resizedImage);

      // Запускаем инференс
      final rawOutput = _runInference(inputBuffer);
      if (rawOutput == null) {
        return null;
      }

      // Постобработка: применяем маппинг классов и фильтрацию
      final wallMask = _postProcessOutput(rawOutput);

      stopwatch.stop();
      debugPrint(
          '🏠 Wall segmentation completed in ${stopwatch.elapsedMilliseconds}ms');

      return wallMask;
    } catch (e) {
      debugPrint('❌ Error in wall segmentation: $e');
      return null;
    }
  }

  /// Предобработка изображения согласно конфигурации модели
  Float32List _preprocessImage(img.Image image) {
    final inputBytes = image.getBytes(order: img.ChannelOrder.rgb);
    final inputBuffer = Float32List(_inputShape.reduce((a, b) => a * b));

    final preprocessing = _config['processing']['preprocessing'];
    final normalize = preprocessing['normalize'] as bool;

    if (normalize) {
      final mean = (preprocessing['mean'] as List).cast<double>();
      final std = (preprocessing['std'] as List).cast<double>();

      for (int i = 0; i < inputBytes.length; i += 3) {
        // Нормализация RGB каналов
        inputBuffer[i] = (inputBytes[i] - mean[0]) / std[0];
        inputBuffer[i + 1] = (inputBytes[i + 1] - mean[1]) / std[1];
        inputBuffer[i + 2] = (inputBytes[i + 2] - mean[2]) / std[2];
      }
    } else {
      for (int i = 0; i < inputBytes.length; i++) {
        inputBuffer[i] = inputBytes[i] / 255.0;
      }
    }

    return inputBuffer;
  }

  /// Запускает инференс модели
  List<List<int>>? _runInference(Float32List inputBuffer) {
    try {
      final reshapedInput = inputBuffer.reshape(_inputShape);

      final outputBuffer = List.filled(
        _outputShape.reduce((a, b) => a * b),
        0,
      ).reshape(_outputShape);

      _interpreter.run(reshapedInput, outputBuffer);

      return outputBuffer[0].cast<List<int>>();
    } catch (e) {
      debugPrint('❌ Inference error: $e');
      return null;
    }
  }

  /// Постобработка выхода модели
  Uint8List _postProcessOutput(List<List<int>> rawOutput) {
    final mask = Uint8List(_outputShape[1] * _outputShape[2]);
    int wallPixelCount = 0;
    int totalPixels = 0;

    // Применяем маппинг классов: преобразуем ADE20K классы в wall/non-wall
    for (int i = 0; i < rawOutput.length; i++) {
      for (int j = 0; j < rawOutput[i].length; j++) {
        totalPixels++;
        final originalClass = rawOutput[i][j];
        final mappedClass = _classMapping[originalClass] ?? 0;

        if (mappedClass == 1) {
          // wall_structure
          mask[i * _outputShape[2] + j] = 1;
          wallPixelCount++;
        } else {
          mask[i * _outputShape[2] + j] = 0;
        }
      }
    }

    // Применяем постобработку если настроена
    final postprocessing = _config['processing']['postprocessing'];
    if (postprocessing['filter_small_regions'] == true) {
      _filterSmallRegions(mask, postprocessing['min_region_size'] as int);
    }

    final wallPercentage =
        (wallPixelCount / totalPixels * 100).toStringAsFixed(1);
    debugPrint(
        '🏠 Specialized wall detection: $wallPixelCount/$totalPixels pixels ($wallPercentage%)');

    // Проверка качества результата
    _validateResult(wallPercentage, totalPixels);

    return mask;
  }

  /// Фильтрует мелкие области (упрощенная реализация)
  void _filterSmallRegions(Uint8List mask, int minSize) {
    // Здесь можно добавить более сложную логику фильтрации
    // Пока что просто логируем
    debugPrint('🔧 Applying region filtering (min size: $minSize pixels)');
  }

  /// Проверяет качество результата сегментации
  void _validateResult(String wallPercentage, int totalPixels) {
    final percentage = double.parse(wallPercentage);

    if (percentage < 5.0) {
      debugPrint(
          '⚠️ Very low wall detection: $wallPercentage% - possible poor lighting or no walls');
    } else if (percentage > 95.0) {
      debugPrint(
          '⚠️ Very high wall detection: $wallPercentage% - possible overdetection');
    } else if (percentage >= 20.0 && percentage <= 80.0) {
      debugPrint('✅ Good wall detection quality: $wallPercentage%');
    }
  }

  /// Освобождает ресурсы
  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
      debugPrint('🧹 Wall segmentation model disposed');
    }
  }
}
