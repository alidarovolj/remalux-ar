# Исправление проблемы "UI actions are only available on root isolate"

## 🐛 Проблема
Приложение выдавало массовые ошибки:
```
❌ Ошибка обработки SegFormer в изоляте: UI actions are only available on root isolate.
❌ Ошибка в изоляте сегментации: UI actions are only available on root isolate.
```

## 🔍 Причина
В `SegmentationService` внутри фонового изолята пытались создать UI объекты:
- `ui.Path()` - UI объект для маски стены
- `ui.Rect.fromLTWH()` - UI прямоугольники

Во Flutter UI операции можно выполнять только в главном (root) изоляте. Попытка создания UI объектов в фоновом изоляте вызывает фатальную ошибку.

## ✅ Решение

### 1. Изменили архитектуру данных
**Было:**
```dart
class SegmentationResult {
  final ui.Path wallMask; // ❌ UI объект
}
```

**Стало:**
```dart
class SegmentationResult {
  final List<WallRect> wallRects; // ✅ Чистые данные
}

class WallRect {
  final double x, y, width, height; // ✅ Простые числа
}
```

### 2. Разделили обработку
**В изоляте (фоновый поток):**
- Обработка AI модели SegFormer
- Извлечение координат стен как простые числа
- Возврат списка `WallRect` (без UI зависимостей)

**В главном потоке:**
- Получение данных от изолята 
- Создание `ui.Path` из координат
- Передача готового UI объекта в отрисовку

### 3. Исправленный код

```dart
// В изоляте - только данные
static List<WallRect> _extractWallRectsFromSegmentation(...) {
  final wallRects = <WallRect>[];
  // ... обработка ...
  wallRects.add(WallRect(x: screenX, y: screenY, width: scaleX, height: scaleY));
  return wallRects; // ✅ Простые данные
}

// В главном потоке - создание UI
ui.Path _createWallPathFromRects(List<WallRect> wallRects) {
  final wallMask = ui.Path(); // ✅ UI операция в главном потоке
  for (final rect in wallRects) {
    wallMask.addRect(ui.Rect.fromLTWH(rect.x, rect.y, rect.width, rect.height));
  }
  return wallMask;
}
```

## 🎯 Результат
- ❌ Устранены ошибки "UI actions are only available on root isolate"
- ✅ SegFormer модель корректно обрабатывается в фоновом изоляте
- ✅ UI остается отзывчивым во время AI обработки
- ✅ Сегментация стен работает стабильно

## 📚 Урок
**Правило изолятов во Flutter:**
- Изоляты могут обрабатывать только чистые данные (числа, строки, списки)
- UI объекты (`Path`, `Rect`, `Color`, etc.) создаются только в главном потоке
- Передавайте между изолятами примитивные данные, а UI создавайте после получения результата

Это архитектурное ограничение Flutter для обеспечения thread-safety UI системы. 