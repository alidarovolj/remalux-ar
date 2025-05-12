# Подготовка модели Segformer для AR-перекрашивания стен

## Конвертация модели из ONNX в TensorFlow Lite

Для работы AR-перекрашивания стен необходимо сконвертировать модель Segformer из формата ONNX в TensorFlow Lite (TFLite). Следуйте этим шагам:

1. **Установите необходимые инструменты**:
   ```bash
   pip install onnx
   pip install onnx-tf
   pip install tensorflow
   ```

2. **Сконвертируйте ONNX в TensorFlow**:
   ```python
   import onnx
   from onnx_tf.backend import prepare
   
   # Загрузка модели ONNX
   onnx_model = onnx.load("path/to/segformer.onnx")
   
   # Конвертация в TensorFlow
   tf_rep = prepare(onnx_model)
   
   # Сохранение модели TensorFlow
   tf_rep.export_graph("path/to/tf_model")
   ```

3. **Конвертируйте TensorFlow в TFLite**:
   ```python
   import tensorflow as tf
   
   # Загрузите сохраненную модель
   converter = tf.lite.TFLiteConverter.from_saved_model("path/to/tf_model")
   
   # Оптимизируйте модель (опционально)
   converter.optimizations = [tf.lite.Optimize.DEFAULT]
   
   # Сконвертируйте модель в TFLite
   tflite_model = converter.convert()
   
   # Сохраните модель TFLite
   with open("assets/ml/segformer.tflite", "wb") as f:
       f.write(tflite_model)
   ```

## Использование модели TFLite в приложении

После конвертации модели поместите файл `segformer.tflite` в директорию `assets/ml/`. Затем обновите файл `pubspec.yaml`, чтобы включить новую модель в ресурсы проекта:

```yaml
flutter:
  assets:
    - assets/ml/segformer.tflite
```

## Примечания по модели Segformer

- **Входные данные**: Изображение размером 512x512 пикселей, нормализованное от -1 до 1
- **Выходные данные**: Маска сегментации, где каждый пиксель содержит метку класса (для стен это обычно класс 1 или другой, в зависимости от обучения модели)
- **Позднее квантование**: Для оптимизации размера и скорости модели рекомендуется использовать квантование INT8 или FLOAT16

## Альтернативные подходы

Если конвертация ONNX в TFLite вызывает сложности, рассмотрите следующие варианты:

1. Использование pre-built модели для сегментации, такой как MobileNetV2+DeepLabV3
2. Поиск уже сконвертированных моделей для сегментации стен
3. Использование API для сегментации, если доступно интернет-соединение

## Дальнейшие улучшения

- Оптимизация модели для повышения FPS
- Кэширование результатов сегментации для низкопроизводительных устройств
- Реализация стабилизации маски для предотвращения мерцания 