import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class WallPainterScreen extends StatefulWidget {
  final Color? initialColor;

  const WallPainterScreen({super.key, this.initialColor});

  @override
  State<WallPainterScreen> createState() => _WallPainterScreenState();
}

class _WallPainterScreenState extends State<WallPainterScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  late Color _selectedColor;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  bool _isModelLoaded = false;
  Path? _maskPath;
  bool _isProcessing = false;
  // Timer? _processingTimer; // Removed placeholder timer

  // Model input/output details
  List<int>? _inputShape;
  List<int>? _outputShape;
  TensorType? _inputType;
  TensorType? _outputType;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? Colors.blue;
    _initCamera();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      const modelPath = 'assets/ml/1.tflite';
      final interpreterOptions = InterpreterOptions();

      // Create the base interpreter
      _interpreter =
          await Interpreter.fromAsset(modelPath, options: interpreterOptions);

      // Allocate tensors for the base interpreter
      _interpreter!.allocateTensors();

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      _inputShape = inputTensor.shape;
      _inputType = inputTensor.type;
      _outputShape = outputTensor.shape;
      _outputType = outputTensor.type;

      _isolateInterpreter =
          await IsolateInterpreter.create(address: _interpreter!.address);

      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      // Ensure model is marked as not loaded on error
      setState(() {
        _isModelLoaded = false;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high, // Changed to high for better detail
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup
              .bgra8888, // BGRA8888 for easier conversion with image package on iOS
        );

        await _cameraController!.initialize();

        _cameraController!.startImageStream(_processCameraImage);

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error in _initCamera: $e');
    }
  }

  // Removed _startProcessingTimer and _generatePlaceholderMask as they are no longer needed

  img.Image _convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return img.Image.fromBytes(
        width: cameraImage.planes[0].width!,
        height: cameraImage.planes[0].height!,
        bytes: cameraImage.planes[0].bytes.buffer, // Correct: ByteBuffer
        order: img.ChannelOrder.bgra,
      );
    } else if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      final int width = cameraImage.width;
      final int height = cameraImage.height;
      final image = img.Image(width: width, height: height);
      final plane0 = cameraImage.planes[0].bytes;
      final plane1 = cameraImage.planes[1].bytes;
      final plane2 = cameraImage.planes[2].bytes;
      final rowStride0 = cameraImage.planes[0].bytesPerRow;
      final pixelStride1 = cameraImage.planes[1].bytesPerPixel!;
      final rowStride1 = cameraImage.planes[1].bytesPerRow;
      final pixelStride2 = cameraImage.planes[2].bytesPerPixel!;
      final rowStride2 = cameraImage.planes[2].bytesPerRow;

      for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
          final int Y = plane0[y * rowStride0 + x];
          final int U = plane1[(y ~/ 2) * rowStride1 + (x ~/ 2) * pixelStride1];
          final int V = plane2[(y ~/ 2) * rowStride2 + (x ~/ 2) * pixelStride2];

          final int R = (Y + 1.402 * (V - 128)).round().clamp(0, 255);
          final int G = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128))
              .round()
              .clamp(0, 255);
          final int B = (Y + 1.772 * (U - 128)).round().clamp(0, 255);
          image.setPixelRgb(x, y, R, G, B);
        }
      }
      return image;
    } else {
      return img.Image(width: 1, height: 1); // Return minimal image
    }
  }

  List<List<List<List<double>>>> _prepareImageForModel(
      CameraImage cameraImage) {
    if (_inputShape == null || _inputType == null) {
      return [];
    }
    if (_inputType != TensorType.float32) {
      return [];
    }

    img.Image image = _convertCameraImage(cameraImage);
    if (image.width <= 1 || image.height <= 1) {
      return [];
    }

    final modelInputHeight = _inputShape![1];
    final modelInputWidth = _inputShape![2];
    img.Image resizedImage =
        img.copyResize(image, width: modelInputWidth, height: modelInputHeight);

    var inputBatch = List.generate(
        1,
        (_) => List.generate(
            modelInputHeight,
            (y) => List.generate(modelInputWidth, (x) {
                  final pixel = resizedImage.getPixel(x, y);
                  return [
                    (pixel.r.toDouble() - 127.5) / 127.5,
                    (pixel.g.toDouble() - 127.5) / 127.5,
                    (pixel.b.toDouble() - 127.5) / 127.5
                  ];
                }, growable: false),
            growable: false),
        growable: false);

    return inputBatch;
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (!_isModelLoaded ||
        _interpreter == null ||
        _isolateInterpreter == null ||
        _isProcessing ||
        _inputShape == null ||
        _outputShape == null ||
        _inputType == null ||
        _outputType == null) {
      return;
    }

    // Save screen dimensions before async operations
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    _isProcessing = true;

    try {
      final input = _prepareImageForModel(cameraImage);
      if (input.isEmpty) {
        _isProcessing = false;
        return;
      }

      var output = <int, Object>{};
      if (_outputType == TensorType.float32) {
        final outputSize = _outputShape!.reduce((a, b) => a * b);
        final flatOutputBuffer = Float32List(outputSize);
        output = {0: flatOutputBuffer};
      } else {
        _isProcessing = false;
        return;
      }

      await _isolateInterpreter!.run(input, output);

      // --- Temporarily comment out output processing to test if run succeeds ---
      // /* // MODIFIED_BLOCK_START - REMOVING COMMENT

      // Get the flat output buffer
      final flatOutputBuffer = output[0]! as Float32List;

      final int outputHeight = _outputShape![1]; // 65
      final int outputWidth = _outputShape![2]; // 65
      final int numClasses = _outputShape![3]; // 21
      const int wallClassIndex = 1; // Placeholder index

      Path newMaskPath = Path();
      // Scaling factors to map model output coordinates to screen coordinates
      // Note: This assumes the CameraPreview fills the screen width/height.
      // Adjust if your layout is different.
      final double scaleX = screenWidth / outputWidth;
      final double scaleY = screenHeight / outputHeight;

      // Iterate through the output buffer
      for (int y = 0; y < outputHeight; y++) {
        for (int x = 0; x < outputWidth; x++) {
          // Find the class with the highest score for pixel (y, x)
          double maxScore = -double.infinity;
          int predictedClass = 0;
          // Calculate the starting index for this pixel's class scores in the flat buffer
          int pixelStartIndex = y * outputWidth * numClasses + x * numClasses;

          for (int c = 0; c < numClasses; c++) {
            final score = flatOutputBuffer[pixelStartIndex + c];
            if (score > maxScore) {
              maxScore = score;
              predictedClass = c;
            }
          }

          // If the predicted class is the wall class, add a rectangle to the mask path
          if (predictedClass == wallClassIndex) {
            // Use scale factors for screen coordinates
            newMaskPath
                .addRect(Rect.fromLTWH(x * scaleX, y * scaleY, scaleX, scaleY));
          }
        }
      }

      if (mounted) {
        setState(() {
          _maskPath = newMaskPath;
        });
      }
      // */ // MODIFIED_BLOCK_END - REMOVING COMMENT
      // --- End of temporarily commented out block ---
    } catch (e, stackTrace) {
      debugPrint("Error processing image: $e");
      debugPrint("Stack trace: $stackTrace");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    // _processingTimer?.cancel(); // Removed
    _cameraController
        ?.stopImageStream(); // Stop stream before disposing controller
    _cameraController?.dispose();
    _isolateInterpreter?.close();
    _interpreter?.close(); // Close original interpreter
    // _ortSession?.release(); // Commented out
    // _ortEnv?.release(); // Commented out
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !_isModelLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Wall Painter (Placeholder)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: _showColorPicker,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: CameraPreview(_cameraController!)),
          if (_maskPath != null)
            CustomPaint(
              painter: MaskPainter(maskPath: _maskPath!, color: _selectedColor),
              child: Container(), // CustomPaint needs a child
            ),
        ],
      ),
    );
  }

  // Widget _buildBlendModeButton(String name, BlendMode mode) { // Commented out
  //   // ... entire method commented ...
  // }

  // Widget _buildColorButton(Color color) { // Commented out
  //    // ... entire method commented ...
  // }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
                // No need to explicitly update mask here,
                // MaskPainter will use the new _selectedColor on next repaint
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }
}

class MaskPainter extends CustomPainter {
  final Path maskPath;
  final Color color;

  MaskPainter({required this.maskPath, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(maskPath, paint);
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.maskPath != maskPath || oldDelegate.color != color;
  }
}
