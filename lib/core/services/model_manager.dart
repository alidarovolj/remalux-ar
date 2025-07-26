import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'performance_profiler.dart';

/// Метаданные модели
class ModelMetadata {
  final String name;
  final String assetPath;
  final String? configPath;
  final String? labelsPath;
  final int sizeMB;
  final String delegateType;

  ModelMetadata({
    required this.name,
    required this.assetPath,
    this.configPath,
    this.labelsPath,
    required this.sizeMB,
    this.delegateType = 'CPU',
  });
}

/// Загруженная модель с ее ресурсами
class LoadedModel {
  final ModelMetadata metadata;
  final Interpreter interpreter;
  final Map<String, dynamic>? config;
  final List<String>? labels;
  final DateTime loadedAt;

  LoadedModel({
    required this.metadata,
    required this.interpreter,
    this.config,
    this.labels,
    required this.loadedAt,
  });

  /// Получить размер входного тензора
  List<int> get inputShape => interpreter.getInputTensor(0).shape;

  /// Получить размер выходного тензора
  List<int> get outputShape => interpreter.getOutputTensor(0).shape;

  /// Освободить ресурсы модели
  void dispose() {
    try {
      interpreter.close();
      debugPrint('🧹 Модель ${metadata.name} освобождена из памяти');
    } catch (e) {
      debugPrint('⚠️ Ошибка освобождения модели ${metadata.name}: $e');
    }
  }
}

/// Централизованный менеджер для управления жизненным циклом TFLite моделей
class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  final Map<String, LoadedModel> _loadedModels = {};
  final PerformanceProfiler _profiler = PerformanceProfiler();

  /// Максимальное количество одновременно загруженных моделей
  static const int maxLoadedModels = 2;

  /// Таймаут для выгрузки неиспользуемых моделей (в минутах)
  static const int modelTimeoutMinutes = 5;

  /// Доступные модели в приложении
  static final Map<String, ModelMetadata> availableModels = {
    'ade20k_standard': ModelMetadata(
      name: 'ADE20K Standard',
      assetPath: 'assets/ml/deeplabv3_ade20k_fp16.tflite',
      labelsPath: 'assets/ml/ade20k_labels.txt',
      sizeMB: 2,
      delegateType: 'CPU',
    ),
    'wall_specialized': ModelMetadata(
      name: 'Wall Specialized',
      assetPath: 'assets/ml/wall_segmentation_specialized.tflite',
      configPath: 'assets/ml/wall_model_config.json',
      sizeMB: 3,
      delegateType: 'CPU',
    ),
    'wall_mobile': ModelMetadata(
      name: 'Wall Mobile Optimized',
      assetPath: 'assets/ml/wall_segmentation_mobile_optimized.tflite',
      configPath: 'assets/ml/wall_segmentation_mobile_optimized_config.json',
      sizeMB: 7,
      delegateType: 'CPU',
    ),
  };

  /// Загрузить модель по ключу
  Future<LoadedModel> loadModel(String modelKey, {bool useGPU = false}) async {
    // Проверяем, есть ли модель уже в памяти
    if (_loadedModels.containsKey(modelKey)) {
      final model = _loadedModels[modelKey]!;
      debugPrint('♻️ Модель ${model.metadata.name} уже загружена');
      return model;
    }

    // Проверяем доступность модели
    if (!availableModels.containsKey(modelKey)) {
      throw ArgumentError('Модель с ключом "$modelKey" не найдена');
    }

    var metadata = availableModels[modelKey]!;

    return await _profiler.profileOperation('loadModel_$modelKey', () async {
      debugPrint('🚀 Загружаем модель: ${metadata.name}');

      // Освобождаем место, если превышен лимит
      await _enforceMemoryLimits();

      try {
        // Создаем опции интерпретатора
        final options = InterpreterOptions();

        // Настраиваем делегаты
        if (useGPU) {
          try {
            final gpuDelegate = GpuDelegate();
            options.addDelegate(gpuDelegate);
            metadata = ModelMetadata(
              name: metadata.name,
              assetPath: metadata.assetPath,
              configPath: metadata.configPath,
              labelsPath: metadata.labelsPath,
              sizeMB: metadata.sizeMB,
              delegateType: 'GPU',
            );
          } catch (e) {
            debugPrint('⚠️ GPU делегат недоступен: $e');
          }
        } else {
          try {
            final xnnpackDelegate = XNNPackDelegate();
            options.addDelegate(xnnpackDelegate);
          } catch (e) {
            debugPrint('⚠️ XNNPACK делегат недоступен: $e');
          }
        }

        // Загружаем интерпретатор
        final interpreter = await Interpreter.fromAsset(
          metadata.assetPath,
          options: options,
        );

        // Загружаем дополнительные ресурсы
        Map<String, dynamic>? config;
        if (metadata.configPath != null) {
          try {
            final configString =
                await rootBundle.loadString(metadata.configPath!);
            config = jsonDecode(configString);
          } catch (e) {
            debugPrint('⚠️ Не удалось загрузить конфиг: $e');
          }
        }

        List<String>? labels;
        if (metadata.labelsPath != null) {
          try {
            final labelsString =
                await rootBundle.loadString(metadata.labelsPath!);
            labels =
                labelsString.split('\n').where((l) => l.isNotEmpty).toList();
          } catch (e) {
            debugPrint('⚠️ Не удалось загрузить метки: $e');
          }
        }

        // Создаем загруженную модель
        final loadedModel = LoadedModel(
          metadata: metadata,
          interpreter: interpreter,
          config: config,
          labels: labels,
          loadedAt: DateTime.now(),
        );

        // Сохраняем в кэш
        _loadedModels[modelKey] = loadedModel;

        debugPrint('✅ Модель ${metadata.name} загружена успешно');
        debugPrint('   Входной размер: ${loadedModel.inputShape}');
        debugPrint('   Выходной размер: ${loadedModel.outputShape}');
        debugPrint('   Делегат: ${metadata.delegateType}');

        // Записываем метрики
        _profiler.recordModelMetrics(
          modelName: metadata.name,
          inferencLatencyMs: 0, // Будет заполнено при inference
          preprocessingTimeMs: 0,
          postprocessingTimeMs: 0,
          modelSizeMB: metadata.sizeMB,
          delegateType: metadata.delegateType,
        );

        return loadedModel;
      } catch (e, stackTrace) {
        debugPrint('❌ Ошибка загрузки модели ${metadata.name}: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    });
  }

  /// Получить загруженную модель (без загрузки)
  LoadedModel? getLoadedModel(String modelKey) {
    return _loadedModels[modelKey];
  }

  /// Выгрузить конкретную модель
  Future<void> unloadModel(String modelKey) async {
    final model = _loadedModels[modelKey];
    if (model == null) {
      debugPrint('⚠️ Модель "$modelKey" не загружена');
      return;
    }

    model.dispose();
    _loadedModels.remove(modelKey);

    debugPrint('🗑️ Модель ${model.metadata.name} выгружена');
  }

  /// Выгрузить все модели
  Future<void> unloadAllModels() async {
    debugPrint('🧹 Выгружаем все модели...');

    for (final entry in _loadedModels.entries) {
      entry.value.dispose();
    }

    _loadedModels.clear();
    debugPrint('✅ Все модели выгружены');
  }

  /// Переключить на другую модель (с выгрузкой предыдущей)
  Future<LoadedModel> switchToModel(String newModelKey,
      {bool useGPU = false}) async {
    debugPrint('🔄 Переключаемся на модель: $newModelKey');

    // Запоминаем текущие модели
    final currentModels = Map<String, LoadedModel>.from(_loadedModels);

    // Загружаем новую модель
    final newModel = await loadModel(newModelKey, useGPU: useGPU);

    // Выгружаем остальные модели (кроме новой)
    for (final key in currentModels.keys) {
      if (key != newModelKey) {
        await unloadModel(key);
      }
    }

    return newModel;
  }

  /// Принудительная сборка мусора и освобождение памяти
  Future<void> forceGarbageCollection() async {
    debugPrint('🧹 Принудительная сборка мусора...');

    // Выгружаем старые неиспользуемые модели
    await _cleanupOldModels();

    // Принудительно запускаем GC (работает только в debug режиме)
    if (kDebugMode) {
      // Dart не предоставляет прямого API для GC, но можно создать нагрузку
      // которая заставит GC сработать
      final tempList = List.generate(1000, (i) => Uint8List(1024));
      tempList.clear();
    }

    debugPrint('✅ Сборка мусора завершена');
  }

  /// Получить статистику использования памяти
  Map<String, dynamic> getMemoryStats() {
    int totalModels = _loadedModels.length;
    int totalSizeMB = _loadedModels.isEmpty
        ? 0
        : _loadedModels.values
            .map((m) => m.metadata.sizeMB)
            .reduce((a, b) => a + b);

    List<Map<String, dynamic>> modelDetails = _loadedModels.entries
        .map((entry) => {
              'key': entry.key,
              'name': entry.value.metadata.name,
              'sizeMB': entry.value.metadata.sizeMB,
              'delegate': entry.value.metadata.delegateType,
              'loadedAt': entry.value.loadedAt.toIso8601String(),
            })
        .toList();

    return {
      'totalModels': totalModels,
      'totalSizeMB': totalSizeMB,
      'maxModels': maxLoadedModels,
      'modelDetails': modelDetails,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Получить список доступных моделей
  List<String> getAvailableModelKeys() {
    return availableModels.keys.toList();
  }

  /// Проверить, загружена ли модель
  bool isModelLoaded(String modelKey) {
    return _loadedModels.containsKey(modelKey);
  }

  /// Приватный метод для контроля лимитов памяти
  Future<void> _enforceMemoryLimits() async {
    if (_loadedModels.length >= maxLoadedModels) {
      // Находим самую старую модель
      String? oldestKey;
      DateTime? oldestTime;

      for (final entry in _loadedModels.entries) {
        if (oldestTime == null || entry.value.loadedAt.isBefore(oldestTime)) {
          oldestTime = entry.value.loadedAt;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        debugPrint(
            '🗑️ Выгружаем старую модель для освобождения места: $oldestKey');
        await unloadModel(oldestKey);
      }
    }
  }

  /// Приватный метод для очистки старых моделей
  Future<void> _cleanupOldModels() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _loadedModels.entries) {
      final age = now.difference(entry.value.loadedAt).inMinutes;
      if (age > modelTimeoutMinutes) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      debugPrint('⏰ Выгружаем устаревшую модель: $key');
      await unloadModel(key);
    }
  }

  /// Метод dispose для полной очистки
  void dispose() {
    unloadAllModels();
  }
}
