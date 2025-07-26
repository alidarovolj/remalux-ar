# 🔧 Руководство по устранению неполадок

## Проблема: "Future already completed" при перезапуске

### Симптомы
```
[ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: Bad state: Future already completed
```

### Причина
`Completer` в `CVWallPainterService` пытается завершиться повторно при реинициализации.

### Решение ✅
Исправлено в коммите:
- Изменен `final Completer<void> _isolateReady` на `Completer<void>? _isolateReady`
- Создается новый `Completer` при каждой инициализации
- Правильный сброс в методе `dispose()`

## Проблема: Черный экран вместо камеры

### Симптомы
- Приложение запускается, но показывает черный экран
- В логах нет сообщений об ошибках камеры

### Диагностика
Добавлены debug сообщения:
```dart
debugPrint('📷 Initializing camera...');
debugPrint('📷 Found ${_cameras.length} cameras');
debugPrint('📷 Camera controller initialized');
debugPrint('📷 Starting image stream...');
debugPrint('✅ Camera initialization completed');
```

### Решение ✅
Добавлен индикатор загрузки:
```dart
else
  // Camera loading indicator
  Positioned.fill(
    child: Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Инициализация камеры...'),
          ],
        ),
      ),
    ),
  ),
```

## Проблема: Roboflow API недоступен

### Симптомы
```
⚠️ API connection test failed: [error details]
```

### Проверка API ключей
```dart
static const String _apiKey = 'VDaf6TftUQZlE4pfp2tc';
static const String _publishableKey = 'rf_D4DydJifm7NuGjSSMKiIFzvuDVO2';
```

### Автоматический fallback ✅
При недоступности API система автоматически:
1. Переключается на `SegmentationMode.localOnly`
2. Использует локальные TFLite модели
3. Показывает предупреждения в логах

## Проблема: Высокое потребление памяти

### Диагностика
Используйте overlays для мониторинга:
- 📊 Performance overlay - FPS, CPU, память
- 🧠 Memory Stats overlay - состояние загруженных моделей
- ℹ️ Device Info - характеристики устройства

### Решение
- Автоматическое управление через `ModelManager`
- Лимит: максимум 2 модели одновременно
- Таймаут: выгрузка через 5 минут неиспользования

## Общие рекомендации

### При разработке
1. **Debug режим**: Всегда используйте debug сборку для диагностики
2. **Логи**: Включены подробные debug сообщения
3. **Hot restart**: При изменении сервисов используйте полный перезапуск

### При тестировании
1. **Профилирование**: Включите все overlays для мониторинга
2. **Разные устройства**: Тестируйте на low-end и high-end устройствах
3. **Сетевые условия**: Проверьте работу с медленным интернетом

### В продакшене
1. **Error handling**: Все ошибки обрабатываются gracefully
2. **Fallback modes**: Локальные модели как запасной вариант
3. **Analytics**: Отправка метрик производительности

## Команды для диагностики

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Профилирование
```bash
flutter run --profile
```

### Очистка кэша
```bash
flutter clean
flutter pub get
```

### Пересборка для iOS
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

## Проверочный чек-лист

### При запуске приложения
- [ ] 📷 Camera initialization завершена успешно
- [ ] 🎨 CV Wall Painter Service инициализирован
- [ ] 🧠 Memory Stats показывает 0 моделей изначально
- [ ] 📊 Performance overlay показывает стабильные метрики

### При использовании функций
- [ ] 🎛️ Переключение режимов сегментации работает
- [ ] 🔄 Fallback на локальные модели при проблемах с API
- [ ] 🧹 Автоматическая выгрузка неиспользуемых моделей
- [ ] ⚡ FPS остается стабильным (>20)

Если проблемы остаются, проверьте логи и используйте debug overlays для детальной диагностики! 🔍 