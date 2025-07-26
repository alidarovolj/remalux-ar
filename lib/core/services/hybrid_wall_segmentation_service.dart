import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'cv_wall_painter_service.dart';
import 'roboflow_wall_segmentation_service.dart';
import 'performance_profiler.dart';
import 'device_capability_detector.dart';

/// Режим работы сегментации
enum SegmentationMode {
  localOnly, // Только локальные модели
  roboflowOnly, // Только Roboflow API
  hybrid, // Гибридный - API для качества, локальные для скорости
  adaptive, // Адаптивный - выбор на основе условий
}

/// Гибридный сервис для сегментации стен
class HybridWallSegmentationService {
  static final HybridWallSegmentationService _instance =
      HybridWallSegmentationService._internal();
  factory HybridWallSegmentationService() => _instance;
  HybridWallSegmentationService._internal();

  final CVWallPainterService _localService = CVWallPainterService.instance;
  final RoboflowWallSegmentationService _roboflowService =
      RoboflowWallSegmentationService();
  final PerformanceProfiler _profiler = PerformanceProfiler();
  final DeviceCapabilityDetector _deviceDetector = DeviceCapabilityDetector();

  SegmentationMode _currentMode = SegmentationMode.adaptive;
  bool _isInitialized = false;

  // Адаптивные параметры
  int _consecutiveApiFailures = 0;
  double _averageApiLatency = 0.0;
  double _averageLocalLatency = 0.0;
  bool _isNetworkAvailable = true;

  /// Инициализация гибридного сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Initializing Hybrid Wall Segmentation Service...');

      // Инициализация локального сервиса
      await _localService.initialize();

      // Попытка инициализации Roboflow API
      try {
        await _roboflowService.initialize();
        debugPrint('✅ Roboflow API available');
      } catch (e) {
        debugPrint('⚠️ Roboflow API unavailable, will use local only: $e');
        _currentMode = SegmentationMode.localOnly;
      }

      _isInitialized = true;
      debugPrint('✅ Hybrid service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize hybrid service: $e');
      rethrow;
    }
  }

  /// Обработка кадра с адаптивным выбором метода
  Future<HybridSegmentationResult?> processFrame(
      CameraImage cameraImage) async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _profiler.profileOperation('hybrid_segmentation', () async {
      final selectedMode = await _selectOptimalMode();

      switch (selectedMode) {
        case SegmentationMode.localOnly:
          return await _processWithLocal(cameraImage);

        case SegmentationMode.roboflowOnly:
          return await _processWithRoboflow(cameraImage);

        case SegmentationMode.hybrid:
          return await _processHybrid(cameraImage);

        case SegmentationMode.adaptive:
          return await _processAdaptive(cameraImage);
      }
    });
  }

  /// Адаптивный выбор режима обработки
  Future<SegmentationMode> _selectOptimalMode() async {
    // Если сетевой режим отключен пользователем
    if (_currentMode == SegmentationMode.localOnly) {
      return SegmentationMode.localOnly;
    }

    // Если слишком много ошибок API
    if (_consecutiveApiFailures > 3) {
      debugPrint('🔄 Switching to local due to API failures');
      return SegmentationMode.localOnly;
    }

    // Анализ производительности устройства
    final deviceCapabilities = await _deviceDetector.getDeviceCapabilities();

    // На мощных устройствах можем использовать гибридный режим
    if (deviceCapabilities.performanceTier == DevicePerformanceTier.highEnd) {
      return SegmentationMode.hybrid;
    }

    // На слабых устройствах приоритет локальным моделям
    if (deviceCapabilities.performanceTier == DevicePerformanceTier.lowEnd) {
      return SegmentationMode.localOnly;
    }

    // Адаптивный выбор на основе задержки
    if (_averageApiLatency > 0 && _averageLocalLatency > 0) {
      // Если API значительно медленнее локальной модели
      if (_averageApiLatency > _averageLocalLatency * 3) {
        return SegmentationMode.localOnly;
      }

      // Если API быстрее и стабильнее
      if (_averageApiLatency < _averageLocalLatency * 1.5) {
        return SegmentationMode.roboflowOnly;
      }
    }

    return SegmentationMode.adaptive;
  }

  /// Обработка только локальными моделями
  Future<HybridSegmentationResult> _processWithLocal(
      CameraImage cameraImage) async {
    try {
      final stopwatch = Stopwatch()..start();

      final didStart = _localService.processCameraFrame(cameraImage);

      if (didStart) {
        // Ждем результат от локального сервиса
        await Future.delayed(
            const Duration(milliseconds: 50)); // Небольшая задержка
        final lastResult = _localService.lastResult;

        stopwatch.stop();
        _updateLocalLatency(stopwatch.elapsedMilliseconds.toDouble());

        return HybridSegmentationResult(
          mask: lastResult?.segmentationMask,
          confidence: 0.8, // Локальные модели имеют стабильную уверенность
          source: SegmentationSource.local,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          originalWidth: cameraImage.width,
          originalHeight: cameraImage.height,
        );
      } else {
        stopwatch.stop();
        return HybridSegmentationResult.empty(
            cameraImage.width, cameraImage.height);
      }
    } catch (e) {
      debugPrint('❌ Local processing failed: $e');
      return HybridSegmentationResult.empty(
          cameraImage.width, cameraImage.height);
    }
  }

  /// Обработка только через Roboflow API
  Future<HybridSegmentationResult> _processWithRoboflow(
      CameraImage cameraImage) async {
    try {
      final stopwatch = Stopwatch()..start();

      final result = await _roboflowService.processFrame(cameraImage);

      stopwatch.stop();

      if (result != null) {
        _updateApiLatency(stopwatch.elapsedMilliseconds.toDouble());
        _consecutiveApiFailures = 0; // Сброс счетчика ошибок

        return HybridSegmentationResult(
          mask: result.mask,
          confidence: result.confidence,
          source: SegmentationSource.roboflow,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          originalWidth: result.originalWidth,
          originalHeight: result.originalHeight,
          segmentCount: result.segmentCount,
        );
      } else {
        throw Exception('Roboflow API returned null result');
      }
    } catch (e) {
      debugPrint('❌ Roboflow processing failed: $e');
      _consecutiveApiFailures++;

      // Fallback на локальную модель
      return await _processWithLocal(cameraImage);
    }
  }

  /// Гибридная обработка - комбинирование результатов
  Future<HybridSegmentationResult> _processHybrid(
      CameraImage cameraImage) async {
    // Запускаем оба метода параллельно
    final futures = await Future.wait([
      _processWithLocal(cameraImage),
      _processWithRoboflow(cameraImage),
    ]);

    final localResult = futures[0];
    final apiResult = futures[1];

    // Выбираем лучший результат
    if (apiResult.source == SegmentationSource.roboflow &&
        apiResult.confidence > 0.7) {
      return apiResult; // API результат более точный
    } else {
      return localResult; // Fallback на локальный
    }
  }

  /// Адаптивная обработка с динамическим выбором
  Future<HybridSegmentationResult> _processAdaptive(
      CameraImage cameraImage) async {
    // Логика адаптивного выбора в реальном времени
    final now = DateTime.now();

    // В первые 10 секунд используем API для калибровки
    if (_averageApiLatency == 0.0) {
      return await _processWithRoboflow(cameraImage);
    }

    // Периодически тестируем API для адаптации
    if (now.second % 30 == 0) {
      // Каждые 30 секунд
      return await _processWithRoboflow(cameraImage);
    }

    // Обычно используем более быстрый метод
    if (_averageApiLatency < _averageLocalLatency) {
      return await _processWithRoboflow(cameraImage);
    } else {
      return await _processWithLocal(cameraImage);
    }
  }

  /// Обновление статистики задержки API
  void _updateApiLatency(double latency) {
    if (_averageApiLatency == 0.0) {
      _averageApiLatency = latency;
    } else {
      _averageApiLatency = (_averageApiLatency * 0.7) + (latency * 0.3);
    }
  }

  /// Обновление статистики задержки локальной модели
  void _updateLocalLatency(double latency) {
    if (_averageLocalLatency == 0.0) {
      _averageLocalLatency = latency;
    } else {
      _averageLocalLatency = (_averageLocalLatency * 0.7) + (latency * 0.3);
    }
  }

  /// Установка режима работы
  void setMode(SegmentationMode mode) {
    _currentMode = mode;
    debugPrint('🔄 Segmentation mode changed to: ${mode.name}');
  }

  /// Получение текущего режима
  SegmentationMode get currentMode => _currentMode;

  /// Получение статистики производительности
  Map<String, dynamic> getPerformanceStats() => {
        'currentMode': _currentMode.name,
        'averageApiLatency': _averageApiLatency,
        'averageLocalLatency': _averageLocalLatency,
        'consecutiveApiFailures': _consecutiveApiFailures,
        'isNetworkAvailable': _isNetworkAvailable,
        'isInitialized': _isInitialized,
      };

  /// Проверка готовности сервиса
  bool get isInitialized => _isInitialized;

  /// Освобождение ресурсов
  void dispose() {
    _localService.dispose();
    _roboflowService.dispose();
    _isInitialized = false;
    debugPrint('🧹 Hybrid service disposed');
  }
}

/// Источник сегментации
enum SegmentationSource {
  local, // Локальная модель
  roboflow, // Roboflow API
  hybrid, // Комбинированный результат
}

/// Результат гибридной сегментации
class HybridSegmentationResult {
  final Uint8List? mask;
  final double confidence;
  final SegmentationSource source;
  final int processingTimeMs;
  final int originalWidth;
  final int originalHeight;
  final int? segmentCount;

  HybridSegmentationResult({
    required this.mask,
    required this.confidence,
    required this.source,
    required this.processingTimeMs,
    required this.originalWidth,
    required this.originalHeight,
    this.segmentCount,
  });

  /// Создание пустого результата
  factory HybridSegmentationResult.empty(int width, int height) {
    return HybridSegmentationResult(
      mask: null,
      confidence: 0.0,
      source: SegmentationSource.local,
      processingTimeMs: 0,
      originalWidth: width,
      originalHeight: height,
    );
  }

  /// Есть ли валидная маска
  bool get hasValidMask => mask != null && mask!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'confidence': confidence,
        'source': source.name,
        'processingTimeMs': processingTimeMs,
        'originalWidth': originalWidth,
        'originalHeight': originalHeight,
        'segmentCount': segmentCount,
        'hasValidMask': hasValidMask,
      };
}
