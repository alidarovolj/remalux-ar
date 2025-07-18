import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:remalux_ar/core/utils/image_converter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SegmentationService {
  late Interpreter _interpreter;
  late List<String> _labels;
  late List<int> _inputShape;
  late List<int> _outputShape;

  static const String modelPath = 'assets/ml/1.tflite';
  static const String labelsPath = 'assets/ml/ade20k_labels.txt';

  // Public getters for mask dimensions
  int? get maskWidth => _outputShape.isNotEmpty ? _outputShape[2] : null;
  int? get maskHeight => _outputShape.isNotEmpty ? _outputShape[1] : null;

  Future<void> loadModel() async {
    final options = InterpreterOptions();

    // Use XNNPACK delegate for better performance
    try {
      final delegate = XNNPackDelegate();
      options.addDelegate(delegate);
    } catch (e) {
      debugPrint('XNNPACK delegate not available: $e');
    }

    _interpreter = await Interpreter.fromAsset(modelPath, options: options);
    await _loadLabels();

    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;

    debugPrint('Interpreter and labels loaded successfully');
    debugPrint('Input shape: $_inputShape');
    debugPrint('Output shape: $_outputShape');
    debugPrint('Labels loaded: ${_labels.length} classes');
    debugPrint(
        'Wall class index: ${_labels.indexWhere((label) => label.contains("wall"))}');
  }

  Future<void> _loadLabels() async {
    final labelsRaw = await rootBundle.loadString(labelsPath);
    _labels = labelsRaw.split('\n');
  }

  Uint8List? processCameraImage(CameraImage cameraImage) {
    final image = ImageConverter.convertCameraImage(cameraImage);
    if (image == null) {
      return null;
    }

    final resizedImage = img.copyResize(
      image,
      width: _inputShape[2],
      height: _inputShape[1],
      interpolation: img.Interpolation.linear,
    );

    final inputBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final inputBuffer = Float32List(_inputShape.reduce((a, b) => a * b));
    for (int i = 0; i < inputBytes.length; i++) {
      inputBuffer[i] = inputBytes[i] / 255.0;
    }

    final reshapedInput = inputBuffer.reshape(_inputShape);

    final outputBuffer = List.filled(
      _outputShape.reduce((a, b) => a * b),
      0,
    ).reshape(_outputShape);

    _interpreter.run(reshapedInput, outputBuffer);

    final segmentationMap = outputBuffer[0];
    final wallClassIndex =
        _labels.indexWhere((label) => label.contains('wall'));

    if (wallClassIndex == -1) {
      debugPrint("Warning: 'wall' class not found in labels.");
      return null;
    }

    final mask = Uint8List(_outputShape[1] * _outputShape[2]);
    int wallPixelCount = 0;
    int totalPixels = 0;

    for (int i = 0; i < segmentationMap.length; i++) {
      for (int j = 0; j < segmentationMap[i].length; j++) {
        totalPixels++;
        if (segmentationMap[i][j] == wallClassIndex) {
          mask[i * _outputShape[2] + j] = 1;
          wallPixelCount++;
        } else {
          mask[i * _outputShape[2] + j] = 0;
        }
      }
    }

    final wallPercentage =
        (wallPixelCount / totalPixels * 100).toStringAsFixed(1);
    debugPrint(
        '🏠 Wall detection: $wallPixelCount/$totalPixels pixels ($wallPercentage%)');

    return mask;
  }
}
