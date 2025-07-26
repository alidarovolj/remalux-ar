import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Тип GPU архитектуры
enum GPUArchitecture {
  adreno, // Qualcomm Snapdragon
  mali, // ARM Mali (MediaTek, Exynos)
  appleGPU, // Apple Neural Engine
  tegra, // NVIDIA Tegra
  unknown,
}

/// Класс производительности устройства
enum DevicePerformanceTier {
  highEnd, // Флагманские устройства
  midRange, // Средний сегмент
  lowEnd, // Бюджетные устройства
}

/// Информация о возможностях устройства
class DeviceCapabilities {
  final String deviceModel;
  final String osVersion;
  final GPUArchitecture gpuArchitecture;
  final String gpuModel;
  final DevicePerformanceTier performanceTier;
  final int totalRAMMB;
  final int availableRAMMB;
  final bool supportsNNAPI;
  final bool supportsCoreML;
  final bool supportsGPUDelegate;
  final int recommendedModelIndex;
  final Map<String, dynamic> optimizationSettings;

  DeviceCapabilities({
    required this.deviceModel,
    required this.osVersion,
    required this.gpuArchitecture,
    required this.gpuModel,
    required this.performanceTier,
    required this.totalRAMMB,
    required this.availableRAMMB,
    required this.supportsNNAPI,
    required this.supportsCoreML,
    required this.supportsGPUDelegate,
    required this.recommendedModelIndex,
    required this.optimizationSettings,
  });

  Map<String, dynamic> toJson() => {
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'gpuArchitecture': gpuArchitecture.name,
        'gpuModel': gpuModel,
        'performanceTier': performanceTier.name,
        'totalRAMMB': totalRAMMB,
        'availableRAMMB': availableRAMMB,
        'supportsNNAPI': supportsNNAPI,
        'supportsCoreML': supportsCoreML,
        'supportsGPUDelegate': supportsGPUDelegate,
        'recommendedModelIndex': recommendedModelIndex,
        'optimizationSettings': optimizationSettings,
      };
}

/// Сервис для детекции возможностей устройства
class DeviceCapabilityDetector {
  static final DeviceCapabilityDetector _instance =
      DeviceCapabilityDetector._internal();
  factory DeviceCapabilityDetector() => _instance;
  DeviceCapabilityDetector._internal();

  DeviceCapabilities? _capabilities;
  bool _isDetectionCompleted = false;

  /// Получить возможности устройства (кэшированные или детектировать)
  Future<DeviceCapabilities> getDeviceCapabilities() async {
    if (_capabilities != null && _isDetectionCompleted) {
      return _capabilities!;
    }

    _capabilities = await _detectCapabilities();
    _isDetectionCompleted = true;
    return _capabilities!;
  }

  /// Основной метод детекции возможностей
  Future<DeviceCapabilities> _detectCapabilities() async {
    debugPrint('🔍 Detecting device capabilities...');

    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';
    int totalRAMMB = 4096; // Fallback значение

    if (Platform.isAndroid) {
      // Упрощенная детекция для Android
      deviceModel = 'Android Device';
      osVersion = 'Android';
      totalRAMMB = 4096; // Базовое значение
    } else if (Platform.isIOS) {
      // Упрощенная детекция для iOS
      deviceModel = 'iOS Device';
      osVersion = 'iOS';
      totalRAMMB = 6144; // iOS устройства обычно имеют больше RAM
    }

    // Детекция GPU архитектуры
    final gpuInfo = await _detectGPUArchitecture(deviceModel);
    final gpuArchitecture = gpuInfo['architecture'] as GPUArchitecture;
    final gpuModel = gpuInfo['model'] as String;

    // Определение класса производительности
    final performanceTier =
        _determinePerformanceTier(deviceModel, totalRAMMB, gpuArchitecture);

    // Детекция поддержки делегатов
    final supportsNNAPI = Platform.isAndroid && await _testNNAPISupport();
    final supportsCoreML = Platform.isIOS && await _testCoreMLSupport();
    final supportsGPUDelegate = await _testGPUDelegateSupport();

    // Примерная оценка доступной памяти (70% от общей)
    final availableRAMMB = (totalRAMMB * 0.7).round();

    // Рекомендованная модель на основе возможностей
    final recommendedModelIndex =
        _selectOptimalModel(performanceTier, gpuArchitecture, availableRAMMB);

    // Настройки оптимизации
    final optimizationSettings = _generateOptimizationSettings(
      gpuArchitecture,
      performanceTier,
      supportsNNAPI,
      supportsCoreML,
      supportsGPUDelegate,
    );

    final capabilities = DeviceCapabilities(
      deviceModel: deviceModel,
      osVersion: osVersion,
      gpuArchitecture: gpuArchitecture,
      gpuModel: gpuModel,
      performanceTier: performanceTier,
      totalRAMMB: totalRAMMB,
      availableRAMMB: availableRAMMB,
      supportsNNAPI: supportsNNAPI,
      supportsCoreML: supportsCoreML,
      supportsGPUDelegate: supportsGPUDelegate,
      recommendedModelIndex: recommendedModelIndex,
      optimizationSettings: optimizationSettings,
    );

    debugPrint('✅ Device capabilities detected:');
    debugPrint('   Device: $deviceModel');
    debugPrint('   GPU: ${gpuArchitecture.name} ($gpuModel)');
    debugPrint('   Tier: ${performanceTier.name}');
    debugPrint('   RAM: ${totalRAMMB}MB (${availableRAMMB}MB available)');
    debugPrint('   Recommended model: $recommendedModelIndex');
    debugPrint(
        '   NNAPI: $supportsNNAPI, CoreML: $supportsCoreML, GPU: $supportsGPUDelegate');

    return capabilities;
  }

  /// Детекция архитектуры GPU
  Future<Map<String, dynamic>> _detectGPUArchitecture(
      String deviceModel) async {
    final model = deviceModel.toLowerCase();

    // Apple устройства
    if (Platform.isIOS || model.contains('iphone') || model.contains('ipad')) {
      return {
        'architecture': GPUArchitecture.appleGPU,
        'model': 'Apple GPU',
      };
    }

    // Android устройства - анализируем по производителю/модели
    if (model.contains('samsung')) {
      if (model.contains('galaxy s') ||
          model.contains('galaxy note') ||
          model.contains('galaxy a')) {
        // Samsung может использовать Snapdragon или Exynos
        if (model.contains('sm-') || await _isSnapdragonDevice()) {
          return {
            'architecture': GPUArchitecture.adreno,
            'model': 'Adreno (Snapdragon)',
          };
        } else {
          return {
            'architecture': GPUArchitecture.mali,
            'model': 'Mali (Exynos)',
          };
        }
      }
    }

    if (model.contains('xiaomi') ||
        model.contains('redmi') ||
        model.contains('poco')) {
      return {
        'architecture': GPUArchitecture.adreno,
        'model': 'Adreno (Snapdragon)',
      };
    }

    if (model.contains('oppo') ||
        model.contains('oneplus') ||
        model.contains('realme')) {
      return {
        'architecture': GPUArchitecture.adreno,
        'model': 'Adreno (Snapdragon)',
      };
    }

    if (model.contains('vivo')) {
      return {
        'architecture': GPUArchitecture.adreno,
        'model': 'Adreno (Snapdragon)',
      };
    }

    if (model.contains('huawei') || model.contains('honor')) {
      return {
        'architecture': GPUArchitecture.mali,
        'model': 'Mali (Kirin)',
      };
    }

    if (model.contains('mediatek') || model.contains('mt')) {
      return {
        'architecture': GPUArchitecture.mali,
        'model': 'Mali (MediaTek)',
      };
    }

    if (model.contains('nvidia') || model.contains('tegra')) {
      return {
        'architecture': GPUArchitecture.tegra,
        'model': 'Tegra GPU',
      };
    }

    // Fallback - пытаемся детектировать через системные свойства
    if (Platform.isAndroid) {
      if (await _isSnapdragonDevice()) {
        return {
          'architecture': GPUArchitecture.adreno,
          'model': 'Adreno (detected)',
        };
      }
    }

    return {
      'architecture': GPUArchitecture.unknown,
      'model': 'Unknown GPU',
    };
  }

  /// Проверка на Snapdragon через системные свойства
  Future<bool> _isSnapdragonDevice() async {
    if (!Platform.isAndroid) return false;

    try {
      // Пытаемся проверить через platform channel (требует нативной реализации)
      // Пока используем fallback логику
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Оценка RAM для Android устройств (упрощенная версия)
  int _estimateAndroidRAM(String deviceModel) {
    // Базовая логика на основе модели
    final model = deviceModel.toLowerCase();

    if (model.contains('flagship') ||
        model.contains('pro') ||
        model.contains('ultra')) {
      return 8192; // 8GB для флагманов
    } else if (model.contains('plus') || model.contains('note')) {
      return 6144; // 6GB для старших моделей
    } else {
      return 4096; // 4GB для базовых моделей
    }
  }

  /// Оценка RAM для iOS устройств
  int _estimateIOSRAM(String model) {
    final modelLower = model.toLowerCase();

    if (modelLower.contains('iphone 15') || modelLower.contains('iphone 14')) {
      return 6144; // 6GB для новых iPhone
    } else if (modelLower.contains('iphone 13') ||
        modelLower.contains('iphone 12')) {
      return 6144; // 6GB
    } else if (modelLower.contains('ipad pro')) {
      return 8192; // 8GB для iPad Pro
    } else if (modelLower.contains('ipad')) {
      return 4096; // 4GB для обычных iPad
    } else {
      return 4096; // 4GB для старых iPhone
    }
  }

  /// Определение класса производительности
  DevicePerformanceTier _determinePerformanceTier(
      String deviceModel, int totalRAMMB, GPUArchitecture gpuArchitecture) {
    final model = deviceModel.toLowerCase();

    // High-end критерии
    if (totalRAMMB >= 8192) return DevicePerformanceTier.highEnd;

    if (gpuArchitecture == GPUArchitecture.appleGPU) {
      return DevicePerformanceTier.highEnd; // Apple устройства обычно high-end
    }

    if (model.contains('flagship') ||
        model.contains('pro') ||
        model.contains('ultra') ||
        model.contains('galaxy s') ||
        model.contains('oneplus') ||
        model.contains('xiaomi 1') ||
        totalRAMMB >= 6144) {
      return DevicePerformanceTier.highEnd;
    }

    // Low-end критерии
    if (totalRAMMB <= 3072 ||
        model.contains('lite') ||
        model.contains('go') ||
        model.contains('mini')) {
      return DevicePerformanceTier.lowEnd;
    }

    // Все остальное - mid-range
    return DevicePerformanceTier.midRange;
  }

  /// Тест поддержки NNAPI
  Future<bool> _testNNAPISupport() async {
    if (!Platform.isAndroid) return false;

    try {
      // В реальной реализации нужен platform channel для проверки NNAPI
      // Пока возвращаем true для Android 8+ (API 27+)
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Тест поддержки Core ML
  Future<bool> _testCoreMLSupport() async {
    if (!Platform.isIOS) return false;

    try {
      // В реальной реализации проверяем доступность Core ML
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Тест поддержки GPU делегата
  Future<bool> _testGPUDelegateSupport() async {
    try {
      // Базовая проверка - возвращаем true для современных устройств
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Выбор оптимальной модели
  int _selectOptimalModel(
    DevicePerformanceTier tier,
    GPUArchitecture gpu,
    int availableRAMMB,
  ) {
    // Логика выбора модели:
    // 0 = ADE20K Standard (2MB)
    // 1 = Wall Specialized (3MB)
    // 2 = Wall Mobile Optimized (7MB)

    switch (tier) {
      case DevicePerformanceTier.highEnd:
        // Флагманы могут использовать любую модель
        if (gpu == GPUArchitecture.adreno) {
          return 1; // Specialized оптимизирована для Adreno
        } else if (gpu == GPUArchitecture.appleGPU) {
          return 2; // Mobile лучше работает на Apple Neural Engine
        } else {
          return 1; // Specialized для остальных high-end
        }

      case DevicePerformanceTier.midRange:
        // Средний сегмент - баланс качества и производительности
        if (availableRAMMB >= 4096) {
          return 1; // Specialized если достаточно памяти
        } else {
          return 0; // Standard для ограниченной памяти
        }

      case DevicePerformanceTier.lowEnd:
        // Бюджетные устройства - приоритет производительности
        return 0; // Всегда Standard модель
    }
  }

  /// Генерация настроек оптимизации
  Map<String, dynamic> _generateOptimizationSettings(
    GPUArchitecture gpu,
    DevicePerformanceTier tier,
    bool supportsNNAPI,
    bool supportsCoreML,
    bool supportsGPUDelegate,
  ) {
    final settings = <String, dynamic>{};

    // Настройки делегатов
    if (Platform.isIOS && supportsCoreML) {
      settings['preferredDelegate'] = 'CoreML';
      settings['useGPU'] = true;
    } else if (Platform.isAndroid && supportsNNAPI) {
      settings['preferredDelegate'] = 'NNAPI';
      settings['useGPU'] = supportsGPUDelegate;
    } else if (supportsGPUDelegate) {
      settings['preferredDelegate'] = 'GPU';
      settings['useGPU'] = true;
    } else {
      settings['preferredDelegate'] = 'CPU';
      settings['useGPU'] = false;
    }

    // Настройки производительности
    switch (tier) {
      case DevicePerformanceTier.highEnd:
        settings['numThreads'] = 4;
        settings['targetFPS'] = 30;
        settings['enableOpticalFlow'] = true;
        settings['morphologicalOps'] = true;
        break;

      case DevicePerformanceTier.midRange:
        settings['numThreads'] = 2;
        settings['targetFPS'] = 25;
        settings['enableOpticalFlow'] = false;
        settings['morphologicalOps'] = true;
        break;

      case DevicePerformanceTier.lowEnd:
        settings['numThreads'] = 1;
        settings['targetFPS'] = 20;
        settings['enableOpticalFlow'] = false;
        settings['morphologicalOps'] = false;
        break;
    }

    // GPU-специфичные настройки
    switch (gpu) {
      case GPUArchitecture.adreno:
        settings['workgroupSize'] = 16;
        settings['precision'] = 'fp16';
        break;

      case GPUArchitecture.mali:
        settings['workgroupSize'] = 8;
        settings['precision'] = 'fp16';
        break;

      case GPUArchitecture.appleGPU:
        settings['workgroupSize'] = 32;
        settings['precision'] = 'fp16';
        settings['useMetalPerformanceShaders'] = true;
        break;

      default:
        settings['workgroupSize'] = 8;
        settings['precision'] = 'fp32';
        break;
    }

    return settings;
  }

  /// Сброс кэша для повторной детекции
  void clearCache() {
    _capabilities = null;
    _isDetectionCompleted = false;
  }
}
