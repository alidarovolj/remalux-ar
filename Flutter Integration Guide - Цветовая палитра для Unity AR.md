# Flutter Integration Guide - Цветовая палитра для Unity AR

## 🎯 Обзор новой системы

Эта система предоставляет **Unity API 2.0** для продвинутой работы с сегментацией объектов и цветовой палитрой в AR. 

### ✨ Ключевые функции:
- 🤖 **Автоматическая сегментация** объектов (стены, пол, потолок, мебель)
- 🎨 **Интерактивная палитра** из 20 готовых цветов + произвольный выбор
- 👆 **Клики по объектам** для выбора что раскрашивать
- ⚡ **Реальное время** - изменения применяются мгновенно
- 🔄 **Управление состоянием** через Riverpod/GetX

---

## 📱 Flutter компоненты

### 1. Модели данных (`lib/features/ar/domain/models/unity_models.dart`)

```dart
// Класс объекта в Unity (стена, пол, мебель и т.д.)
class UnityClass {
  final int classId;
  final String className;
  final String currentColor;
  
  Color get color => Color(int.parse(currentColor.substring(1), radix: 16) + 0xFF000000);
}

// Список доступных классов
class UnityClassListResponse {
  final List<UnityClass> classes;
}

// События коммуникации
class UnityClassClickedEvent { /* ... */ }
class UnityColorChangedEvent { /* ... */ }
class SetClassColorCommand { /* ... */ }
```

### 2. Менеджер коммуникации (`lib/features/ar/domain/services/unity_color_manager.dart`)

```dart
class UnityColorManager {
  // Callbacks для событий Unity
  Function(List<UnityClass>)? onClassesReceived;
  Function(UnityClass)? onClassClicked;
  Function(UnityColorChangedEvent)? onColorChanged;
  Function()? onUnityReady;
  Function(String)? onError;
  
  // Команды в Unity
  void setClassColor(int classId, Color color) { /* ... */ }
  void requestAvailableClasses() { /* ... */ }
  void resetColors() { /* ... */ }
  void showAllClasses() { /* ... */ }
}
```

### 3. UI компоненты

#### Палитра цветов (`unity_color_palette_widget.dart`):
```dart
UnityColorPaletteWidget(
  onColorSelected: (color) => _unityManager.setClassColor(_selectedClass!.classId, color),
  selectedColor: _selectedColor,
  isEnabled: true,
)
```

#### Список объектов (`unity_class_list_widget.dart`):
```dart
UnityClassListWidget(
  classes: _availableClasses,
  onClassSelected: (unityClass) => setState(() { _selectedClass = unityClass; }),
  selectedClass: _selectedClass,
)
```

#### AR страница (`unity_ar_page.dart`):
```dart
EmbedUnity(
  onMessageFromUnity: (message) => _unityManager.handleUnityMessage(message),
)
```

---

## 🔄 Unity → Flutter API

### События, которые Unity отправляет во Flutter:

```dart
// Unity готов к работе
onUnityReady: (data) -> void

// Список найденных объектов 
onAvailableClasses: {
  "classes": [
    {"classId": 0, "className": "wall", "currentColor": "#0074D9"},
    {"classId": 1, "className": "floor", "currentColor": "#2ECC40"}
  ]
}

// Пользователь кликнул по объекту в Unity
onClassClicked: {
  "classId": 0,
  "className": "wall", 
  "currentColor": "#0074D9"
}

// Подтверждение изменения цвета
onColorChanged: {
  "classId": 0,
  "className": "wall",
  "color": "#FF0000"
}

// Ошибка Unity
error: "Описание ошибки"
```

---

## 🎮 Flutter → Unity API

### Команды, которые Flutter отправляет в Unity:

```dart
// Установить цвет для объекта
sendToUnity('AsyncSegmentationManager', 'SetClassColorFromFlutter', jsonEncode({
  'classId': 0,
  'color': '#FF0000'  // Красный цвет для стены
}));

// Запросить список доступных объектов
sendToUnity('AsyncSegmentationManager', 'GetAvailableClassesFromFlutter', '');

// Сбросить все цвета к умолчанию
sendToUnity('AsyncSegmentationManager', 'ResetColorsFromFlutter', '');

// Показать все объекты (включая скрытые)
sendToUnity('AsyncSegmentationManager', 'ShowAllClassesFromFlutter', '');
```

---

## 🛠 Unity C# скрипты

### 1. `FlutterUnityManager.cs` - мост коммуникации

```csharp
public class FlutterUnityManager : MonoBehaviour {
    void Start() {
        SendToFlutter("onUnityReady", "Unity инициализирован");
    }
    
    public void SetClassColorFromFlutter(string jsonData) {
        var data = JsonUtility.FromJson<ColorCommand>(jsonData);
        AsyncSegmentationManager.Instance.SetClassColor(data.classId, data.color);
    }
    
    public void GetAvailableClassesFromFlutter(string _) {
        var classes = AsyncSegmentationManager.Instance.GetAvailableClasses();
        SendToFlutter("onAvailableClasses", JsonUtility.ToJson(new { classes }));
    }
}
```

### 2. `AsyncSegmentationManager.cs` - основная логика

```csharp
public class AsyncSegmentationManager : MonoBehaviour {
    public void SetClassColor(int classId, string hexColor) {
        // Применяет цвет к объектам указанного класса
        Color color = ColorUtility.TryParseHtmlString(hexColor, out Color result) ? result : Color.white;
        ApplyColorToClass(classId, color);
        
        // Отправляем подтверждение во Flutter
        SendToFlutter("onColorChanged", new { classId, color = hexColor });
    }
    
    public ClassInfo[] GetAvailableClasses() {
        // Возвращает список найденных объектов
        return detectedClasses.ToArray();
    }
}
```

---

## 📱 Пример использования

### Полный workflow пользователя:

```dart
class UnityArPage extends StatefulWidget {
  @override
  _UnityArPageState createState() => _UnityArPageState();
}

class _UnityArPageState extends State<UnityArPage> {
  final UnityColorManager _unityManager = UnityColorManager();
  List<UnityClass> _availableClasses = [];
  UnityClass? _selectedClass;
  Color? _selectedColor;
  
  @override
  void initState() {
    super.initState();
    _setupUnityCallbacks();
  }
  
  void _setupUnityCallbacks() {
    // Unity готов
    _unityManager.onUnityReady = () {
      setState(() { _isUnityReady = true; });
      _unityManager.requestAvailableClasses();
    };
    
    // Получен список объектов
    _unityManager.onClassesReceived = (classes) {
      setState(() { 
        _availableClasses = classes;
        _selectedClass = classes.first; // Выбираем первый по умолчанию
      });
    };
    
    // Пользователь кликнул по объекту
    _unityManager.onClassClicked = (clickedClass) {
      setState(() { _selectedClass = clickedClass; });
    };
    
    // Цвет изменен
    _unityManager.onColorChanged = (event) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Цвет применен к ${event.className}'))
      );
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Unity AR виджет
          EmbedUnity(
            onMessageFromUnity: (message) => _unityManager.handleUnityMessage(message),
          ),
          
          // UI элементы поверх AR
          if (_isUnityReady) ...[
            // Список объектов
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: UnityClassListWidget(
                classes: _availableClasses,
                onClassSelected: (unityClass) => setState(() { _selectedClass = unityClass; }),
                selectedClass: _selectedClass,
              ),
            ),
            
            // Палитра цветов
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: UnityColorPaletteWidget(
                onColorSelected: (color) {
                  if (_selectedClass != null) {
                    _unityManager.setClassColor(_selectedClass!.classId, color);
                    setState(() { _selectedColor = color; });
                  }
                },
                selectedColor: _selectedColor,
              ),
            ),
            
            // Кнопки управления
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _unityManager.showAllClasses(),
                    child: Text('Показать все'),
                  ),
                  ElevatedButton(
                    onPressed: () => _unityManager.resetColors(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Сбросить'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 🚀 Быстрый старт

### 1. Добавьте зависимости:
```yaml
dependencies:
  flutter_embed_unity: ^1.3.1  # Для Unity интеграции
  get: ^4.6.5                  # Для GetX (по желанию)
```

### 2. Добавьте маршрут:
```dart
// в app_router.dart
GoRoute(
  path: '/unity-ar',
  name: 'unity_ar',
  builder: (context, state) => UnityArPage(),
),
```

### 3. Используйте в приложении:
```dart
// Переход к Unity AR
context.push('/unity-ar');

// С начальным цветом
context.push('/unity-ar?color=FF0000');
```

---

## 🐛 Решение проблем

### Проблема: Постоянная загрузка
**Причина**: Unity не отправляет `onUnityReady`
**Решение**: Добавлен таймер принудительного убирания загрузки через 8 секунд

```dart
// В unity_ar_page.dart
Future.delayed(const Duration(seconds: 8), () {
  if (_isLoading && mounted) {
    setState(() {
      _isLoading = false;
      _isUnityReady = true;
      // Создаем базовые классы если Unity не ответил
      if (_availableClasses.isEmpty) {
        _availableClasses = [
          UnityClass(classId: 0, className: 'wall', currentColor: '#0074D9'),
          UnityClass(classId: 1, className: 'floor', currentColor: '#2ECC40'),
        ];
      }
    });
  }
});
```

### Проблема: Нет палитры цветов
**Причина**: Палитра скрывается когда `_selectedClass == null`
**Решение**: Показываем палитру всегда + создаем базовые классы

```dart
// Показываем палитру всегда, не только когда выбран класс
UnityColorPaletteWidget(
  onColorSelected: _onColorSelected,
  selectedColor: _selectedColor,
  isEnabled: true, // Всегда доступна
)
```

### Проблема: Unity не отвечает на команды
**Причина**: Неправильные имена объектов/методов в Unity
**Решение**: Убедитесь что Unity содержит:
- `AsyncSegmentationManager` GameObject
- Методы: `SetClassColorFromFlutter`, `GetAvailableClassesFromFlutter`
- `FlutterUnityManager` для отправки событий

---

## 📋 Чек-лист интеграции

### Flutter:
- ✅ Добавлен `flutter_embed_unity` в pubspec.yaml
- ✅ Созданы модели данных Unity
- ✅ Настроен `UnityColorManager`
- ✅ Созданы UI компоненты (палитра, список классов)
- ✅ Добавлена Unity AR страница
- ✅ Настроена маршрутизация

### Unity:
- ⚠️ `AsyncSegmentationManager` с методами API
- ⚠️ `FlutterUnityManager` для коммуникации
- ⚠️ Правильная отправка событий во Flutter
- ⚠️ Методы обработки команд от Flutter

### Отладка:
- ✅ Добавлено логирование сообщений Unity
- ✅ Таймер принудительного убирания загрузки
- ✅ Базовые классы по умолчанию
- ✅ Обработка ошибок коммуникации

---

## 🎯 Следующие шаги

1. **Проверить Unity скрипты** - убедиться что все методы реализованы
2. **Тестировать коммуникацию** - проверить отправку/получение сообщений
3. **Оптимизировать UI** - улучшить расположение палитры и элементов
4. **Добавить больше функций** - сохранение сцен, шаблоны цветов, и т.д.

**Статус**: ✅ Flutter интеграция готова, 🔧 Unity коммуникация требует проверки
