import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

/// Метрики производительности системы
class SystemPerformanceMetrics {
  final int fps;
  final double cpuUsagePercent;
  final int memoryUsageMB;
  final int frameRenderTimeMs;
  final DateTime timestamp;
  final String deviceInfo;

  SystemPerformanceMetrics({
    required this.fps,
    required this.cpuUsagePercent,
    required this.memoryUsageMB,
    required this.frameRenderTimeMs,
    required this.timestamp,
    required this.deviceInfo,
  });

  Map<String, dynamic> toJson() => {
        'fps': fps,
        'cpuUsagePercent': cpuUsagePercent,
        'memoryUsageMB': memoryUsageMB,
        'frameRenderTimeMs': frameRenderTimeMs,
        'timestamp': timestamp.toIso8601String(),
        'deviceInfo': deviceInfo,
      };
}

/// Метрики производительности модели ML
class ModelPerformanceMetrics {
  final String modelName;
  final int inferencLatencyMs;
  final int preprocessingTimeMs;
  final int postprocessingTimeMs;
  final int totalTimeMs;
  final int modelSizeMB;
  final String delegateType; // CPU, GPU, NNAPI, CoreML
  final DateTime timestamp;

  ModelPerformanceMetrics({
    required this.modelName,
    required this.inferencLatencyMs,
    required this.preprocessingTimeMs,
    required this.postprocessingTimeMs,
    required this.totalTimeMs,
    required this.modelSizeMB,
    required this.delegateType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'inferencLatencyMs': inferencLatencyMs,
        'preprocessingTimeMs': preprocessingTimeMs,
        'postprocessingTimeMs': postprocessingTimeMs,
        'totalTimeMs': totalTimeMs,
        'modelSizeMB': modelSizeMB,
        'delegateType': delegateType,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Сервис для двухуровневого профилирования производительности
class PerformanceProfiler {
  static final PerformanceProfiler _instance = PerformanceProfiler._internal();
  factory PerformanceProfiler() => _instance;
  PerformanceProfiler._internal();

  final List<SystemPerformanceMetrics> _systemMetrics = [];
  final List<ModelPerformanceMetrics> _modelMetrics = [];

  // FPS tracking
  final List<DateTime> _frameTimestamps = [];
  int _currentFPS = 0;

  // Memory tracking
  Timer? _memoryTrackingTimer;

  bool _isEnabled = false;

  /// Включить профилирование
  void enable() {
    _isEnabled = true;
    _startMemoryTracking();
  }

  /// Выключить профилирование
  void disable() {
    _isEnabled = false;
    _stopMemoryTracking();
  }

  /// Очистить собранные метрики
  void clearMetrics() {
    _systemMetrics.clear();
    _modelMetrics.clear();
    _frameTimestamps.clear();
  }

  /// Начать трассировку системной операции (для Flutter DevTools)
  void startSystemTrace(String name) {
    if (!_isEnabled) return;
    developer.Timeline.startSync(name);
  }

  /// Завершить трассировку системной операции
  void endSystemTrace(String name) {
    if (!_isEnabled) return;
    developer.Timeline.finishSync();
  }

  /// Записать кадр для расчета FPS
  void recordFrame() {
    if (!_isEnabled) return;

    final now = DateTime.now();
    _frameTimestamps.add(now);

    // Удаляем кадры старше 1 секунды
    final oneSecondAgo = now.subtract(const Duration(seconds: 1));
    _frameTimestamps
        .removeWhere((timestamp) => timestamp.isBefore(oneSecondAgo));

    _currentFPS = _frameTimestamps.length;
  }

  /// Записать метрики системы
  void recordSystemMetrics({
    required double cpuUsagePercent,
    required int memoryUsageMB,
    required int frameRenderTimeMs,
    required String deviceInfo,
  }) {
    if (!_isEnabled) return;

    final metrics = SystemPerformanceMetrics(
      fps: _currentFPS,
      cpuUsagePercent: cpuUsagePercent,
      memoryUsageMB: memoryUsageMB,
      frameRenderTimeMs: frameRenderTimeMs,
      timestamp: DateTime.now(),
      deviceInfo: deviceInfo,
    );

    _systemMetrics.add(metrics);

    // Ограничиваем количество метрик (последние 1000)
    if (_systemMetrics.length > 1000) {
      _systemMetrics.removeAt(0);
    }
  }

  /// Записать метрики модели ML
  void recordModelMetrics({
    required String modelName,
    required int inferencLatencyMs,
    required int preprocessingTimeMs,
    required int postprocessingTimeMs,
    required int modelSizeMB,
    required String delegateType,
  }) {
    if (!_isEnabled) return;

    final totalTimeMs =
        preprocessingTimeMs + inferencLatencyMs + postprocessingTimeMs;

    final metrics = ModelPerformanceMetrics(
      modelName: modelName,
      inferencLatencyMs: inferencLatencyMs,
      preprocessingTimeMs: preprocessingTimeMs,
      postprocessingTimeMs: postprocessingTimeMs,
      totalTimeMs: totalTimeMs,
      modelSizeMB: modelSizeMB,
      delegateType: delegateType,
      timestamp: DateTime.now(),
    );

    _modelMetrics.add(metrics);

    // Ограничиваем количество метрик (последние 500)
    if (_modelMetrics.length > 500) {
      _modelMetrics.removeAt(0);
    }
  }

  /// Обернуть выполнение операции для автоматического профилирования
  Future<T> profileOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!_isEnabled) return await operation();

    final stopwatch = Stopwatch()..start();
    startSystemTrace(operationName);

    try {
      final result = await operation();
      return result;
    } finally {
      stopwatch.stop();
      endSystemTrace(operationName);

      print('[$operationName] завершено за ${stopwatch.elapsedMilliseconds}мс');
    }
  }

  /// Синхронная версия профилирования операции
  T profileOperationSync<T>(
    String operationName,
    T Function() operation,
  ) {
    if (!_isEnabled) return operation();

    final stopwatch = Stopwatch()..start();
    startSystemTrace(operationName);

    try {
      final result = operation();
      return result;
    } finally {
      stopwatch.stop();
      endSystemTrace(operationName);

      print('[$operationName] завершено за ${stopwatch.elapsedMilliseconds}мс');
    }
  }

  /// Получить средние метрики системы за последние N записей
  SystemPerformanceMetrics? getAverageSystemMetrics({int lastN = 10}) {
    if (_systemMetrics.isEmpty) return null;

    final metrics = _systemMetrics.length > lastN
        ? _systemMetrics.sublist(_systemMetrics.length - lastN)
        : _systemMetrics;

    if (metrics.isEmpty) return null;

    final avgFps =
        metrics.map((m) => m.fps).reduce((a, b) => a + b) / metrics.length;
    final avgCpu =
        metrics.map((m) => m.cpuUsagePercent).reduce((a, b) => a + b) /
            metrics.length;
    final avgMemory =
        metrics.map((m) => m.memoryUsageMB).reduce((a, b) => a + b) /
            metrics.length;
    final avgFrameTime =
        metrics.map((m) => m.frameRenderTimeMs).reduce((a, b) => a + b) /
            metrics.length;

    return SystemPerformanceMetrics(
      fps: avgFps.round(),
      cpuUsagePercent: avgCpu,
      memoryUsageMB: avgMemory.round(),
      frameRenderTimeMs: avgFrameTime.round(),
      timestamp: DateTime.now(),
      deviceInfo: metrics.last.deviceInfo,
    );
  }

  /// Получить средние метрики модели за последние N записей
  ModelPerformanceMetrics? getAverageModelMetrics(String modelName,
      {int lastN = 10}) {
    final modelMetrics =
        _modelMetrics.where((m) => m.modelName == modelName).toList();

    if (modelMetrics.isEmpty) return null;

    final metrics = modelMetrics.length > lastN
        ? modelMetrics.sublist(modelMetrics.length - lastN)
        : modelMetrics;

    if (metrics.isEmpty) return null;

    final avgInference =
        metrics.map((m) => m.inferencLatencyMs).reduce((a, b) => a + b) /
            metrics.length;
    final avgPreprocess =
        metrics.map((m) => m.preprocessingTimeMs).reduce((a, b) => a + b) /
            metrics.length;
    final avgPostprocess =
        metrics.map((m) => m.postprocessingTimeMs).reduce((a, b) => a + b) /
            metrics.length;
    final avgTotal = metrics.map((m) => m.totalTimeMs).reduce((a, b) => a + b) /
        metrics.length;

    return ModelPerformanceMetrics(
      modelName: modelName,
      inferencLatencyMs: avgInference.round(),
      preprocessingTimeMs: avgPreprocess.round(),
      postprocessingTimeMs: avgPostprocess.round(),
      totalTimeMs: avgTotal.round(),
      modelSizeMB: metrics.last.modelSizeMB,
      delegateType: metrics.last.delegateType,
      timestamp: DateTime.now(),
    );
  }

  /// Экспортировать все метрики в JSON
  Map<String, dynamic> exportMetrics() {
    return {
      'systemMetrics': _systemMetrics.map((m) => m.toJson()).toList(),
      'modelMetrics': _modelMetrics.map((m) => m.toJson()).toList(),
      'currentFPS': _currentFPS,
      'totalFrames': _frameTimestamps.length,
      'exportTimestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Получить текущий FPS
  int get currentFPS => _currentFPS;

  /// Получить количество записанных системных метрик
  int get systemMetricsCount => _systemMetrics.length;

  /// Получить количество записанных метрик моделей
  int get modelMetricsCount => _modelMetrics.length;

  /// Приватный метод для отслеживания памяти
  void _startMemoryTracking() {
    _memoryTrackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // TODO: Реализовать получение актуальных метрик системы
      // Пока используем заглушки для демонстрации
      recordSystemMetrics(
        cpuUsagePercent: 0.0, // Будет реализовано позже
        memoryUsageMB: 0, // Будет реализовано позже
        frameRenderTimeMs: 16, // Целевое значение для 60 FPS
        deviceInfo: 'Unknown Device', // Будет реализовано позже
      );
    });
  }

  /// Приватный метод для остановки отслеживания памяти
  void _stopMemoryTracking() {
    _memoryTrackingTimer?.cancel();
    _memoryTrackingTimer = null;
  }
}
