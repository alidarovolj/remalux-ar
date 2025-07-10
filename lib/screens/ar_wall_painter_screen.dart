import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARWallPainterScreen extends StatefulWidget {
  const ARWallPainterScreen({super.key});

  @override
  State<ARWallPainterScreen> createState() => _ARWallPainterScreenState();
}

class _ARWallPainterScreenState extends State<ARWallPainterScreen> {
  final GlobalKey _arViewKey = GlobalKey(); // Key to get RenderBox
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  Color _selectedColor = const Color(0xFFF44336); // Красный по умолчанию

  // Camera frame debugging info
  String _frameInfo = "Ожидание кадров...";
  int _frameCount = 0;

  // TFLite properties
  Interpreter? _interpreter;
  ui.Image? _segmentationMask; // The mask from the model
  ui.Image? _paintedMask; // The mask with user's painting
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/segformer.tflite');
      print('TFLite model loaded successfully.');
    } catch (e) {
      print('Failed to load TFLite model: $e');
    }
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Wall Painter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearAll,
          )
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) => _onScreenTap(details.globalPosition),
            child: ARView(
              key: _arViewKey, // Assign key
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
          ),
          // Display the original segmentation mask
          if (_segmentationMask != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.4, // Make it less visible
                child: RawImage(
                  image: _segmentationMask,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Display the user's painting on top
          if (_paintedMask != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.7, // Make paint more vibrant
                child: RawImage(
                  image: _paintedMask,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Debugging info text
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black54,
              child: Text(
                _frameInfo,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.color_lens),
                  onPressed: _showColorPicker,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _clearAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath:
          "assets/ml/triangle.png", // Можно заменить на более подходящую текстуру
      showWorldOrigin: false,
      handleTaps: true,
      enableCameraFrames: true, // Включаем захват кадров камеры
    );
    arObjectManager.onInitialize();

    arSessionManager.onPlaneOrPointTap = onPlaneOrPointTap;
    arSessionManager.onCameraFrame = _onCameraFrame;
  }

  void _onCameraFrame(Uint8List imageBytes, int width, int height) {
    if (_isProcessingFrame || _interpreter == null) {
      return;
    }
    _isProcessingFrame = true;

    runSegmentation(imageBytes, width, height).then((mask) {
      if (mask != null) {
        setState(() {
          _segmentationMask = mask;
        });
      }
      _isProcessingFrame = false;
    });

    setState(() {
      _frameCount++;
      _frameInfo =
          "Кадры: $_frameCount, Размер: ${width}x${height}, Байт: ${imageBytes.length}";
    });
  }

  Future<ui.Image?> runSegmentation(
      Uint8List imageBytes, int width, int height) async {
    if (_interpreter == null) {
      print("Interpreter not initialized.");
      return null;
    }

    // 1. Декодируем JPEG изображение, приходящее с нативного кода
    final image = img.decodeJpg(imageBytes);
    if (image == null) {
      print("Failed to decode image");
      return null;
    }

    // 2. Изменяем размер до входного размера модели (предположим 256x256)
    // Важно: размер должен соответствовать модели!
    const inputSize = 256;
    final resizedImage =
        img.copyResize(image, width: inputSize, height: inputSize);

    // 3. Нормализуем и конвертируем в Float32List
    // Модели обычно ожидают нормализованные данные (0-1)
    final inputBytes = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final inputAsFloat = Float32List(1 * inputSize * inputSize * 3);
    for (var i = 0; i < inputBytes.length; i++) {
      inputAsFloat[i] = inputBytes[i] / 255.0;
    }
    // Форма тензора [1, height, width, channels]
    final inputTensor = inputAsFloat.reshape([1, inputSize, inputSize, 3]);

    // 4. Готовим выходной тензор. Форма зависит от модели,
    // предположим [1, 256, 256, 1] для маски сегментации.
    final outputTensor = List.generate(
        1,
        (_) => List.generate(
            inputSize,
            (_) =>
                List.generate(inputSize, (_) => List.generate(1, (_) => 0.0))));

    // 5. Запускаем модель
    try {
      _interpreter?.run(inputTensor, outputTensor);
    } catch (e) {
      print("Error running model inference: $e");
      return null;
    }

    // 6. Обрабатываем результат и создаем изображение маски
    final outputImage = img.Image(width: inputSize, height: inputSize);
    final outputMask = outputTensor[0];
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        // Предполагаем, что модель возвращает вероятность.
        // Если > 0.5 - это стена. Окрасим ее в выбранный цвет.
        if (outputMask[y][x][0] > 0.5) {
          outputImage.setPixelRgba(x, y, _selectedColor.red,
              _selectedColor.green, _selectedColor.blue, 150); // Полупрозрачный
        }
      }
    }

    // 7. Кодируем маску в PNG и возвращаем как ui.Image
    final pngBytes = img.encodePng(outputImage);
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(pngBytes));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _onScreenTap(Offset tapPosition) async {
    final maskCoordinate = _convertScreenTapToMaskCoordinate(tapPosition);
    if (maskCoordinate == null || _segmentationMask == null) {
      return;
    }

    final int x = maskCoordinate.dx.floor();
    final int y = maskCoordinate.dy.floor();

    // Get the pixel data of the segmentation mask
    final ByteData? maskData = await _segmentationMask!.toByteData();
    if (maskData == null) return;

    // Check if the tapped pixel is part of the wall (not transparent)
    final int pixelOffset = (y * _segmentationMask!.width + x) * 4;
    final int alpha = maskData.getUint8(pixelOffset + 3);

    if (alpha > 50) {
      // Tapped on a wall
      final newPaintedMask = await _floodFill(x, y);
      if (newPaintedMask != null) {
        setState(() {
          _paintedMask = newPaintedMask;
        });
      }
    }
  }

  Future<ui.Image?> _floodFill(int startX, int startY) async {
    if (_segmentationMask == null) return null;

    final img.Image original = img.Image(
        width: _segmentationMask!.width, height: _segmentationMask!.height);
    final ByteData? maskData =
        await _segmentationMask!.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (maskData == null) return null;

    final pixels = maskData.buffer.asUint32List();
    final targetColor = pixels[(startY * _segmentationMask!.width) + startX];

    if (targetColor == 0) return null; // Clicked on transparent part

    final q = Queue<Point<int>>();
    q.add(Point(startX, startY));

    final paintedPixels = <Point<int>>{};

    while (q.isNotEmpty) {
      final p = q.removeFirst();
      if (p.x < 0 || p.x >= original.width || p.y < 0 || p.y >= original.height)
        continue;
      if (paintedPixels.contains(p)) continue;

      final currentColor = pixels[(p.y * original.width) + p.x];

      if (currentColor == targetColor) {
        original.setPixel(
            p.x,
            p.y,
            img.ColorRgba8(_selectedColor.red, _selectedColor.green,
                _selectedColor.blue, _selectedColor.alpha));
        paintedPixels.add(p);
        q.add(Point(p.x + 1, p.y));
        q.add(Point(p.x - 1, p.y));
        q.add(Point(p.x, p.y + 1));
        q.add(Point(p.x, p.y - 1));
      }
    }

    final codec = await ui.instantiateImageCodec(original.getBytes());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Offset? _convertScreenTapToMaskCoordinate(Offset screenTap) {
    final RenderBox? renderBox =
        _arViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _segmentationMask == null) {
      return null;
    }

    // Get the size of the ARView widget
    final previewSize = renderBox.size;
    // Get the local position of the tap within the widget
    final localTapPosition = renderBox.globalToLocal(screenTap);

    // Check if tap is outside the widget's bounds
    if (localTapPosition.dx < 0 ||
        localTapPosition.dx > previewSize.width ||
        localTapPosition.dy < 0 ||
        localTapPosition.dy > previewSize.height) {
      return null;
    }

    // The segmentation mask has a fixed size (e.g., 256x256)
    final maskWidth = _segmentationMask!.width.toDouble();
    final maskHeight = _segmentationMask!.height.toDouble();

    // Convert widget coordinates to mask coordinates
    final maskX = (localTapPosition.dx / previewSize.width) * maskWidth;
    final maskY = (localTapPosition.dy / previewSize.height) * maskHeight;

    return Offset(maskX, maskY);
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hits) async {
    // This logic is now deprecated for painting, but we can keep it for other purposes
    // For now, let's disable it to avoid confusion
    return;
    /*
    final hit = hits.firstWhere(
      (hit) => hit.type == ARHitTestResultType.plane,
      orElse: () => hits.first,
    );

    final newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final bool? didAddAnchor = await arAnchorManager.addAnchor(newAnchor);

    if (didAddAnchor != null && didAddAnchor) {
      anchors.add(newAnchor);

      // Создаем узел с моделью "мазка"
      final newNode = ARNode(
        type: NodeType.webGLB, // Используем webGLB, т.к. localGLTF2 может быть не поддержан
        uri:
            "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb", // Загрузим простую сферу для теста
        scale: vector.Vector3(0.05, 0.05, 0.01), // Делаем мазок плоским
        transformation: newAnchor.transformation,
        data: {
          'color': [
            _selectedColor.red / 255.0,
            _selectedColor.green / 255.0,
            _selectedColor.blue / 255.0,
            _selectedColor.alpha / 255.0,
          ]
        },
      );

      final bool? didAddNode = await arObjectManager.addNode(newNode);
      if (didAddNode != null && didAddNode) {
        nodes.add(newNode);
      } else {
        arSessionManager.onError("Adding node failed");
      }
    } else {
      arSessionManager.onError("Adding anchor failed");
    }
    */
  }

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
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _paintedMask = null;
    });
    // for (var anchor in anchors) {
    //   arAnchorManager.removeAnchor(anchor);
    // }
    // for (var node in nodes) {
    //   arObjectManager.removeNode(node);
    // }
    // anchors.clear();
    // nodes.clear();
  }
}
