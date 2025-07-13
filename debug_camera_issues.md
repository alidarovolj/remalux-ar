# Диагностика проблем камеры AR Wall Painter

## Исправленные проблемы

### 1. ❌ Постоянный start/stop imageStream
**Проблема:** Приложение каждые 100ms вызывало `startImageStream` и сразу `stopImageStream`, что создавало race conditions.

**Решение:** 
- Убрали Timer.periodic
- Запускаем imageStream один раз при готовности
- Используем throttling внутри callback
- Останавливаем поток только при закрытии экрана

### 2. ❌ Null pointer exceptions в AVFoundationCamera
**Проблема:** CameraImage или его свойства могли быть null в момент обработки.

**Решение:**
- Добавили проверки валидности CameraImage
- Проверяем размеры изображения
- Проверяем наличие planes и bytes
- Добавили bounds checking в Stanford сервисе

## Изменения в коде

### ARWallPainterScreen
```dart
// Вместо Timer.periodic с start/stop
void _startImageStreamIfReady() {
  if (!_isImageStreamStarted && state.isReady) {
    state.cameraController!.startImageStream(_onCameraImage);
    _isImageStreamStarted = true;
  }
}

void _onCameraImage(CameraImage image) {
  // Throttling - обрабатываем только каждые 100ms
  if (now.difference(_lastFrameProcessed) < _frameThrottleDuration) return;
  
  if (_isProcessingFrame || !mounted) return;
  
  // Обработка кадра
}
```

### ARWallPainterBloc
```dart
Future<void> _onProcessCameraFrame(...) async {
  // Проверяем готовность системы и валидность данных
  if (!state.isReady || 
      state.isProcessingFrame || 
      emit.isDone ||
      event.cameraImage.planes.isEmpty) {
    return;
  }
  
  // Дополнительная проверка валидности изображения
  if (event.cameraImage.width <= 0 || event.cameraImage.height <= 0) {
    return;
  }
}
```

### WallPainterStanfordService
```dart
img.Image? _convertCameraImageToRgb(CameraImage cameraImage) {
  // Проверка валидности входных данных
  if (cameraImage.width <= 0 || 
      cameraImage.height <= 0 || 
      cameraImage.planes.isEmpty) {
    return null;
  }

  final plane0 = cameraImage.planes[0];
  if (plane0.bytes.isEmpty) {
    return null;
  }
  
  // Проверка размера буфера
  if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
    final expectedSize = cameraImage.width * cameraImage.height * 4;
    if (plane0.bytes.length < expectedSize) {
      return null;
    }
  }
}
```

## Ожидаемые результаты

✅ **Должно исчезнуть:**
- Множественные ошибки "Null check operator used on a null value"
- Потеря соединения с устройством
- Зависания при обработке кадров

✅ **Должно работать:**
- Стабильный поток камеры
- Плавная обработка кадров (10 FPS)
- Отзывчивый UI
- Корректная сегментация стен

## Тестирование

1. **Запуск приложения**: Должно запускаться без ошибок
2. **Камера**: Должна показывать видео без зависаний
3. **Сегментация**: Должна работать с касанием по стене
4. **Производительность**: 
   - Обработка: 50-150ms
   - Точность: 70-90%
   - Без потери кадров

## Дальнейшие улучшения

- [ ] Оптимизация производительности до 30+ FPS
- [ ] Добавление AR plane detection
- [ ] Интеграция ML моделей (DeepLabv3+, SegFormer)
- [ ] GPU ускорение 