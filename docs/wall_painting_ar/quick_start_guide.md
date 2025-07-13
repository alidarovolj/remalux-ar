# Quick Start Guide: AR Wall Painting во Flutter

## 🚀 Быстрый старт за 5 минут ✅ **ПРОЕКТ УЖЕ ГОТОВ**

### Шаг 1: ✅ Проект уже настроен

```bash
# ✅ Проект уже склонирован и настроен
cd remalux_ar

# ✅ Зависимости уже установлены
flutter pub get
```

### Шаг 2: ✅ AR зависимости уже настроены

```yaml
# pubspec.yaml ✅ УЖЕ НАСТРОЕНО
dependencies:
  # AR и 3D
  ar_flutter_plugin: ✅ (из локального packages/)
  
  # ML и обработка изображений
  tflite_flutter: ^0.11.0 ✅
  onnxruntime: ^1.4.1 ✅
  image: ^4.1.7 ✅
  camera: ^0.10.5+9 ✅
  
  # UI
  flutter_colorpicker: ^1.0.3 ✅
  flutter_bloc: ^8.1.3 ✅
  
  # И многое другое...
```

### Шаг 3: Настройка платформ

#### iOS
```ruby
# ios/Podfile
platform :ios, '12.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Приложению нужен доступ к камере для AR</string>
```

#### Android
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 33
    defaultConfig {
        minSdkVersion 24
    }
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera.ar" android:required="true" />
```

### Шаг 4: ✅ Готовые экраны уже реализованы

#### ✅ Доступные AR экраны:

1. **ARWallPainterScreen** - 2D режим
   ```dart
   // lib/screens/ar_wall_painter_screen.dart ✅ УЖЕ ГОТОВ
   // 🎨 2D сегментация с overlay
   // 🤖 Stanford + ML гибридный подход  
   // 📊 Статистика производительности
   // 🎛️ Панели управления режимами
   ```

2. **AR3DWallPainterScreen** - 3D AR режим
   ```dart
   // lib/screens/ar_3d_wall_painter_screen.dart ✅ УЖЕ ГОТОВ  
   // 🎯 Настоящая детекция AR плоскостей
   // 🏗️ 3D размещение объектов в пространстве
   // 👆 Тап по плоскости для покраски
   // 🎨 Цветовая палитра
   ```

3. **ARDemoScreen** - главное меню
   ```dart
   // lib/screens/ar_demo_screen.dart ✅ УЖЕ ГОТОВ
   // 📱 Выбор между 2D и 3D режимами
   // 🎯 Кнопка "3D AR Детекция Плоскостей"
   // 📋 Инструкции для пользователя
   ```

class _SimpleWallPainterState extends State<SimpleWallPainter> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  
  Color selectedColor = Colors.blue;
  List<ARNode> paintedWalls = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Wall Painter'),
        actions: [
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: _showColorPicker,
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.verticalAndHorizontal,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Нажмите на стену чтобы покрасить её',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
    );
    
    this.arObjectManager!.onInitialize();
    this.arSessionManager!.onTap = onTapHandler;
  }
  
  Future<void> onTapHandler(List<ARHitTestResult> hits) async {
    if (hits.isEmpty) return;
    
    var hit = hits.firstWhere(
      (h) => h.type == ARHitTestResultType.plane,
      orElse: () => hits.first,
    );
    
    // Создаем цветную плоскость
    var newAnchor = await arAnchorManager!.addAnchor(
      ARPlaneAnchor(transformation: hit.pose),
    );
    
    if (newAnchor != null) {
      var plane = ARNode(
        type: NodeType.plane,
        shape: ARPlaneShape(width: 2.0, height: 2.0),
        position: hit.pose.translation,
        rotation: hit.pose.rotation,
        materials: [
          ARMaterial(
            color: selectedColor.withOpacity(0.7),
          ),
        ],
      );
      
      await arObjectManager!.addNode(plane, planeAnchor: newAnchor);
      paintedWalls.add(plane);
    }
  }
  
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              setState(() {
                selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }
}
```

### Шаг 5: Запуск приложения

```bash
# iOS
flutter run -d ios

# Android  
flutter run -d android
```

## 📱 Простейший вариант без AR (только сегментация)

Если нужно быстро протестировать сегментацию без AR:

```dart
// lib/screens/camera_wall_painter.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class CameraWallPainter extends StatefulWidget {
  @override
  _CameraWallPainterState createState() => _CameraWallPainterState();
}

class _CameraWallPainterState extends State<CameraWallPainter> {
  CameraController? controller;
  bool isProcessing = false;
  img.Image? processedImage;
  Color selectedColor = Colors.red;
  
  @override
  void initState() {
    super.initState();
    initCamera();
  }
  
  Future<void> initCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    await controller!.initialize();
    setState(() {});
  }
  
  Future<void> captureAndProcess() async {
    if (isProcessing || controller == null) return;
    
    setState(() => isProcessing = true);
    
    try {
      final image = await controller!.takePicture();
      final bytes = await image.readAsBytes();
      
      // Простая сегментация по цвету
      final originalImage = img.decodeImage(bytes)!;
      processedImage = simpleWallSegmentation(originalImage);
      
      setState(() {});
    } finally {
      setState(() => isProcessing = false);
    }
  }
  
  img.Image simpleWallSegmentation(img.Image image) {
    // Очень простой алгоритм для демонстрации
    final result = img.Image(image.width, image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Простая проверка: является ли пиксель "светлым" (стена)
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        final brightness = (r + g + b) / 3;
        
        if (brightness > 180) {
          // Закрашиваем выбранным цветом
          result.setPixel(
            x, 
            y, 
            img.getColor(
              selectedColor.red,
              selectedColor.green,
              selectedColor.blue,
            ),
          );
        } else {
          // Оставляем оригинальный цвет
          result.setPixel(x, y, pixel);
        }
      }
    }
    
    return result;
  }
  
  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Camera Wall Painter')),
      body: processedImage == null
          ? CameraPreview(controller!)
          : Image.memory(img.encodePng(processedImage!)),
      floatingActionButton: FloatingActionButton(
        onPressed: captureAndProcess,
        child: Icon(isProcessing ? Icons.hourglass_empty : Icons.camera),
      ),
    );
  }
}
```

## 🧪 Тестовые модели

### 1. Скачать готовую модель DeepLabv3

```bash
# Создаем папку для моделей
mkdir -p assets/models

# Скачиваем модель (пример)
wget -O assets/models/deeplabv3.tflite \
  https://storage.googleapis.com/download.tensorflow.org/models/tflite/gpu/deeplabv3_257_mv_gpu.tflite
```

### 2. Использование модели

```dart
import 'package:tflite_flutter/tflite_flutter.dart';

class MLWallSegmenter {
  Interpreter? _interpreter;
  
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/deeplabv3.tflite'
    );
  }
  
  Future<Uint8List> segment(Uint8List imageBytes) async {
    // Препроцессинг
    final input = preprocessImage(imageBytes);
    
    // Инференс
    final output = List.filled(257 * 257, 0);
    _interpreter!.run(input, output);
    
    // Постпроцессинг
    return extractWallMask(output);
  }
}
```

## 🎯 Чек-лист для MVP ✅ **ВСЕ ВЫПОЛНЕНО**

- ✅ Базовая AR сцена работает (ar_flutter_plugin)
- ✅ Детекция вертикальных плоскостей (PlaneDetectionConfig)
- ✅ Обработка нажатий на плоскости (ARHitTestResult)
- ✅ UI выбора цвета (ColorPicker)
- ✅ 2D визуализация цвета (overlay режим)
- ✅ **БОНУС:** 3D размещение объектов в AR пространстве
- ✅ **БОНУС:** ML сегментация с гибридными алгоритмами
- ✅ **БОНУС:** BLoC архитектура
- ✅ **БОНУС:** Статистика производительности
- [ ] Сохранение скриншота результата (планируется)

## 🔧 Отладка частых проблем

### "AR не инициализируется"
```dart
// Проверьте разрешения
if (!await Permission.camera.request().isGranted) {
  // Показать диалог с объяснением
}

// Проверьте поддержку AR
if (!await ARCore.checkArCoreAvailability()) {
  // Устройство не поддерживает AR
}
```

### "Плоскости не детектируются"
```dart
// Увеличьте время ожидания
Timer(Duration(seconds: 5), () {
  if (detectedPlanes.isEmpty) {
    showSnackBar('Подвигайте камерой для обнаружения стен');
  }
});
```

### "Низкая производительность"
```dart
// Уменьшите разрешение обработки
const PROCESSING_SIZE = 256; // вместо 512

// Throttle обработку
Timer.periodic(Duration(milliseconds: 100), (timer) {
  if (!isProcessing) {
    processFrame();
  }
});
```

## 📚 Полезные ссылки

1. [AR Flutter Plugin Docs](https://pub.dev/packages/ar_flutter_plugin)
2. [TFLite Flutter Examples](https://github.com/tensorflow/flutter-tflite)
3. [Flutter Camera Plugin](https://pub.dev/packages/camera)
4. [Image Processing in Dart](https://pub.dev/packages/image)

## 🚢 Следующие шаги

1. **Улучшение сегментации**: Интегрировать ML модель
2. **Стабилизация**: Добавить temporal coherence
3. **UX**: Улучшить процесс выбора цвета
4. **Производительность**: Оптимизировать для 60 FPS
5. **Функции**: Добавить сохранение и шаринг

---

💡 **Совет**: Начните с простого примера выше и постепенно добавляйте функциональность. Это позволит быстро получить работающий прототип и итеративно его улучшать. 