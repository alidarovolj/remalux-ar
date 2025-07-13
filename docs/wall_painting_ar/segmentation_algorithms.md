# Алгоритмы сегментации стен для AR покраски

## Обзор методов сегментации

### 1. Классический подход (Imaggle Method)

Основан на исследовании Stanford University (Yeung, Piersol, Liu, 2012).

#### Алгоритм

```python
def segment_wall(image, tap_point):
    # 1. Edge Detection
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, threshold1=50, threshold2=150)
    
    # 2. Flood Fill from tap point
    mask = np.zeros((height+2, width+2), np.uint8)
    cv2.floodFill(image, mask, tap_point, 0, 
                  loDiff=(10,10,10), upDiff=(10,10,10))
    
    # 3. Mask refinement
    mask = mask[1:-1, 1:-1]  # Remove padding
    kernel = np.ones((5,5), np.uint8)
    mask = cv2.erode(mask, kernel, iterations=1)
    
    return mask
```

#### Преимущества
- Быстрая работа (< 200ms на мобильном устройстве)
- Не требует обучения модели
- Хорошо работает с четкими границами

#### Недостатки
- Проблемы с низкоконтрастными границами
- Фликеринг при трекинге
- Чувствительность к теням

### 2. ML-based подход (DeepLabv3+)

#### Архитектура модели
```
Input (RGB, 513x513) 
    ↓
MobileNetV3 Encoder
    ↓
ASPP (Atrous Spatial Pyramid Pooling)
    ↓
Decoder with skip connections
    ↓
Output (Segmentation mask, 513x513)
```

#### Подготовка модели для мобильного использования

```python
# Конвертация в TFLite
converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
converter.inference_input_type = tf.uint8
converter.inference_output_type = tf.uint8
tflite_model = converter.convert()
```

#### Интеграция в Flutter

```dart
class WallSegmenter {
  late Interpreter _interpreter;
  
  Future<void> loadModel() async {
    final modelPath = 'assets/models/deeplabv3_wall.tflite';
    _interpreter = await Interpreter.fromAsset(modelPath);
  }
  
  Uint8List segmentWall(Uint8List imageBytes) {
    // Preprocessing
    var input = preprocessImage(imageBytes);
    
    // Run inference
    var output = List.filled(513 * 513, 0).reshape([513, 513]);
    _interpreter.run(input, output);
    
    // Postprocessing
    return postprocessMask(output);
  }
}
```

### 3. Гибридный подход (ML + Classical)

Комбинирует преимущества обоих методов:

1. **Грубая сегментация через ML** - получаем общую область стен
2. **Уточнение границ через Canny** - точные края
3. **Flood fill с ограничениями** - заполнение только внутри ML маски

```dart
class HybridSegmenter {
  Future<Uint8List> segmentWall(
    Uint8List frame, 
    Point tapPoint
  ) async {
    // 1. ML segmentation для всех стен
    final mlMask = await _runMLSegmentation(frame);
    
    // 2. Выбор конкретной стены по точке нажатия
    final wallId = mlMask[tapPoint.y][tapPoint.x];
    if (wallId != WALL_CLASS_ID) return null;
    
    // 3. Edge detection
    final edges = await _detectEdges(frame);
    
    // 4. Constrained flood fill
    final refinedMask = await _constrainedFloodFill(
      frame, 
      tapPoint, 
      edges, 
      mlMask
    );
    
    return refinedMask;
  }
}
```

## Оптимизация для реального времени

### 1. Временное переиспользование (Temporal Coherence)

```dart
class TemporalSegmenter {
  Uint8List? _previousMask;
  Matrix4? _previousCameraPose;
  
  Uint8List segmentWithTemporal(
    Uint8List frame,
    Matrix4 cameraPose
  ) {
    if (_previousMask != null) {
      // Проверяем движение камеры
      final movement = calculateMovement(
        _previousCameraPose, 
        cameraPose
      );
      
      if (movement < MOVEMENT_THRESHOLD) {
        // Переиспользуем предыдущую маску
        return _previousMask!;
      }
      
      // Используем предыдущую маску как prior
      final mask = segmentWithPrior(frame, _previousMask!);
      _previousMask = mask;
      _previousCameraPose = cameraPose;
      
      return mask;
    }
    
    // Первый кадр - полная сегментация
    final mask = segmentFull(frame);
    _previousMask = mask;
    _previousCameraPose = cameraPose;
    
    return mask;
  }
}
```

### 2. Многоуровневая обработка

```dart
class MultiScaleSegmenter {
  // Уровень 1: Быстрая грубая сегментация (128x128)
  // Уровень 2: Средняя точность (256x256)  
  // Уровень 3: Полная точность (512x512)
  
  Stream<SegmentationResult> segmentProgressive(
    Uint8List frame
  ) async* {
    // Быстрый результат
    yield await _segmentAtScale(frame, 128);
    
    // Улучшенный результат
    yield await _segmentAtScale(frame, 256);
    
    // Финальный результат
    yield await _segmentAtScale(frame, 512);
  }
}
```

## Обработка сложных случаев

### 1. Множественные стены

Когда в кадре несколько стен:
- Использовать connected components для разделения
- Выбирать стену по точке нажатия пользователя
- Опционально: позволить красить несколько стен

### 2. Частичная окклюзия

Когда мебель частично закрывает стену:
- Сегментировать видимые части
- Использовать inpainting для предсказания скрытых областей
- Или оставлять окклюдированные области непокрашенными

### 3. Сложное освещение

При резких тенях или бликах:
- Предобработка: выравнивание гистограммы
- Адаптивные пороги для edge detection
- ML модели, обученные на augmented данных

## Метрики качества

### 1. Точность сегментации
- IoU (Intersection over Union) > 0.85
- Boundary F1-score > 0.90
- Временная стабильность (IoU между кадрами) > 0.95

### 2. Производительность
- Latency < 50ms (для 720p)
- FPS > 15 для непрерывной сегментации
- Потребление памяти < 100MB

### 3. Пользовательский опыт
- Отсутствие видимого флиекринга
- Плавные границы покраски
- Корректная обработка окклюзий 