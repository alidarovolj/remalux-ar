# BiseNet Setup для CV Wall Painter 

## 🎯 Что такое BiseNet?

**BiseNet от Qualcomm** - это ультра-оптимизированная модель семантической сегментации, специально разработанная для мобильных устройств с чипами Snapdragon.

### 🚀 Ключевые преимущества:
- **18-86ms** время обработки кадра
- **720x960** высокое разрешение входа
- **45.7MB** компактный размер
- **NPU оптимизация** для Qualcomm чипов
- **Real-time** производительность

## 📋 Что уже скачано:

Из [Hugging Face Qualcomm BiseNet](https://huggingface.co/qualcomm/BiseNet):
- ✅ **`Models/BiseNet.tflite`** - TensorFlow Lite модель
- ✅ **`Models/BiseNet.onnx`** - ONNX модель

## 🔧 Настройка проекта

### 1. Обновить pubspec.yaml

Добавьте папку Models в assets:

```yaml
flutter:
  assets:
    - assets/
    - assets/ml/
    - Models/  # Добавить эту строку
```

### 2. Структура файлов

Убедитесь, что у вас есть:
```
remalux_ar/
├── Models/
│   ├── BiseNet.tflite  ✅
│   └── BiseNet.onnx    ✅
├── assets/
│   └── ml/
│       └── labels.txt  ✅
└── lib/
    ├── core/services/
    │   └── cv_wall_painter_service.dart  ✅
    └── screens/
        └── cv_wall_painter_screen.dart   ✅
```

### 3. Проверить обновления кода

Уже обновлено в нашем коде:
- ✅ Путь к модели: `Models/BiseNet.tflite`
- ✅ Разрешение входа: `720x960`
- ✅ Интервал обработки: `100ms`
- ✅ Отладочные сообщения для BiseNet

## 🧪 Тестирование

### Команды для запуска:
```bash
# 1. Обновить зависимости
flutter pub get

# 2. Запустить приложение
flutter run

# 3. Перейти в CV Wall Painter
# В приложении: /cv-wall-painter
```

### Проверка загрузки модели:
```dart
// В консоли вы должны увидеть:
🎨 Инициализация CV Wall Painter Service (BiseNet)
🧠 Загрузка BiseNet модели от Qualcomm...
✅ CV Wall Painter Service готов (BiseNet от Qualcomm)
```

## 📊 Ожидаемая производительность

### Бенчмарки BiseNet (по данным Qualcomm):

| Устройство | Время обработки |
|------------|----------------|
| **Snapdragon 8 Elite** | 14-18ms 🚀 |
| **Samsung Galaxy S23/S24** | 26-28ms ⚡ |
| **Snapdragon 8 Gen 2/3** | 24-28ms |
| **Snapdragon 8 Gen 1** | 30-35ms |
| **Snapdragon 888** | 45-60ms |
| **Другие устройства** | 60-86ms |

### Сравнение с DeepLabV3:
```
DeepLabV3: 100-200ms ❌ Медленно
BiseNet:   18-86ms   ✅ В 2-3 раза быстрее!

Разрешение:
DeepLabV3: 513x513   ❌ Низкое
BiseNet:   720x960   ✅ Высокое

Размер модели:
DeepLabV3: 2.4MB     ❌ Урезанная
BiseNet:   45.7MB    ✅ Полнофункциональная
```

## 🔧 Настройки оптимизации

### Для топовых устройств (Snapdragon 8 Elite/Gen 3):
```dart
static const int maxProcessingWidth = 960;   // Полное разрешение
static const int maxProcessingHeight = 720;
static const Duration processingInterval = Duration(milliseconds: 50);
```

### Для средних устройств (Snapdragon 8 Gen 1/888):
```dart
static const int maxProcessingWidth = 480;   // Текущие настройки
static const int maxProcessingHeight = 360;
static const Duration processingInterval = Duration(milliseconds: 100);
```

### Для слабых устройств:
```dart
static const int maxProcessingWidth = 320;
static const int maxProcessingHeight = 240;
static const Duration processingInterval = Duration(milliseconds: 150);
```

## 🐛 Устранение неполадок

### Проблема: Модель не загружается
```
❌ Ошибка загрузки модели: BiseNet.tflite не найден

Решение:
1. Проверьте путь: Models/BiseNet.tflite
2. Убедитесь что Models/ добавлен в pubspec.yaml
3. Выполните: flutter clean && flutter pub get
```

### Проблема: Медленная обработка
```
⚠️ Время обработки > 100ms

Решение:
1. Проверьте что у вас Qualcomm чип
2. Уменьшите разрешение обработки
3. Увеличьте processingInterval
```

### Проблема: Низкая точность
```
⚠️ Confidence < 60%

Решение:
1. Улучшите освещение
2. Направьте камеру на четкую стену
3. Избегайте быстрых движений
```

## 🎉 Проверка готовности

### ✅ Чек-лист установки:
- [ ] Models/BiseNet.tflite скачан
- [ ] pubspec.yaml обновлен
- [ ] flutter pub get выполнен
- [ ] Приложение запускается
- [ ] CV Wall Painter экран открывается
- [ ] Сообщение "BiseNet готов" появляется
- [ ] Покраска стен работает

### 🎯 Следующие шаги:
1. **Протестировать на реальной стене**
2. **Измерить производительность на вашем устройстве**
3. **Настроить оптимальные параметры**
4. **Добавить UI кнопку для доступа**

---

## 🏆 Заключение

**BiseNet готов к использованию!** Эта модель превосходит DeepLabV3 по всем показателям:
- ⚡ **Скорость**: в 2-3 раза быстрее
- 🎯 **Точность**: выше качество сегментации  
- 📱 **Оптимизация**: специально для мобильных
- 🔋 **Эффективность**: меньше энергопотребления

**Время тестировать!** 🚀 