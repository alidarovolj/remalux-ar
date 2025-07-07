import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:camera/camera.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

enum PaintStrokeType {
  main, // Основной мазок
  connecting, // Соединительный мазок
  drip, // Потек
}

class ARWallPainterScreenSimple extends StatefulWidget {
  const ARWallPainterScreenSimple({super.key});

  @override
  State<ARWallPainterScreenSimple> createState() =>
      _ARWallPainterScreenSimpleState();
}

class _ARWallPainterScreenSimpleState extends State<ARWallPainterScreenSimple> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<PaintStroke> _paintStrokes = [];
  Color _selectedColor = const Color(0xFF2196F3);
  double _brushSize = 30.0;

  // Для отслеживания последовательных тапов
  Offset? _lastPaintPosition;
  DateTime? _lastPaintTime;

  // AI Сегментация стен
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  bool _isModelLoaded = false;
  Path? _wallMaskPath;
  bool _isProcessing = false;
  List<int>? _inputShape;
  List<int>? _outputShape;
  TensorType? _inputType;
  TensorType? _outputType;

  // Предустановленные цвета
  final List<Color> _presetColors = [
    const Color(0xFF2196F3), // Синий
    const Color(0xFF4CAF50), // Зеленый
    const Color(0xFFF44336), // Красный
    const Color(0xFFFF9800), // Оранжевый
    const Color(0xFF9C27B0), // Фиолетовый
    const Color(0xFFFFEB3B), // Желтый
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadAIModel();
  }

  Future<void> _loadAIModel() async {
    try {
      const modelPath = 'assets/ml/1.tflite';
      print("🤖 Загружаем AI модель сегментации стен: $modelPath");

      final interpreterOptions = InterpreterOptions();
      _interpreter =
          await Interpreter.fromAsset(modelPath, options: interpreterOptions);
      _interpreter!.allocateTensors();

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      _inputShape = inputTensor.shape;
      _inputType = inputTensor.type;
      _outputShape = outputTensor.shape;
      _outputType = outputTensor.type;

      print('🧠 AI Model Input: $_inputShape, Type: $_inputType');
      print('🧠 AI Model Output: $_outputShape, Type: $_outputType');

      _isolateInterpreter =
          await IsolateInterpreter.create(address: _interpreter!.address);

      setState(() {
        _isModelLoaded = true;
      });
      print('✅ AI модель загружена успешно');
    } catch (e) {
      print('❌ Ошибка загрузки AI модели: $e');
      setState(() {
        _isModelLoaded = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();

        // Запускаем поток обработки изображений для AI сегментации
        _cameraController!.startImageStream(_processCameraImageForAI);

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка инициализации камеры: $e');
    }
  }

  img.Image _convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return img.Image.fromBytes(
        width: cameraImage.planes[0].width!,
        height: cameraImage.planes[0].height!,
        bytes: cameraImage.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    } else {
      // Упрощенная конвертация YUV420 в RGB
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
    }
  }

  List<List<List<List<double>>>> _prepareImageForAI(CameraImage cameraImage) {
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

  Future<void> _processCameraImageForAI(CameraImage cameraImage) async {
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
      final input = _prepareImageForAI(cameraImage);
      if (input.isEmpty) {
        _isProcessing = false;
        return;
      }

      _interpreter!.resizeInputTensor(0, _inputShape!);
      _interpreter!.allocateTensors();

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

      // Обрабатываем результат AI для создания маски стен
      final flatOutputBuffer = output[0]! as Float32List;
      final int outputHeight = _outputShape![1];
      final int outputWidth = _outputShape![2];
      final int numClasses = _outputShape![3];
      const int wallClassIndex = 1; // Индекс класса "стена" в модели

      Path newWallMask = Path();
      final double scaleX = MediaQuery.of(context).size.width / outputWidth;
      final double scaleY = MediaQuery.of(context).size.height / outputHeight;

      for (int y = 0; y < outputHeight; y++) {
        for (int x = 0; x < outputWidth; x++) {
          double maxScore = -double.infinity;
          int predictedClass = 0;
          int pixelStartIndex = y * outputWidth * numClasses + x * numClasses;

          for (int c = 0; c < numClasses; c++) {
            final score = flatOutputBuffer[pixelStartIndex + c];
            if (score > maxScore) {
              maxScore = score;
              predictedClass = c;
            }
          }

          // Если AI определила что это стена - добавляем в маску
          if (predictedClass == wallClassIndex) {
            newWallMask
                .addRect(Rect.fromLTWH(x * scaleX, y * scaleY, scaleX, scaleY));
          }
        }
      }

      if (mounted) {
        setState(() {
          _wallMaskPath = newWallMask;
        });
      }
    } catch (e) {
      print("❌ Ошибка AI обработки: $e");
    } finally {
      _isProcessing = false;
    }
  }

  bool _isPointOnWall(Offset point) {
    if (_wallMaskPath == null) return false;
    return _wallMaskPath!.contains(point);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    _isolateInterpreter?.close();
    super.dispose();
  }

  void _addPaintStroke(Offset position) {
    // 🧠 Проверяем с помощью AI - попал ли тап на стену
    if (!_isPointOnWall(position)) {
      // Показываем сообщение что нужно тапать по стене
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Нажмите на стену для покраски! 🏠'),
            ],
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Colors.orange.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // Не рисуем если не попали на стену
    }

    final now = DateTime.now();

    // Проверяем, можно ли соединить с предыдущим мазком
    bool shouldConnect = false;
    if (_lastPaintPosition != null && _lastPaintTime != null) {
      final distance = (position - _lastPaintPosition!).distance;
      final timeDiff = now.difference(_lastPaintTime!).inMilliseconds;

      // Соединяем если расстояние небольшое и прошло мало времени
      shouldConnect = distance < 100 && timeDiff < 500;
    }

    setState(() {
      if (shouldConnect && _paintStrokes.isNotEmpty) {
        // Добавляем соединительные мазки между точками
        _addConnectingStrokes(_lastPaintPosition!, position);
      }

      // Добавляем основной мазок
      _paintStrokes.add(PaintStroke(
        center: position,
        color: _selectedColor,
        size: _brushSize,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: PaintStrokeType.main,
      ));

      // Добавляем эффект растекания вокруг основного мазка
      _addDripEffects(position);
    });

    _lastPaintPosition = position;
    _lastPaintTime = now;

    // Тактильная обратная связь - успешное нанесение краски
    HapticFeedback.lightImpact();

    // Уведомление об успешной покраске
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.brush, color: Colors.white),
            SizedBox(width: 8),
            Text('Стена покрашена! 🎨'),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        backgroundColor: _selectedColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addConnectingStrokes(Offset start, Offset end) {
    final distance = (end - start).distance;
    final steps = (distance / 20).ceil(); // Мазок каждые 20 пикселей

    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final position = Offset.lerp(start, end, t)!;

      // Проверяем что соединительный мазок тоже на стене
      if (_isPointOnWall(position)) {
        _paintStrokes.add(PaintStroke(
          center: position,
          color: _selectedColor,
          size: _brushSize * 0.8, // Соединительные мазки немного меньше
          id: '${DateTime.now().millisecondsSinceEpoch}_connect_$i',
          type: PaintStrokeType.connecting,
        ));
      }
    }
  }

  void _addDripEffects(Offset center) {
    // Добавляем небольшие потеки вокруг основного мазка
    for (int i = 0; i < 3; i++) {
      final angle = (i * 120) * (3.14159 / 180); // 120 градусов между потеками
      final distance = _brushSize * 0.6;
      final dripPosition = Offset(
        center.dx + distance * cos(angle),
        center.dy + distance * sin(angle),
      );

      // Проверяем что потек тоже на стене
      if (_isPointOnWall(dripPosition)) {
        _paintStrokes.add(PaintStroke(
          center: dripPosition,
          color: _selectedColor,
          size: _brushSize * 0.4,
          id: '${DateTime.now().millisecondsSinceEpoch}_drip_$i',
          type: PaintStrokeType.drip,
        ));
      }
    }
  }

  void _clearAllPaint() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Очистить всё?'),
          content: const Text('Удалить всю нанесенную краску?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _paintStrokes.clear();
                  _lastPaintPosition = null;
                  _lastPaintTime = null;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Вся краска удалена! ✨'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorPicker() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Предустановленные цвета
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presetColors.length + 1,
              itemBuilder: (context, index) {
                if (index == _presetColors.length) {
                  // Кнопка выбора произвольного цвета
                  return GestureDetector(
                    onTap: _showColorPickerDialog,
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.blue, Colors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.palette,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                }

                final color = _presetColors[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.brush,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Индикатор выбранного цвета
          Text(
            'Выбранный цвет',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedColor = tempColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Выбрать'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrushControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.brush, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Размер кисти: ${_brushSize.round()}px',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _selectedColor,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: _selectedColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _brushSize,
              min: 10.0,
              max: 80.0,
              divisions: 14,
              onChanged: (value) {
                setState(() {
                  _brushSize = value;
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Камера или заглушка
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Инициализация камеры...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Overlay для AI маски стен (отладка)
          if (_wallMaskPath != null && kDebugMode)
            Positioned.fill(
              child: CustomPaint(
                painter: WallMaskPainter(_wallMaskPath!),
              ),
            ),

          // Overlay для захвата тапов и жестов
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                _addPaintStroke(details.localPosition);
              },
              onPanStart: (details) {
                _addPaintStroke(details.localPosition);
              },
              onPanUpdate: (details) {
                _addPaintStroke(details.localPosition);
              },
              onPanEnd: (details) {
                // Сбрасываем отслеживание для создания разрыва между мазками
                _lastPaintPosition = null;
                _lastPaintTime = null;
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Краски на стене
          ..._paintStrokes.map((stroke) => Positioned(
                left: stroke.center.dx - stroke.size / 2,
                top: stroke.center.dy - stroke.size / 2,
                child: PaintStrokeWidget(stroke: stroke),
              )),

          // Верхняя панель
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'AR Покраска стен',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: _clearAllPaint,
                      icon: const Icon(Icons.clear_all, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Нижняя панель с элементами управления
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBrushControls(),
                    const SizedBox(height: 16),
                    _buildColorPicker(),
                    const SizedBox(height: 16),
                    // Инструкция
                    Column(
                      children: [
                        Text(
                          'Нажмите или проведите пальцем по стене для покраски',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Статус AI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isModelLoaded ? Icons.smart_toy : Icons.error,
                              color: _isModelLoaded ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isModelLoaded
                                  ? 'AI активен 🧠'
                                  : 'AI загружается...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaintStroke {
  final Offset center;
  final Color color;
  final double size;
  final String id;
  final PaintStrokeType type;

  PaintStroke({
    required this.center,
    required this.color,
    required this.size,
    required this.id,
    required this.type,
  });
}

class PaintStrokeWidget extends StatefulWidget {
  final PaintStroke stroke;

  const PaintStrokeWidget({super.key, required this.stroke});

  @override
  State<PaintStrokeWidget> createState() => _PaintStrokeWidgetState();
}

class _PaintStrokeWidgetState extends State<PaintStrokeWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(
          milliseconds: widget.stroke.type == PaintStrokeType.main ? 600 : 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.stroke.type == PaintStrokeType.main
          ? Curves.elasticOut
          : Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: _getMaxOpacity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  double _getMaxOpacity() {
    switch (widget.stroke.type) {
      case PaintStrokeType.main:
        return 0.9;
      case PaintStrokeType.connecting:
        return 0.6;
      case PaintStrokeType.drip:
        return 0.4;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildStrokeByType(),
        );
      },
    );
  }

  Widget _buildStrokeByType() {
    switch (widget.stroke.type) {
      case PaintStrokeType.main:
        return _buildMainStroke();
      case PaintStrokeType.connecting:
        return _buildConnectingStroke();
      case PaintStrokeType.drip:
        return _buildDripStroke();
    }
  }

  Widget _buildMainStroke() {
    return Container(
      width: widget.stroke.size,
      height: widget.stroke.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.stroke.color.withOpacity(_opacityAnimation.value),
            widget.stroke.color.withOpacity(_opacityAnimation.value * 0.8),
            widget.stroke.color.withOpacity(_opacityAnimation.value * 0.3),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.stroke.color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: widget.stroke.color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingStroke() {
    return Container(
      width: widget.stroke.size,
      height: widget.stroke.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.stroke.color.withOpacity(_opacityAnimation.value),
        boxShadow: [
          BoxShadow(
            color: widget.stroke.color.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDripStroke() {
    return Container(
      width: widget.stroke.size,
      height: widget.stroke.size * 1.5, // Потеки вытянуты по вертикали
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.stroke.size / 2),
          topRight: Radius.circular(widget.stroke.size / 2),
          bottomLeft: Radius.circular(widget.stroke.size / 4),
          bottomRight: Radius.circular(widget.stroke.size / 4),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.stroke.color.withOpacity(_opacityAnimation.value * 0.8),
            widget.stroke.color.withOpacity(_opacityAnimation.value * 0.4),
            widget.stroke.color.withOpacity(_opacityAnimation.value * 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.stroke.color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// Painter для отладочной визуализации AI маски стен
class WallMaskPainter extends CustomPainter {
  final Path wallMask;

  WallMaskPainter(this.wallMask);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(wallMask, paint);

    // Рисуем границы для лучшей видимости
    final borderPaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(wallMask, borderPaint);
  }

  @override
  bool shouldRepaint(WallMaskPainter oldDelegate) {
    return oldDelegate.wallMask != wallMask;
  }
}
