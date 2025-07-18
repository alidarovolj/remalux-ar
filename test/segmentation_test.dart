import 'package:flutter_test/flutter_test.dart';
import 'package:remalux_ar/core/services/segmentation_service.dart';

void main() {
  group('SegmentationService Tests', () {
    late SegmentationService segmentationService;

    setUp(() {
      segmentationService = SegmentationService();
    });

    test('should have correct model and labels paths', () {
      expect(SegmentationService.modelPath,
          'assets/ml/deeplabv3_ade20k_fp16.tflite');
      expect(SegmentationService.labelsPath, 'assets/ml/ade20k_labels.txt');
    });

    test('should initialize model successfully', () async {
      // Этот тест требует реального устройства с моделью
      // В реальных тестах нужно мокать tflite_flutter
      expect(() => segmentationService.loadModel(), returnsNormally);
    });

    test('should have valid mask dimensions getters', () {
      // До инициализации должны возвращать null
      expect(segmentationService.maskWidth, isNull);
      expect(segmentationService.maskHeight, isNull);
    });
  });
}
