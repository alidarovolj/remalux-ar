# 📋 Полная инструкция интеграции Unity AR в Flutter (iOS)

## 🎯 Что мы интегрировали:
- Unity AR проект для сегментации и окрашивания стен
- Flutter приложение с цветовой палитрой
- Двустороннюю коммуникацию Flutter ↔ Unity

---

## 📦 Шаг 1: Подготовка Unity проекта

### 1.1 Установка flutter_embed_unity в Unity:
```
1. Скачайте flutter_embed_unity package
2. Unity → Assets → Import Package → Custom Package
3. Импортируйте пакет
```

### 1.2 Экспорт Unity проекта:
```
1. Unity → flutter_embed_unity → Export → iOS
2. Выберите папку: your_flutter_project/ios/unityLibrary/
3. Дождитесь завершения экспорта
```

**Результат:** Создается `ios/unityLibrary/` с Unity фреймворком и данными.

---

## 🛠 Шаг 2: Настройка Flutter проекта

### 2.1 Обновление pubspec.yaml:
```yaml
dependencies:
  flutter_embed_unity: ^1.3.1
```

### 2.2 Установка зависимостей:
```bash
flutter pub get
```

---

## 📱 Шаг 3: Создание AR интерфейса

### 3.1 Создание структуры AR модуля:
```
lib/features/ar/
├── domain/
│   └── providers/
│       └── ar_provider.dart
└── presentation/
    ├── pages/
    │   └── ar_page.dart
    └── widgets/
        ├── ar_controls_widget.dart
        ├── ar_loading_widget.dart
        └── color_palette_widget.dart
```

### 3.2 Основные файлы созданы:
- **ArProvider:** Управление состоянием и коммуникация с Unity
- **ArPage:** Главная AR страница с Unity виджетом
- **Виджеты:** Цветовая палитра и элементы управления

### 3.3 Добавление роута в app_router.dart:
```dart
GoRoute(
  path: '/ar',
  name: 'ar',
  builder: (context, state) {
    final colorParam = state.uri.queryParameters['color'];
    Color? initialColor;
    if (colorParam != null) {
      try {
        final colorValue = colorParam.startsWith('#')
            ? colorParam.substring(1)
            : colorParam;
        initialColor = Color(int.parse('FF$colorValue', radix: 16));
      } catch (e) {
        initialColor = null;
      }
    }
    return ArPage(initialColor: initialColor);
  },
),
```

### 3.4 Настройка навигации в home_page.dart:
```dart
CustomButton(
  label: 'home.visualize'.tr(),
  onPressed: () {
    context.push('/ar');
  },
  // ... другие параметры
),
```

---

## 🍎 Шаг 4: Критическая настройка iOS (Xcode)

### 4.1 Открыть проект в Xcode:
```bash
open ios/Runner.xcworkspace
```

### 4.2 Добавить Target Dependencies:
```
1. Выберите проект Runner → Target Runner
2. Build Phases → Target Dependencies
3. Нажмите + → Добавьте UnityFramework
```

### 4.3 Добавить Framework в Link Binary With Libraries:
```
1. Build Phases → Link Binary With Libraries
2. Нажмите + → Добавьте UnityFramework.framework
```

### 4.4 Настроить Framework Search Paths:
```
1. Build Settings → Framework Search Paths
2. Убедитесь что $(inherited) стоит ПЕРВЫМ
3. Добавьте: $(SRCROOT)/unityLibrary/Frameworks
```

### 4.5 КРИТИЧЕСКИЙ ШАГ - Добавить Run Script Phase:
```
1. Build Phases → + → New Run Script Phase
2. Перетащите скрипт ПОСЛЕ "[CP] Embed Pods Frameworks"
3. Вставьте команду:
```
```bash
cp -R "${SRCROOT}/unityLibrary/Data" "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/UnityFramework.framework/"
```

**Этот скрипт критически важен!** Без него Unity не найдет свои данные и будет крашиться.

---

## 🔧 Шаг 5: Установка iOS зависимостей

### 5.1 Полная очистка и переустановка:
```bash
# Очистка кэшей
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ios/Pods ios/Podfile.lock
flutter clean

# Переустановка зависимостей
flutter pub get
cd ios && pod install --repo-update && cd ..
```

### 5.2 Сборка и запуск:
```bash
flutter run --debug
```

---

## ⚠️ Решение критических проблем

### Ошибка: `No such module 'UnityFramework'`
**Решение:** Проверьте Target Dependencies и Framework Search Paths.

### Ошибка: `malloc: xzm: failed to initialize`
**Решение:** Это предупреждение Unity, не критично.

### Ошибка: `Could not open global-metadata.dat`
**Решение:** Добавьте Run Script Phase (самое важное!).

### Ошибка: `Framework 'Pods_Runner' not found`
**Решение:** Добавьте `$(inherited)` в начало Framework Search Paths.

---

## 🎮 Функциональность AR приложения

### Flutter → Unity коммуникация:
```dart
sendToUnity('FlutterUnityManager', 'SetWallColor', colorHex);
sendToUnity('FlutterUnityManager', 'ResetWalls', '');
sendToUnity('FlutterUnityManager', 'ToggleFlashlight', '');
```

### Возможности:
- ✅ AR камера с сегментацией стен
- ✅ Цветовая палитра для выбора цветов
- ✅ Передача цветов из модального окна в AR
- ✅ Сброс окрашивания стен
- ✅ Управление вспышкой

---

## 📋 Итоговая структура проекта:

```
remalux_ar/
├── ios/
│   ├── unityLibrary/           # Unity экспорт
│   │   ├── Data/               # Unity данные (автокопируются скриптом)
│   │   └── UnityFramework.framework/
│   └── Runner.xcworkspace      # Открывать в Xcode
├── lib/
│   ├── features/ar/            # AR модуль
│   └── core/router/            # Навигация с AR роутом
└── pubspec.yaml               # flutter_embed_unity: ^1.3.1
```

---

## 🚀 Workflow для будущих изменений

### Обычная разработка Flutter:
```bash
flutter run  # Стандартная команда
```

### При изменениях Unity проекта:
```bash
# 1. В Unity: flutter_embed_unity → Export iOS
# 2. В Flutter:
flutter clean
flutter run
```

### Для релиза:
```bash
flutter build ios --release
# Затем архивирование через Xcode
```

---

## ✅ Финальная проверка

**Успешная интеграция если:**
- ✅ Приложение запускается без крашей
- ✅ Unity показывает AR камеру
- ✅ Выбор цветов работает в Flutter
- ✅ Цвета передаются в Unity и применяются к стенам
- ✅ В логах нет ошибок `global-metadata.dat`

**🎉 ИНТЕГРАЦИЯ ЗАВЕРШЕНА УСПЕШНО!**

---

## 🔍 Дополнительные заметки

### Важные пути и файлы:
- **Unity экспорт:** `ios/unityLibrary/`
- **Unity данные:** `ios/unityLibrary/Data/`
- **Unity фреймворк:** `ios/unityLibrary/UnityFramework.framework`
- **Xcode workspace:** `ios/Runner.xcworkspace`

### Версии пакетов:
- **flutter_embed_unity:** ^1.3.1
- **Unity:** 2022.3.62f1 (IL2CPP)

### Платформы:
- **iOS:** Полностью настроено и работает
- **Android:** Требует дополнительной настройки Unity экспорта

---

**Автор:** AI Assistant  
**Дата:** Январь 2025  
**Проект:** remalux_ar Unity Integration