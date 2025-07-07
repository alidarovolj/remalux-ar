import 'dart:async';
// import 'dart:io'; // Commented out for now
import 'dart:math'; // No longer needed for placeholder
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for rootBundle to load the model
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'dart:io'; // Needed for Platform
import 'ar_wall_painter_screen_simple.dart';
// import 'package:onnxruntime/onnxruntime.dart'; // Not needed if model is out
// import 'package:path_provider/path_provider.dart'; // Not needed for now
// import 'package:permission_handler/permission_handler.dart'; // Permissions removed for now

class WallPainterScreen extends StatefulWidget {
  final Color? initialColor;

  const WallPainterScreen({Key? key, this.initialColor}) : super(key: key);

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

  // Placeholder animation variables - no longer needed
  // double _animationTime = 0.0;

  // Image processing - comment out for now
  // ui.Image? _cameraImage;
  // ui.Image? _paintedImage;
  // List<PaintedArea> _paintedAreas = [];
  // bool _isProcessing = false;
  // int _lastProcessedTime = 0;

  // Для отрисовки реального изображения
  // Uint8List? _cameraImageBytes;
  // img.Image? _imgLibImage;

  // ONNX Model related - comment out for now
  // OrtEnv? _ortEnv;
  // OrtSession? _ortSession;
  // bool _isModelLoaded = false;
  // static const String _modelPath = 'assets/ml/model.onnx';
  // static const String _inputName = 'pixel_values';
  // static const String _outputName = 'logits';
  // static const int _modelInputHeight = 32;
  // static const int _modelInputWidth = 32;
  // static const int _modelOutputHeight = _modelInputHeight ~/ 4;
  // static const int _modelOutputWidth = _modelInputWidth ~/ 4;
  // static const int _numClasses = 150;
  // int _wallClassIndex =
  //     9;

  // final List<MapEntry<String, BlendMode>> _blendModes = [
  //   MapEntry('Основной', BlendMode.overlay),
  //   MapEntry('Яркий', BlendMode.colorDodge),
  //   MapEntry('Глубокий', BlendMode.multiply),
  //   MapEntry('Светлый', BlendMode.screen),
  //   MapEntry('Натур.', BlendMode.softLight),
  // ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ?? Colors.blue;
    _initCamera();
    _loadModel();
    // _startProcessingTimer(); // Removed placeholder timer call
  }

  Future<void> _loadModel() async {
    try {
      const modelPath = 'assets/ml/1.tflite';
      print("Attempting to load model $modelPath");
      final interpreterOptions = InterpreterOptions();
      // Potentially add delegates like GPU if needed
      // Check if running on a mobile platform (excluding web)
      /* // MODIFIED_BLOCK_START: Commenting out delegate logic
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) { 
        if (Platform.isAndroid) {
           // Use GpuDelegateV2 for Android if available
           // interpreterOptions.addDelegate(GpuDelegateV2()); 
           print("Android platform detected, GPU delegate (V2) could be added here.");
        } else if (Platform.isIOS) {
           // Use GpuDelegate for Metal on iOS
           // interpreterOptions.addDelegate(GpuDelegate()); // Commenting this out
           print("iOS platform detected, GPU (Metal) delegate was attempted."); // Keep log for info
        }
      }
      */ // MODIFIED_BLOCK_END

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

      print('Base Model Input Shape: $_inputShape, Type: $_inputType');
      print('Base Model Output Shape: $_outputShape, Type: $_outputType');

      // Create the IsolateInterpreter
      print('Creating IsolateInterpreter...');
      _isolateInterpreter =
          await IsolateInterpreter.create(address: _interpreter!.address);
      print('IsolateInterpreter created.');

      setState(() {
        _isModelLoaded = true;
      });
      print('TFLite model loaded and IsolateInterpreter created successfully.');
    } catch (e) {
      print('Error loading TFLite model or creating IsolateInterpreter: $e');
      // Ensure model is marked as not loaded on error
      setState(() {
        _isModelLoaded = false;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      print("_initCamera: Getting available cameras...");
      _cameras = await availableCameras();
      print("_initCamera: Found ${_cameras?.length ?? 0} cameras.");

      if (_cameras != null && _cameras!.isNotEmpty) {
        print("_initCamera: Initializing CameraController...");
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high, // Changed to high for better detail
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup
              .bgra8888, // BGRA8888 for easier conversion with image package on iOS
        );

        await _cameraController!.initialize();
        print("_initCamera: CameraController initialized.");

        _cameraController!
            .startImageStream(_processCameraImage); // Start image stream
        print("_initCamera: Image stream started.");

        if (mounted) {
          print("_initCamera: Calling setState to refresh UI.");
          setState(() {});
        }
      } else {
        print("_initCamera: No cameras found.");
      }
    } catch (e) {
      print('Camera initialization error in _initCamera: $e');
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
      // Basic YUV to RGB conversion (simplified)
      // This will be slow and might not be perfectly accurate.
      // Consider a native plugin or a more optimized Dart library for YUV conversion if performance is critical.
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
      print("Unsupported image format: ${cameraImage.format.group}");
      return img.Image(width: 1, height: 1); // Return minimal image
    }
  }

  List<List<List<List<double>>>> _prepareImageForModel(
      CameraImage cameraImage) {
    if (_inputShape == null || _inputType == null) {
      print("Error: Model input shape or type is null.");
      return [];
    }
    if (_inputType != TensorType.float32) {
      print("Error: Model input type is not Float32. Got $_inputType");
      return [];
    }

    img.Image image = _convertCameraImage(cameraImage);
    if (image.width <= 1 || image.height <= 1) {
      print("Error: Converted image has invalid dimensions.");
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
    _isProcessing = true;

    try {
      final input = _prepareImageForModel(cameraImage);
      if (input.isEmpty) {
        _isProcessing = false;
        return;
      }

      // Explicitly resize input tensor before running
      _interpreter!.resizeInputTensor(0, _inputShape!);
      _interpreter!
          .allocateTensors(); // MODIFIED_LINE: Allocate tensors after resizing

      var output = <int, Object>{};
      if (_outputType == TensorType.float32) {
        final outputSize = _outputShape!.reduce((a, b) => a * b);
        final flatOutputBuffer = Float32List(outputSize);
        output = {0: flatOutputBuffer};
      } else {
        print("Error: Model output type is not Float32. Got $_outputType");
        _isProcessing = false;
        return;
      }

      await _isolateInterpreter!.run(input, output);

      // --- Temporarily comment out output processing ---
      // /* // MODIFIED_BLOCK_START - REMOVING COMMENT

      // Get the flat output buffer
      final flatOutputBuffer = output[0]! as Float32List;

      final int outputHeight = _outputShape![1]; // 65
      final int outputWidth = _outputShape![2]; // 65
      final int numClasses = _outputShape![3]; // 21
      // TODO: IMPORTANT! Verify and update this index for your specific '1.tflite' model!
      const int wallClassIndex = 1; // Placeholder index - UPDATE THIS!

      Path newMaskPath = Path();
      // Scaling factors to map model output coordinates to screen coordinates
      // Note: This assumes the CameraPreview fills the screen width/height.
      // Adjust if your layout is different.
      final double scaleX = MediaQuery.of(context).size.width / outputWidth;
      final double scaleY = MediaQuery.of(context).size.height / outputHeight;

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
      print("Error processing image: $e");
      print("Stack trace: $stackTrace");
    } finally {
      _isProcessing = false;
    }
  }

  // _processCameraImage would be used with a real segmentation model.
  // void _processCameraImage(CameraImage image) async {
  //   if (!_isModelLoaded || _interpreter == null || _isProcessing) {
  //     return;
  //   }
  //   _isProcessing = true;
  //
  //   // TODO: Add actual image preparation and model inference here
  //   // For example:
  //   // 1. Convert CameraImage to the format expected by the model (e.g., RGB, specific size)
  //   // 2. Prepare input tensor
  //   // 3. Run inference: _interpreter.run(input, output);
  //   // 4. Process output tensor to create a mask Path
  //   // 5. setState(() { _maskPath = generatedPath; });
  //
  //   _isProcessing = false;
  // }

  // Future<img.Image?> _convertYUVToImage(CameraImage image) async { // Commented out
  //   // ... entire method commented ...
  // }

  // void _updatePaintedImage() async { // Commented out
  //    // ... entire method commented ...
  // }

  // Future<void> _drawPaintedArea(Canvas canvas, Size size, PaintedArea area) async { // Commented out
  //   // ... entire method commented ...
  // }

  // Future<Uint8List?> _getWallMaskFromModel(Size displaySize) async { // Commented out
  //   // ... entire method commented ...
  // }

  // Path _createPathFromMask(Uint8List mask, Size size) { // Commented out
  //   // ... entire method commented ...
  // }

  @override
  void dispose() {
    print("WallPainterScreen disposing...");
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
    print("WallPainterScreen building UI...");
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !_isModelLoaded) {
      // Added _isModelLoaded check
      print(
          "WallPainterScreen build: Camera or Model not ready, showing loading indicator.");
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    print("WallPainterScreen build: Camera ready, showing CameraPreview.");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wall Painter'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ARWallPainterScreenSimple(),
                ),
              );
            },
            icon: const Icon(Icons.view_in_ar),
            tooltip: 'AR режим',
          ),
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
    print("_showColorPicker called");
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

  // Future<void> _takePicture() async { // Commented out
  //   // ... entire method commented ...
  // }
}

// class PaintedArea { // Commented out
//   // ... entire class commented ...
// }

// class PaintedImagePainter extends CustomPainter { // Commented out
//   // ... entire class commented ...
// }

class MaskPainter extends CustomPainter {
  final Path maskPath;
  final Color color;

  MaskPainter({required this.maskPath, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6) // Apply selected color with some opacity
      ..style = PaintingStyle.fill;

    // Clip the canvas to the camera preview size if necessary,
    // or ensure maskPath is in the correct coordinate space.
    // For simplicity, assuming maskPath is already in screen coordinates.
    canvas.drawPath(maskPath, paint);
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.maskPath != maskPath || oldDelegate.color != color;
  }
}
