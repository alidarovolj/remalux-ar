# Ресурсы и модели для AR Wall Painting

## 📦 Готовые модели для скачивания

### DeepLabv3+ модели

1. **MobileNetV2 backbone (Рекомендуется для начала)**
   - Размер: 8.4 MB
   - Скорость: ~30ms на мобильном GPU
   ```bash
   wget https://storage.googleapis.com/download.tensorflow.org/models/tflite/gpu/deeplabv3_257_mv_gpu.tflite
   ```

2. **Xception backbone (Высокая точность)**
   - Размер: 54 MB  
   - Точность: 82% mIoU
   - [Скачать с TensorFlow Hub](https://tfhub.dev/tensorflow/lite-model/deeplabv3/1/metadata/2)

### SegFormer модели

1. **SegFormer-B0 (ADE20K)**
   - Размер: 3.8 MB
   - Современная архитектура
   ```bash
   # Требует конвертации из PyTorch
   pip install transformers
   python convert_segformer_to_tflite.py
   ```

2. **Hugging Face модели**
   - [nvidia/segformer-b0-finetuned-ade-512-512](https://huggingface.co/nvidia/segformer-b0-finetuned-ade-512-512)
   - [nvidia/segformer-b1-finetuned-ade-512-512](https://huggingface.co/nvidia/segformer-b1-finetuned-ade-512-512)

### Специализированные модели для интерьеров

1. **Indoor Scene Segmentation**
   - GitHub: [hellochick/Indoor-segmentation](https://github.com/hellochick/Indoor-segmentation)
   - Обучена на ADE20K Indoor
   - Требует конвертации из TensorFlow 1.x

## 🛠️ Инструменты и библиотеки

### Flutter пакеты

```yaml
# pubspec.yaml
dependencies:
  # AR
  ar_flutter_plugin: ^0.7.3
  arcore_flutter_plugin: ^0.1.0
  arkit_plugin: ^1.0.7
  
  # ML
  tflite_flutter: ^0.10.0
  tflite_flutter_helper: ^0.3.1
  
  # Обработка изображений
  image: ^4.0.0
  opencv: ^1.0.4
  
  # UI
  flutter_colorpicker: ^1.0.3
  
  # Камера
  camera: ^0.10.5
  
  # Unity (для продвинутой версии)
  flutter_unity_widget: ^2022.2.0
```

### Нативные библиотеки

**iOS (CocoaPods)**
```ruby
pod 'OpenCV', '~> 4.5.0'
pod 'TensorFlowLiteSwift'
```

**Android (Gradle)**
```gradle
implementation 'org.tensorflow:tensorflow-lite:2.13.0'
implementation 'org.tensorflow:tensorflow-lite-gpu:2.13.0'
implementation 'org.opencv:opencv-android:4.5.5'
```

## 📚 Датасеты

### ADE20K (MIT Scene Parsing)
- [Официальный сайт](http://sceneparsing.csail.mit.edu/)
- 150 классов включая "wall"
- 25K изображений с аннотациями

### COCO-Stuff
- [GitHub](https://github.com/nightrome/cocostuff)
- 171 класс включая архитектурные элементы
- 164K изображений

### SUN RGB-D
- [Princeton](http://rgbd.cs.princeton.edu/)
- Включает depth информацию
- Полезен для обучения с учетом глубины

## 🔧 Инструменты конвертации

### ONNX to TensorFlow
```bash
pip install onnx-tf
onnx-tf convert -i model.onnx -o model_tf/
```

### TensorFlow to TFLite
```python
converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()
```

### PyTorch to ONNX
```python
torch.onnx.export(model, dummy_input, "model.onnx", opset_version=11)
```

## 📱 Примеры приложений для изучения

### Open Source
1. [ARCore Unity Examples](https://github.com/google-ar/arcore-unity-sdk)
2. [ARKit Examples](https://github.com/laanlabs/ARBrush)
3. [TensorFlow Lite Examples](https://github.com/tensorflow/examples/tree/master/lite)

### Коммерческие приложения
1. **Dulux Visualizer** - [iOS](https://apps.apple.com/app/id557400983) | [Android](https://play.google.com/store/apps/details?id=com.akzonobel.duluxvisualizer)
2. **Sherwin-Williams ColorSnap** - [iOS](https://apps.apple.com/app/id334316106) | [Android](https://play.google.com/store/apps/details?id=com.colorsnap)
3. **Asian Paints Colour Next** - [iOS](https://apps.apple.com/app/id871745797) | [Android](https://play.google.com/store/apps/details?id=com.ap.colornext)

## 🎓 Научные статьи и исследования

1. **Stanford Imaggle Project** (2012)
   - "Real-time Image Segmentation for Augmented Reality"
   - Классический подход: Canny + Flood Fill
   - [PDF](https://stacks.stanford.edu/file/druid:yj296hj2790/Yeung_Piersol_Liu_Project_Imaggle.pdf)

2. **Multi-Channel Thresholding for AR** (2017)
   - Alexander Poole, Liu University
   - Оптимизация для мобильных устройств
   - [PDF](https://liu.diva-portal.org/smash/get/diva2:1144357/FULLTEXT01.pdf)

3. **DeepLab Series**
   - DeepLabv3+: [arXiv:1802.02611](https://arxiv.org/abs/1802.02611)
   - Encoder-Decoder with Atrous Separable Convolution

4. **SegFormer**
   - [arXiv:2105.15203](https://arxiv.org/abs/2105.15203)
   - Simple and Efficient Design for Semantic Segmentation

## 💻 Код примеры

### Базовая сегментация стен
```dart
// Доступен в репозитории
lib/services/wall_segmentation_service.dart
```

### AR интеграция
```dart
// Минимальный пример
lib/screens/simple_wall_painter.dart
```

### OpenCV через Platform Channel
```swift
// iOS implementation
ios/Runner/OpenCVBridge.swift
```

## 🔗 Полезные ссылки

### Документация
- [ARCore Developer Guide](https://developers.google.com/ar)
- [ARKit Documentation](https://developer.apple.com/documentation/arkit)
- [TensorFlow Lite Guide](https://www.tensorflow.org/lite/guide)
- [Flutter Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)

### Сообщества
- [Flutter AR Discord](https://discord.gg/flutter)
- [TensorFlow Lite Discussion](https://groups.google.com/g/tflite)
- [ARCore GitHub Issues](https://github.com/google-ar/arcore-unity-sdk/issues)

### Инструменты визуализации
- [Netron](https://netron.app/) - Визуализация ML моделей
- [TensorBoard](https://www.tensorflow.org/tensorboard) - Анализ производительности
- [AR Foundation Samples](https://github.com/Unity-Technologies/arfoundation-samples)

## 📊 Бенчмарки и тесты

### Производительность моделей на мобильных устройствах

| Модель | iPhone 12 | Pixel 6 | Размер |
|--------|-----------|---------|---------|
| DeepLabv3 MobileNetV2 | 28ms | 35ms | 8.4MB |
| DeepLabv3 Xception | 95ms | 120ms | 54MB |
| SegFormer-B0 | 22ms | 30ms | 3.8MB |
| Custom Wall Model | 15ms | 20ms | 2.1MB |

---

💡 **Совет**: Начните с DeepLabv3 MobileNetV2 для быстрого прототипа, затем экспериментируйте с другими моделями для улучшения качества. 