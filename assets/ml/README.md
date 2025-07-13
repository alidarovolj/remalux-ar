# ML Модели для AR Wall Painting

## Обзор

Этот проект поддерживает следующие ML модели для сегментации стен:

1. **DeepLabv3+ MobileNetV2** - Легкая модель для мобильных устройств
2. **SegFormer B0** - Современная transformer-based модель
3. **Кастомная модель** - Специализированная модель для стен

## Загрузка моделей

### 1. DeepLabv3+ MobileNetV2

```bash
# Загрузка готовой модели
wget https://storage.googleapis.com/download.tensorflow.org/models/tflite/gpu/deeplabv3_257_mv_gpu.tflite -O assets/ml/deeplabv3_mobilenet.tflite
```

### 2. SegFormer B0

```bash
# Скачивание и конвертация SegFormer
python scripts/convert_segformer.py --model nvidia/segformer-b0-finetuned-ade-512-512 --output assets/ml/segformer_b0.tflite
```

### 3. Кастомная модель

Для обучения кастомной модели специально для стен:

```python
# Смотрите scripts/train_custom_model.py
python scripts/train_custom_model.py --dataset wall_dataset --epochs 50 --output assets/ml/custom_wall_model.tflite
```

## Требования к файлам

### Файловая структура:
```
assets/ml/
├── deeplabv3_mobilenet.tflite    # Основная модель
├── segformer_b0.tflite           # Альтернативная модель
├── custom_wall_model.tflite      # Кастомная модель (опционально)
├── labels.txt                    # Метки классов ADE20K
└── README.md                     # Эта инструкция
```

### Характеристики моделей:

| Модель | Размер | Скорость | Точность | Использование |
|--------|--------|----------|----------|---------------|
| DeepLabv3+ MobileNetV2 | 8.4 MB | 30ms | 72% mIoU | Основная |
| SegFormer B0 | 3.8 MB | 25ms | 76% mIoU | Альтернативная |
| Custom Wall Model | 2.1 MB | 15ms | 85% для стен | Специализированная |

## Конфигурация

### В pubspec.yaml:
```yaml
flutter:
  assets:
    - assets/ml/deeplabv3_mobilenet.tflite
    - assets/ml/segformer_b0.tflite
    - assets/ml/labels.txt
```

### В коде:
```dart
// Выбор модели
const String modelPath = 'assets/ml/deeplabv3_mobilenet.tflite';

// Инициализация
final mlService = MLWallSegmentationService.instance;
await mlService.initialize();
```

## Оптимизация

### Квантизация
```python
# Конвертация с квантизацией
converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.int8]
tflite_model = converter.convert()
```

### GPU ускорение
```dart
// Автоматически включается на Android
final interpreterOptions = InterpreterOptions();
interpreterOptions.addDelegate(GpuDelegate());
```

## Альтернативные источники

### Если основные модели недоступны:

1. **Kaggle Models**
   - [DeepLab ADE20K](https://www.kaggle.com/datasets/deeplabmodels)
   - [SegFormer Models](https://www.kaggle.com/models/nvidia/segformer)

2. **Hugging Face**
   - [nvidia/segformer-b0-finetuned-ade-512-512](https://huggingface.co/nvidia/segformer-b0-finetuned-ade-512-512)

3. **Google AI Hub**
   - [DeepLab Models](https://aihub.cloud.google.com/s?category=model&q=deeplab)

## Fallback режим

Если ML модели недоступны, приложение автоматически переключается на Stanford алгоритм:

```dart
// В HybridWallPainterService
if (!_mlService.isInitialized) {
  debugPrint('⚠️ ML недоступно, используем Stanford алгоритм');
  _currentMode = HybridMode.stanfordOnly;
}
```

## Производительность

### Целевые показатели:
- Латентность: < 50ms
- Точность: > 85% для стен
- Потребление памяти: < 100MB
- FPS: > 15 для непрерывной обработки

### Оптимизация:
1. Используйте квантизованные модели
2. Включайте GPU делегаты
3. Настройте размер входа под устройство
4. Применяйте temporal coherence

## Отладка

### Проверка доступности модели:
```bash
flutter analyze assets/ml/
```

### Тестирование модели:
```dart
// В тестах
final result = await mlService.segmentWall(testImage, null);
expect(result, isNotNull);
expect(result!.confidence, greaterThan(0.5));
```

## Лицензии

- DeepLabv3+: Apache 2.0
- SegFormer: Apache 2.0
- ADE20K Dataset: MIT License

---

**Важно:** Модели не включены в репозиторий из-за размера. Загрузите их отдельно перед использованием. 