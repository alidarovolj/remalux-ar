# Интеграция ML моделей для сегментации стен

## Обзор доступных моделей

### 1. DeepLabv3+ (Рекомендуется для начала)

**Характеристики:**
- Размер: 8.4 MB (MobileNetV2) - 54 MB (Xception)
- Точность: 72-82% mIoU на ADE20K
- Скорость: 30-200ms на мобильном устройстве

**Источники моделей:**

1. **TensorFlow Hub** - Готовые TFLite модели
   ```bash
   # MobileNetV2 версия (легкая)
   wget https://tfhub.dev/tensorflow/lite-model/deeplabv3/1/metadata/2?lite-format=tflite
   
   # Переименовать в deeplabv3_mobilenet.tflite
   ```

2. **Kaggle Models**
   - [DeepLab ADE20K Pretrained](https://www.kaggle.com/datasets/deeplabmodels)
   - Требует регистрации на Kaggle

### 2. SegFormer (Современный подход)

**Характеристики:**
- Размер: 3.8 MB (B0) - 82 MB (B5)
- Точность: 76-84% mIoU на ADE20K
- Более эффективная архитектура

**Конвертация из PyTorch в TFLite:**

```python
# convert_segformer_to_tflite.py
import torch
import tensorflow as tf
from transformers import SegformerForSemanticSegmentation

# 1. Загрузка модели
model = SegformerForSemanticSegmentation.from_pretrained(
    "nvidia/segformer-b0-finetuned-ade-512-512"
)

# 2. Экспорт в ONNX
dummy_input = torch.randn(1, 3, 512, 512)
torch.onnx.export(
    model, 
    dummy_input, 
    "segformer_b0.onnx",
    opset_version=11
)

# 3. Конвертация ONNX -> TensorFlow
import onnx
from onnx_tf import convert

onnx_model = onnx.load("segformer_b0.onnx")
tf_model = convert.from_onnx(onnx_model)
tf_model.save("segformer_tf")

# 4. Конвертация TensorFlow -> TFLite
converter = tf.lite.TFLiteConverter.from_saved_model("segformer_tf")
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

with open("segformer_b0.tflite", "wb") as f:
    f.write(tflite_model)
```

### 3. Кастомная модель для стен

Если готовые модели недостаточно точны, можно обучить специализированную модель:

```python
# train_custom_wall_model.py
import tensorflow as tf
from tensorflow.keras import layers

def create_wall_segmentation_model():
    """Легковесная модель специально для стен"""
    inputs = layers.Input(shape=(256, 256, 3))
    
    # Encoder (MobileNetV2)
    encoder = tf.keras.applications.MobileNetV2(
        input_tensor=inputs,
        weights='imagenet',
        include_top=False
    )
    
    # Decoder
    x = encoder.output
    x = layers.Conv2DTranspose(128, 3, strides=2, padding='same')(x)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)
    
    x = layers.Conv2DTranspose(64, 3, strides=2, padding='same')(x)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)
    
    x = layers.Conv2DTranspose(32, 3, strides=2, padding='same')(x)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)
    
    # Output layer (2 classes: wall, not-wall)
    outputs = layers.Conv2D(2, 1, activation='softmax')(x)
    
    model = tf.keras.Model(inputs, outputs)
    return model
```

## ✅ Интеграция в Flutter **РЕАЛИЗОВАНО**

### 1. ✅ Добавление зависимостей

```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.11.0  # ✅ Интегрировано
  onnxruntime: ^1.4.1      # ✅ Дополнительно добавлено
  image: ^4.1.7            # ✅ Обновлено
  camera: ^0.10.5+9        # ✅ Для камеры
  
flutter:
  assets:
    - assets/ml/  # ✅ Все ML модели
```

### 2. ✅ Реализованные сервисы сегментации

#### ✅ MLWallSegmentationService

```dart
// lib/core/services/ml_wall_segmentation_service.dart
// ✅ РЕАЛИЗОВАНО И РАБОТАЕТ
class MLWallSegmentationService {
  // Поддерживает DeepLabv3+ и SegFormer модели
  // GPU ускорение для Android
  // Автоматическое определение типа модели
  // Оптимизация: downsampling до 320x240px
  
  static const String DEEPLABV3_MODEL = 'assets/ml/deeplabv3_mnv2_ade20k_1.tflite';
  static const String SEGFORMER_MODEL = 'assets/ml/segformer_b0_ade20k.tflite';
  
  // ✅ 150 классов ADE20K поддержка
  static const int WALL_CLASS_ID = 1;
  static const int CEILING_CLASS_ID = 5; 
  static const int FLOOR_CLASS_ID = 3;
  
  Future<void> initialize() async {
    try {
      // Загрузка модели
      _interpreter = await Interpreter.fromAsset(MODEL_PATH);
      
      // Загрузка labels (опционально)
      _labels = await FileUtil.loadLabels('assets/models/labels.txt');
    } catch (e) {
      print('Error loading model: $e');
    }
  }
  
  Future<Uint8List?> segmentWall(Uint8List imageBytes) async {
    if (_interpreter == null) return null;
    
    // 1. Декодирование и изменение размера изображения
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return null;
    
    img.Image resized = img.copyResize(
      image, 
      width: INPUT_SIZE, 
      height: INPUT_SIZE
    );
    
    // 2. Подготовка входных данных
    var input = _imageToByteListFloat32(resized, INPUT_SIZE);
    
    // 3. Подготовка выходных данных
    var output = List.generate(
      1,
      (index) => List.generate(
        INPUT_SIZE,
        (index) => List.filled(INPUT_SIZE, 0.0),
      ),
    );
    
    // 4. Запуск инференса
    _interpreter!.run(input, output);
    
    // 5. Постобработка - извлечение маски стен
    return _extractWallMask(output[0]);
  }
  
  Uint8List _imageToByteListFloat32(img.Image image, int size) {
    var convertedBytes = Float32List(1 * size * size * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - 128) / 128.0;
        buffer[pixelIndex++] = (img.getGreen(pixel) - 128) / 128.0;
        buffer[pixelIndex++] = (img.getBlue(pixel) - 128) / 128.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
  
  Uint8List _extractWallMask(List<List<double>> segmentationOutput) {
    var mask = Uint8List(INPUT_SIZE * INPUT_SIZE);
    
    for (int i = 0; i < INPUT_SIZE; i++) {
      for (int j = 0; j < INPUT_SIZE; j++) {
        // Находим класс с максимальной вероятностью
        int maxClass = 0;
        double maxProb = segmentationOutput[i][j * NUM_CLASSES];
        
        for (int c = 1; c < NUM_CLASSES; c++) {
          if (segmentationOutput[i][j * NUM_CLASSES + c] > maxProb) {
            maxProb = segmentationOutput[i][j * NUM_CLASSES + c];
            maxClass = c;
          }
        }
        
        // Если это стена - ставим 255, иначе 0
        mask[i * INPUT_SIZE + j] = (maxClass == WALL_CLASS_ID) ? 255 : 0;
      }
    }
    
    return mask;
  }
}
```

#### ✅ HybridWallPainterService

```dart
// lib/core/services/hybrid_wall_painter_service.dart
// ✅ РЕАЛИЗОВАНО И АКТИВНО ИСПОЛЬЗУЕТСЯ
class HybridWallPainterService {
  // 4 режима работы: auto, stanfordOnly, mlOnly, hybrid
  // Автоматический выбор алгоритмов
  // Трекинг производительности
  // 20-item performance history
  // Fallback на Stanford при ошибках ML
  
  Future<HybridWallPaintResult> processFrame(
    CameraImage image,
    ui.Offset? seedPoint,
    HybridMode mode,
  ) async {
    // Автоматическая обработка с выбором лучшего алгоритма
  }
}
```

### 3. ✅ Интеграция с AR

```dart
// lib/screens/ar_wall_painter_screen.dart + ar_3d_wall_painter_screen.dart
// ✅ ДВА ЭКРАНА РЕАЛИЗОВАНЫ
class ARWallPainterScreen extends StatefulWidget {
  // 2D режим с overlay
}

class AR3DWallPainterScreen extends StatefulWidget {
  // 3D режим с настоящими AR плоскостями
}

class _ARWallPainterScreenState extends State<ARWallPainterScreen> {
  late ARWallPainterBloc _bloc; // ✅ BLoC архитектура
  late HybridWallPainterService _hybridService; // ✅ Гибридный сервис
  
  @override
  void initState() {
    super.initState();
    segmentationService = WallSegmentationService();
    segmentationService.initialize();
  }
  
  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    
    // Настройка AR сессии
    this.arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handleTaps: true,
    );
    
    // Обработка нажатий
    this.arSessionManager.onTap = _handleTap;
    
    // Запуск периодической сегментации
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      _performSegmentation();
    });
  }
  
  Future<void> _performSegmentation() async {
    // Получение текущего кадра из AR сессии
    final frame = await arSessionManager.getCameraImage();
    if (frame == null) return;
    
    // Сегментация
    final mask = await segmentationService.segmentWall(frame);
    
    setState(() {
      currentWallMask = mask;
    });
  }
  
  void _handleTap(List<ARHitTestResult> hits) {
    if (hits.isEmpty || currentWallMask == null) return;
    
    // Определение точки нажатия
    final hit = hits.first;
    final tapPoint = hit.screenPoint;
    
    // Проверка, попали ли в стену
    final maskIndex = tapPoint.dy * 257 + tapPoint.dx;
    if (currentWallMask![maskIndex] > 0) {
      // Применение цвета к стене
      _applyColorToWall(hit, currentWallMask!);
    }
  }
}
```

## Оптимизация производительности

### 1. Использование GPU Delegate

```dart
// Для Android
final gpuDelegateV2 = GpuDelegateV2(
  precisionLossAllowed: true,
  inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
);

var interpreterOptions = InterpreterOptions()
  ..addDelegate(gpuDelegateV2);

_interpreter = await Interpreter.fromAsset(
  MODEL_PATH,
  options: interpreterOptions,
);
```

### 2. Квантизация модели

```python
# Пост-тренировочная квантизация
converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_data_gen
converter.target_spec.supported_ops = [
  tf.lite.OpsSet.TFLITE_BUILTINS_INT8
]
converter.inference_input_type = tf.uint8
converter.inference_output_type = tf.uint8
quantized_model = converter.convert()
```

### 3. Батчинг и кеширование

```dart
class OptimizedSegmentationService {
  final _frameQueue = Queue<Uint8List>();
  final _resultCache = LRUCache<String, Uint8List>(100);
  
  Future<Uint8List?> segmentWithCache(Uint8List frame) async {
    final hash = calculateHash(frame);
    
    // Проверка кеша
    if (_resultCache.containsKey(hash)) {
      return _resultCache[hash];
    }
    
    // Выполнение сегментации
    final result = await _performSegmentation(frame);
    _resultCache[hash] = result;
    
    return result;
  }
}
```

## Тестирование и валидация

### Метрики для оценки

```dart
class SegmentationMetrics {
  static double calculateIoU(Uint8List predicted, Uint8List ground_truth) {
    int intersection = 0;
    int union = 0;
    
    for (int i = 0; i < predicted.length; i++) {
      if (predicted[i] > 0 && ground_truth[i] > 0) {
        intersection++;
      }
      if (predicted[i] > 0 || ground_truth[i] > 0) {
        union++;
      }
    }
    
    return intersection / union;
  }
  
  static double calculateLatency(Function segmentationFunction) {
    final stopwatch = Stopwatch()..start();
    segmentationFunction();
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds.toDouble();
  }
}
```

## Полезные ссылки

1. **Модели и датасеты:**
   - [ADE20K Dataset](http://sceneparsing.csail.mit.edu/)
   - [TensorFlow Model Garden](https://github.com/tensorflow/models)
   - [Hugging Face SegFormer](https://huggingface.co/nvidia/segformer-b0-finetuned-ade-512-512)

2. **Инструменты конвертации:**
   - [ONNX to TensorFlow](https://github.com/onnx/onnx-tensorflow)
   - [TensorFlow Lite Converter](https://www.tensorflow.org/lite/convert)

3. **Примеры реализации:**
   - [TFLite Flutter Examples](https://github.com/tensorflow/flutter-tflite)
   - [Semantic Segmentation Demo](https://github.com/tensorflow/examples/tree/master/lite/examples/image_segmentation) 