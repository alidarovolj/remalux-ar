# 🚀 **Руководство по интеграции новой Unity сборки**

## 📋 **Обзор**

Это руководство описывает процесс интеграции новой Unity сборки (из папки `assets/iOS`) в Flutter проект `remalux_ar` с использованием плагина `flutter_embed_unity`.

## 🔧 **Что было сделано**

### 1. **Копирование новой Unity сборки**
```bash
# Удаление старой сборки
rm -rf ios/unityLibrary

# Копирование новой сборки
cp -R assets/iOS ios/unityLibrary
```

### 2. **Сборка UnityFramework.framework**
```bash
cd ios/unityLibrary
xcodebuild -project Unity-iPhone.xcodeproj -scheme UnityFramework -configuration Debug -sdk iphoneos build
```

### 3. **Копирование собранного фреймворка**
```bash
# Найти собранный фреймворк
find ~/Library/Developer/Xcode/DerivedData -name "UnityFramework.framework" -type d

# Скопировать в unityLibrary
cp -R ~/Library/Developer/Xcode/DerivedData/Unity-iPhone-*/Build/Products/Debug-iphoneos/UnityFramework.framework ios/unityLibrary/
```

### 4. **Обновление плагина flutter_embed_unity**
```bash
# Найти папку плагина
find ~/.pub-cache -name "*flutter_embed_unity_2022_3_ios*" -type d

# Заменить UnityFramework.framework в плагине
cp -R ios/unityLibrary/UnityFramework.framework ~/.pub-cache/hosted/pub.dev/flutter_embed_unity_2022_3_ios-1.0.2/ios/

# Обновить Data папку с Unity ассетами
cp -R ios/unityLibrary/Data ~/.pub-cache/hosted/pub.dev/flutter_embed_unity_2022_3_ios-1.0.2/ios/UnityFramework.framework/
```

### 5. **Переустановка зависимостей**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install

cd ..
flutter clean
flutter pub get
```

## ⚠️ **Проблемы которые могли возникнуть**

### Ошибки Unity Runtime:
- **`malloc: xzm: failed to initialize deferred reclamation buffer`** - Ошибка инициализации памяти Unity
- **`Can't show file for stack frame`** - Проблемы с debugging символами Unity

### Возможные решения:

#### 1. **Настройки Xcode проекта Unity**
В `ios/unityLibrary/Unity-iPhone.xcodeproj` → Build Settings:
- **User Script Sandboxing**: `NO`
- **Enable Bitcode**: `NO`
- **Valid Architectures**: `arm64`

#### 2. **Настройки Unity Player Settings** (в Unity Editor)
- **Configuration**: `Release` (для production)
- **Script Debugging**: отключить
- **Crash & Exception Handling**: включить

#### 3. **Xcode Build Phases**
Добавить Run Script Phase для копирования Data:
```bash
cp -R "${SRCROOT}/unityLibrary/Data" "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/UnityFramework.framework/"
```

## 🎮 **Unity API Integration**

### Flutter → Unity Commands:
```dart
// Установка цвета класса
sendToUnity('AsyncSegmentationManager', 'SetClassColorFromFlutter', jsonEncode({
  'classId': 0,
  'color': '#FF0000'
}));

// Запрос доступных классов
sendToUnity('AsyncSegmentationManager', 'GetAvailableClassesFromFlutter', '');

// Сброс цветов
sendToUnity('AsyncSegmentationManager', 'ResetColorsFromFlutter', '');

// Показать все классы
sendToUnity('AsyncSegmentationManager', 'ShowAllClassesFromFlutter', '');
```

### Unity → Flutter Events:
- `onUnityReady` - Unity готов к работе
- `onAvailableClasses` - Список найденных классов объектов
- `onClassClicked` - Клик по объекту в Unity
- `onColorChanged` - Подтверждение изменения цвета

## 📱 **Flutter компоненты**

### Созданные компоненты:
1. **`lib/features/ar/domain/models/unity_models.dart`** - Модели данных Unity
2. **`lib/features/ar/domain/services/unity_color_manager.dart`** - Менеджер коммуникации
3. **`lib/features/ar/presentation/widgets/unity_color_palette_widget.dart`** - Палитра цветов
4. **`lib/features/ar/presentation/widgets/unity_class_list_widget.dart`** - Список объектов
5. **`lib/features/ar/presentation/pages/unity_ar_page.dart`** - AR страница

### Маршрутизация:
- **`/unity-ar`** - Новая AR страница с Unity API 2.0
- **`/ar`** - Старая AR страница (оставлена для совместимости)

## 🔄 **Workflow пользователя**

1. **Запуск** → Unity инициализируется и готов к работе
2. **Сканирование** → Unity автоматически ищет объекты (стены, пол, мебель)
3. **Выбор объекта** → Пользователь выбирает из списка найденных классов
4. **Выбор цвета** → Из палитры 20 готовых цветов + произвольный выбор
5. **Просмотр** → Unity отображает результат в реальном времени

## 🛠️ **Debugging**

### Логи Unity:
```
Built from '2022.3/staging' branch, Version '2022.3.62f1'
🔗 FlutterUnityManager initialized
🚀 AsyncSegmentationManager: Начинаем инициализацию...
✅ Модель загружена: model_unity_final
```

### Логи Flutter:
```
🎮 Unity готов к работе!
📝 Получен список классов: 2
🎯 Выбран класс для покраски: wall
🎨 Применяем цвет Color(0xffe53e3e) к классу wall
```

## ✅ **Проверка интеграции**

### Тестирование:
1. Запустить приложение: `flutter run`
2. Перейти на главную страницу
3. Нажать кнопку "Visualize"
4. Должна открыться Unity AR страница
5. Проверить инициализацию Unity
6. Проверить работу с цветами и объектами

### Ожидаемые результаты:
- ✅ Unity загружается без ошибок
- ✅ AR сканирование определяет объекты
- ✅ Выбор цвета работает корректно
- ✅ Покраска объектов отображается в реальном времени

## 🚨 **Если что-то пошло не так**

### Переустановка Unity сборки:
```bash
# 1. Очистить все
rm -rf ios/unityLibrary
rm -rf ios/Pods ios/Podfile.lock

# 2. Скопировать заново
cp -R assets/iOS ios/unityLibrary

# 3. Пересобрать фреймворк
cd ios/unityLibrary
xcodebuild -project Unity-iPhone.xcodeproj -scheme UnityFramework -configuration Debug -sdk iphoneos build

# 4. Обновить плагин
cp -R ~/Library/Developer/Xcode/DerivedData/Unity-iPhone-*/Build/Products/Debug-iphoneos/UnityFramework.framework ~/.pub-cache/hosted/pub.dev/flutter_embed_unity_2022_3_ios-1.0.2/ios/

# 5. Переустановить зависимости
cd ../ios && pod install
cd .. && flutter clean && flutter pub get
```

### Альтернативный плагин:
Если `flutter_embed_unity` не работает, можно вернуться к `flutter_unity_widget`:
```yaml
dependencies:
  flutter_unity_widget: ^2022.2.1
```

## 📚 **Дополнительные ресурсы**

- [flutter_embed_unity GitHub](https://github.com/learntoflutter/flutter_embed_unity)
- [Unity as a Library Documentation](https://docs.unity3d.com/Manual/UnityasaLibrary.html)
- [Unity iOS Integration Guide](https://docs.unity3d.com/Manual/UnityasaLibrary-iOS.html)

---

**Статус интеграции**: ✅ Завершена и готова к тестированию
