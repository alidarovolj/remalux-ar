import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../utils/image_converter.dart';
import 'performance_profiler.dart';

/// Сервис для работы с Roboflow API для сегментации стен
class RoboflowWallSegmentationService {
  static final RoboflowWallSegmentationService _instance =
      RoboflowWallSegmentationService._internal();
  factory RoboflowWallSegmentationService() => _instance;
  RoboflowWallSegmentationService._internal();

  // API конфигурация
  static const String _apiUrl = 'https://serverless.roboflow.com';
  static const String _modelEndpoint = 'wall_segmentation-flyds-hxhvv/1';
  static const String _apiKey = 'VDaf6TftUQZlE4pfp2tc';

  final PerformanceProfiler _profiler = PerformanceProfiler();

  bool _isInitialized = false;
  int? _modelWidth;
  int? _modelHeight;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Initializing Roboflow Wall Segmentation Service...');

      // Тестовый запрос для проверки доступности API
      await _testApiConnection();

      _isInitialized = true;
      debugPrint('✅ Roboflow service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Roboflow service: $e');
      rethrow;
    }
  }

  /// Тест соединения с API
  Future<void> _testApiConnection() async {
    try {
      debugPrint('🔗 Testing Roboflow API connection...');
      final response = await http.get(
        Uri.parse('$_apiUrl/$_modelEndpoint'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('🌐 Roboflow API connection successful');
      } else {
        debugPrint(
            '⚠️ API connection test failed with status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('API responded with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ API connection test failed: $e');
      // Не бросаем исключение, продолжаем работу в локальном режиме
    }
  }

  /// Обработка кадра камеры для сегментации стен
  Future<WallSegmentationResult?> processFrame(CameraImage cameraImage) async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _profiler.profileOperation('roboflow_inference', () async {
      try {
        // Конвертация CameraImage в Uint8List
        final imageBytes = await _convertCameraImageToBytes(cameraImage);

        // Отправка на API
        final response = await _sendInferenceRequest(imageBytes);

        // Обработка ответа
        final result = await _processApiResponse(response, cameraImage);

        return result;
      } catch (e) {
        debugPrint('❌ Frame processing failed: $e');
        return null;
      }
    });
  }

  /// Конвертация CameraImage в байты для API
  Future<Uint8List> _convertCameraImageToBytes(CameraImage cameraImage) async {
    try {
      // Конвертация CameraImage в img.Image
      final image = ImageConverter.convertCameraImage(cameraImage);

      if (image == null) {
        throw Exception('Failed to convert camera image');
      }

      // Изменение размера для оптимизации (640x640 оптимально для API)
      final resized = img.copyResize(image, width: 640, height: 640);

      // Кодирование в JPEG для API
      final jpegBytes = img.encodeJpg(resized, quality: 85);

      return Uint8List.fromList(jpegBytes);
    } catch (e) {
      debugPrint('❌ Image conversion failed: $e');
      rethrow;
    }
  }

  /// Отправка запроса на Roboflow API
  Future<Map<String, dynamic>> _sendInferenceRequest(
      Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$_apiUrl/$_modelEndpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $_apiKey',
        },
        body: {
          'api_key': _apiKey,
          'image': base64Image,
          'confidence': '0.5', // Порог уверенности
          'overlap': '0.3', // Порог перекрытия
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ API request failed: $e');
      rethrow;
    }
  }

  /// Обработка ответа от API и создание маски
  Future<WallSegmentationResult> _processApiResponse(
      Map<String, dynamic> response, CameraImage originalImage) async {
    try {
      final predictions = response['predictions'] as List? ?? [];

      if (predictions.isEmpty) {
        debugPrint('⚠️ No wall predictions found');
        return WallSegmentationResult.empty(
            originalImage.width, originalImage.height);
      }

      // Создание маски из предсказаний
      final mask = await _createMaskFromPredictions(
          predictions, originalImage.width, originalImage.height);

      final processingTime = response['inference_time'] as num? ?? 0;

      debugPrint(
          '✅ Processed ${predictions.length} wall segments in ${processingTime}ms');

      return WallSegmentationResult(
        mask: mask,
        confidence: _calculateAverageConfidence(predictions),
        segmentCount: predictions.length,
        processingTimeMs: processingTime.toInt(),
        originalWidth: originalImage.width,
        originalHeight: originalImage.height,
      );
    } catch (e) {
      debugPrint('❌ Response processing failed: $e');
      rethrow;
    }
  }

  /// Создание бинарной маски из предсказаний Roboflow
  Future<Uint8List> _createMaskFromPredictions(
      List<dynamic> predictions, int width, int height) async {
    // Создаем пустую маску
    final mask = Uint8List(width * height);

    for (final prediction in predictions) {
      final className = prediction['class'] as String? ?? '';
      final confidence = prediction['confidence'] as num? ?? 0.0;

      // Обрабатываем только стены с достаточной уверенностью
      if (className.toLowerCase().contains('wall') && confidence > 0.5) {
        final points = prediction['points'] as List?;

        if (points != null && points.isNotEmpty) {
          // Конвертируем точки в полигон
          final polygon = points
              .map((point) => [
                    (point['x'] as num).toDouble(),
                    (point['y'] as num).toDouble(),
                  ])
              .toList();

          // Заполняем полигон в маске
          _fillPolygonInMask(mask, polygon, width, height);
        }
      }
    }

    return mask;
  }

  /// Заполнение полигона в маске (алгоритм scanline)
  void _fillPolygonInMask(
      Uint8List mask, List<List<double>> polygon, int width, int height) {
    if (polygon.length < 3) return;

    // Нормализация координат из 640x640 к оригинальному размеру
    final scaledPolygon = polygon
        .map((point) => [
              (point[0] / 640.0 * width).round(),
              (point[1] / 640.0 * height).round(),
            ])
        .toList();

    // Простой алгоритм заполнения - сканируем по строкам
    for (int y = 0; y < height; y++) {
      final intersections = <int>[];

      // Находим пересечения луча с полигоном
      for (int i = 0; i < scaledPolygon.length; i++) {
        final j = (i + 1) % scaledPolygon.length;
        final x1 = scaledPolygon[i][0];
        final y1 = scaledPolygon[i][1];
        final x2 = scaledPolygon[j][0];
        final y2 = scaledPolygon[j][1];

        if ((y1 <= y && y < y2) || (y2 <= y && y < y1)) {
          final x = (x1 + (y - y1) * (x2 - x1) / (y2 - y1)).round();
          if (x >= 0 && x < width) {
            intersections.add(x);
          }
        }
      }

      // Сортируем пересечения и заполняем между парами
      intersections.sort();
      for (int i = 0; i < intersections.length - 1; i += 2) {
        final startX = intersections[i];
        final endX = intersections[i + 1];

        for (int x = startX; x <= endX && x < width; x++) {
          mask[y * width + x] = 255;
        }
      }
    }
  }

  /// Расчет средней уверенности
  double _calculateAverageConfidence(List<dynamic> predictions) {
    if (predictions.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int wallCount = 0;

    for (final prediction in predictions) {
      final className = prediction['class'] as String? ?? '';
      if (className.toLowerCase().contains('wall')) {
        totalConfidence += prediction['confidence'] as num? ?? 0.0;
        wallCount++;
      }
    }

    return wallCount > 0 ? totalConfidence / wallCount : 0.0;
  }

  /// Проверка готовности сервиса
  bool get isInitialized => _isInitialized;

  /// Освобождение ресурсов
  void dispose() {
    _isInitialized = false;
    debugPrint('🧹 Roboflow service disposed');
  }
}

/// Результат сегментации стен
class WallSegmentationResult {
  final Uint8List mask;
  final double confidence;
  final int segmentCount;
  final int processingTimeMs;
  final int originalWidth;
  final int originalHeight;

  WallSegmentationResult({
    required this.mask,
    required this.confidence,
    required this.segmentCount,
    required this.processingTimeMs,
    required this.originalWidth,
    required this.originalHeight,
  });

  /// Создание пустого результата
  factory WallSegmentationResult.empty(int width, int height) {
    return WallSegmentationResult(
      mask: Uint8List(width * height),
      confidence: 0.0,
      segmentCount: 0,
      processingTimeMs: 0,
      originalWidth: width,
      originalHeight: height,
    );
  }

  /// Конвертация в UI.Image для отображения
  Future<ui.Image> toUIImage() async {
    final rgbaBytes = Uint8List(mask.length * 4);

    for (int i = 0; i < mask.length; i++) {
      final value = mask[i];
      rgbaBytes[i * 4] = value; // R
      rgbaBytes[i * 4 + 1] = value; // G
      rgbaBytes[i * 4 + 2] = value; // B
      rgbaBytes[i * 4 + 3] = value; // A
    }

    final codec = await ui.instantiateImageCodec(
      rgbaBytes,
      targetWidth: originalWidth,
      targetHeight: originalHeight,
    );

    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Map<String, dynamic> toJson() => {
        'confidence': confidence,
        'segmentCount': segmentCount,
        'processingTimeMs': processingTimeMs,
        'originalWidth': originalWidth,
        'originalHeight': originalHeight,
      };
}
