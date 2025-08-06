# 🎮 Полная инструкция интеграции Unity с Flutter

Это руководство описывает все шаги для настройки Unity проекта для работы с Flutter через `flutter_embed_unity`.

## 📋 Содержание

1. [Требования](#требования)
2. [Настройка Unity проекта](#настройка-unity-проекта)
3. [Скрипты для коммуникации](#скрипты-для-коммуникации)
4. [Экспорт для iOS](#экспорт-для-ios)
5. [Экспорт для Android](#экспорт-для-android)
6. [Интеграция в Flutter](#интеграция-в-flutter)
7. [Решение проблем](#решение-проблем)

## 🔧 Требования

### Unity
- **Unity 2022.3 LTS** (рекомендуется 2022.3.21f1 или новее)
- **iOS**: минимум iOS 12+
- **Android**: минимум API 22+ (Android 5.1)

### Платформы
- **iOS**: Xcode 14+, macOS 
- **Android**: Android Studio, JDK 11+

## 🎯 Настройка Unity проекта

### 1. Основные настройки Player Settings

#### Общие настройки
1. Откройте **File → Build Settings → Player Settings**
2. В разделе **Other Settings** установите:
   - **Scripting Backend**: `IL2CPP`
   - **Api Compatibility Level**: `.NET Framework` или `.NET Standard 2.1`

#### Настройки для iOS
```
Configuration: Release (для production)
Target SDK: Device SDK
Architecture: Universal
Target minimum iOS Version: 12.0
```

#### Настройки для Android
```
Configuration: Release (для production)
Target API Level: 33+ (рекомендуется)
Minimum API Level: 22
Target Architectures: ARMv7 ✓, ARM64 ✓
```

### 2. Настройка XR (для AR проектов)

Если используете ARFoundation:

1. **Window → Package Manager**
2. Установите пакеты:
   - `AR Foundation`
   - `ARCore XR Plugin` (для Android)
   - `ARKit XR Plugin` (для iOS)

3. **Edit → Project Settings → XR Plug-in Management**
4. Включите нужные провайдеры:
   - iOS: `ARKit`
   - Android: `ARCore`

## 📡 Скрипты для коммуникации

### 1. FlutterUnityManager.cs

Создайте главный скрипт для управления коммуникацией:

```csharp
using UnityEngine;
using System.Collections;

public class FlutterUnityManager : MonoBehaviour
{
    public static FlutterUnityManager Instance { get; private set; }
    
    [Header("Компоненты")]
    public AsyncSegmentationManager segmentationManager;
    public ARWallPresenter arWallPresenter;
    
    void Awake()
    {
        // Singleton pattern
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
            InitializeManager();
        }
        else
        {
            Destroy(gameObject);
        }
    }
    
    void InitializeManager()
    {
        Debug.Log("🔗 FlutterUnityManager initialized");
    }
    
    void Start()
    {
        StartCoroutine(SendInitialState());
    }
    
    IEnumerator SendInitialState()
    {
        yield return new WaitForSeconds(1f);
        SendMessage("onUnityReady", "Unity scene loaded and ready");
    }
    
    #region Flutter Communication Methods
    
    /// <summary>
    /// Устанавливает цвет покраски стен из Flutter
    /// </summary>
    /// <param name="hexColor">Цвет в формате #RRGGBB</param>
    public void SetPaintColor(string hexColor)
    {
        Debug.Log($"🎨 Flutter -> Unity: SetPaintColor({hexColor})");
        
        if (string.IsNullOrEmpty(hexColor))
        {
            Debug.LogError("❌ Получен пустой цвет от Flutter");
            return;
        }
        
        // Парсим HEX цвет
        if (ColorUtility.TryParseHtmlString(hexColor, out Color color))
        {
            // Применяем цвет к системе сегментации
            if (segmentationManager != null)
            {
                segmentationManager.SetPaintColor(color);
                Debug.Log($"✅ Цвет применен к сегментации: {color}");
            }
            
            // Уведомляем Flutter об успешном применении
            SendMessage("colorChanged", $"Color changed to {hexColor}");
        }
        else
        {
            Debug.LogError($"❌ Не удалось распарсить цвет: {hexColor}");
            SendMessage("error", $"Invalid color format: {hexColor}");
        }
    }
    
    /// <summary>
    /// Включает/выключает режим рисования
    /// </summary>
    public void SetPaintingMode(string isEnabled)
    {
        bool enabled = isEnabled.ToLower() == "true";
        Debug.Log($"🖌️ Flutter -> Unity: SetPaintingMode({enabled})");
        
        // Применяем режим рисования
        if (segmentationManager != null)
        {
            segmentationManager.SetPaintingEnabled(enabled);
        }
        
        SendMessage("paintingModeChanged", enabled.ToString());
    }
    
    /// <summary>
    /// Сбрасывает все покрашенные стены
    /// </summary>
    public void ResetWalls(string unused)
    {
        Debug.Log("🔄 Flutter -> Unity: ResetWalls");
        
        if (segmentationManager != null)
        {
            segmentationManager.ResetPaint();
        }
        
        SendMessage("wallsReset", "Walls have been reset");
    }
    
    /// <summary>
    /// Переключает вспышку камеры
    /// </summary>
    public void ToggleFlashlight(string unused)
    {
        Debug.Log("🔦 Flutter -> Unity: ToggleFlashlight");
        
        // Здесь добавьте логику управления вспышкой
        // Например, через ARCameraManager
        
        SendMessage("flashlightToggled", "Flashlight toggled");
    }
    
    #endregion
    
    #region Send Messages to Flutter
    
    /// <summary>
    /// Отправляет сообщение во Flutter
    /// </summary>
    public void SendMessage(string eventType, string data)
    {
        string message = $"{eventType}:{data}";
        Debug.Log($"📤 Unity -> Flutter: {message}");
        
        // Для flutter_embed_unity используется SendToFlutter
        SendToFlutter.Send(message);
    }
    
    /// <summary>
    /// Отправляет состояние сегментации
    /// </summary>
    public void SendSegmentationState()
    {
        if (segmentationManager != null)
        {
            var state = new
            {
                isActive = segmentationManager.IsActive,
                paintColor = ColorUtility.ToHtmlStringRGB(segmentationManager.PaintColor),
                isPainting = segmentationManager.IsPaintingEnabled
            };
            
            string jsonState = JsonUtility.ToJson(state);
            SendMessage("segmentationState", jsonState);
        }
    }
    
    /// <summary>
    /// Отправляет ошибку во Flutter
    /// </summary>
    public void SendError(string errorMessage)
    {
        SendMessage("error", errorMessage);
    }
    
    #endregion
}
```

### 2. SendToFlutter.cs

Создайте утилитарный класс для отправки сообщений:

```csharp
using UnityEngine;

public static class SendToFlutter
{
    /// <summary>
    /// Отправляет сообщение во Flutter через flutter_embed_unity
    /// </summary>
    /// <param name="message">Сообщение для отправки</param>
    public static void Send(string message)
    {
        if (string.IsNullOrEmpty(message))
        {
            Debug.LogWarning("⚠️ Попытка отправить пустое сообщение во Flutter");
            return;
        }
        
        try
        {
#if UNITY_IOS && !UNITY_EDITOR
            // Для iOS используем native plugin
            _sendMessageToFlutter(message);
#elif UNITY_ANDROID && !UNITY_EDITOR
            // Для Android используем Java
            using (AndroidJavaClass unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                AndroidJavaObject activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
                activity.Call("sendToFlutter", message);
            }
#else
            // В редакторе просто логируем
            Debug.Log($"[EDITOR] SendToFlutter: {message}");
#endif
        }
        catch (System.Exception e)
        {
            Debug.LogError($"❌ Ошибка отправки сообщения во Flutter: {e.Message}");
        }
    }
    
#if UNITY_IOS && !UNITY_EDITOR
    [System.Runtime.InteropServices.DllImport("__Internal")]
    private static extern void _sendMessageToFlutter(string message);
#endif
}
```

### 3. AsyncSegmentationManager.cs (пример для AR)

```csharp
using UnityEngine;
using UnityEngine.XR.ARFoundation;

public class AsyncSegmentationManager : MonoBehaviour
{
    [Header("Настройки")]
    public Material segmentationMaterial;
    public Color paintColor = Color.blue;
    
    private bool isActive = false;
    private bool isPaintingEnabled = false;
    
    public bool IsActive => isActive;
    public Color PaintColor => paintColor;
    public bool IsPaintingEnabled => isPaintingEnabled;
    
    void Start()
    {
        InitializeSystem();
    }
    
    void InitializeSystem()
    {
        Debug.Log("🚀 AsyncSegmentationManager: Начинаем инициализацию...");
        
        // Инициализация AR и сегментации
        isActive = true;
        
        Debug.Log("✅ AsyncSegmentationManager инициализация завершена");
    }
    
    /// <summary>
    /// Устанавливает цвет покраски
    /// </summary>
    public void SetPaintColor(Color newColor)
    {
        paintColor = newColor;
        
        // Применяем цвет к материалу
        if (segmentationMaterial != null)
        {
            segmentationMaterial.SetColor("_PaintColor", paintColor);
            Debug.Log($"🎨 Цвет материала обновлен: {paintColor}");
        }
        
        // Уведомляем Flutter
        FlutterUnityManager.Instance?.SendMessage("colorApplied", ColorUtility.ToHtmlStringRGB(paintColor));
    }
    
    /// <summary>
    /// Включает/выключает режим рисования
    /// </summary>
    public void SetPaintingEnabled(bool enabled)
    {
        isPaintingEnabled = enabled;
        Debug.Log($"🖌️ Режим рисования: {(enabled ? "включен" : "выключен")}");
    }
    
    /// <summary>
    /// Сбрасывает покраску
    /// </summary>
    public void ResetPaint()
    {
        // Сбрасываем все покрашенные области
        Debug.Log("🔄 Сброс покраски");
        
        // Здесь добавьте логику сброса
        if (segmentationMaterial != null)
        {
            segmentationMaterial.SetFloat("_ResetPaint", Time.time);
        }
    }
}
```

## 📱 Экспорт для iOS

### 1. Настройка экспорта

1. **File → Build Settings**
2. Выберите **iOS** платформу
3. **Player Settings → iOS settings**:
   - Target minimum iOS Version: `12.0`
   - Target SDK: `Device SDK`
   - Architecture: `Universal`

### 2. Экспорт проекта

1. В **Build Settings** включите **Export Project**
2. Создайте папку `<flutter_project>/ios/UnityLibrary`
3. Нажмите **Build** и выберите созданную папку
4. Unity создаст Xcode проект в указанной папке

### 3. Настройка в Xcode

1. Откройте `<flutter_project>/ios/Runner.xcworkspace`
2. Добавьте Unity проект: **File → Add Files to "Runner"**
3. Выберите `UnityLibrary/Unity-iPhone.xcodeproj`
4. В `ios/Podfile` убедитесь в наличии:

```ruby
platform :ios, '12.0'
```

## 🤖 Экспорт для Android

### 1. Настройка экспорта

1. **File → Build Settings**
2. Выберите **Android** платформу
3. Включите **Export Project**
4. **Player Settings → Android settings**:
   - Minimum API Level: `22`
   - Target API Level: `33`
   - Scripting Backend: `IL2CPP`
   - Target Architectures: `ARMv7`, `ARM64`

### 2. Экспорт проекта

1. Создайте папку `<flutter_project>/android/unityLibrary`
2. Нажмите **Build** и выберите созданную папку
3. Unity создаст Android Studio проект

### 3. Настройка в Android

В `android/app/build.gradle` добавьте:

```gradle
dependencies {
    implementation project(':unityLibrary')
}
```

В `android/settings.gradle`:

```gradle
include ':unityLibrary'
```

## 🔗 Интеграция в Flutter

### 1. Добавление зависимости

В `pubspec.yaml`:

```yaml
dependencies:
  flutter_embed_unity: ^1.3.1
```

### 2. Использование в Flutter

```dart
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

// В виджете
EmbedUnity(
  onMessageFromUnity: (message) {
    print('Сообщение от Unity: $message');
    // Обработка сообщений от Unity
  },
)

// Отправка сообщений в Unity
sendToUnity(
  'FlutterUnityManager',  // GameObject name
  'SetPaintColor',        // Method name  
  '#FF5722',             // Message (HEX color)
);
```

### 3. Методы коммуникации

| Flutter → Unity | Описание |
|----------------|----------|
| `SetPaintColor(hexColor)` | Устанавливает цвет покраски |
| `SetPaintingMode(enabled)` | Включает/выключает рисование |
| `ResetWalls("")` | Сбрасывает покраску |
| `ToggleFlashlight("")` | Переключает вспышку |

| Unity → Flutter | Описание |
|----------------|----------|
| `onUnityReady` | Unity готов к работе |
| `colorChanged` | Цвет изменен |
| `paintingModeChanged` | Режим рисования изменен |
| `wallsReset` | Стены сброшены |
| `error` | Ошибка в Unity |

## 🔧 Решение проблем

### Проблема: Unity не получает сообщения

**Решение:**
1. Убедитесь, что GameObject называется `FlutterUnityManager`
2. Проверьте правильность названий методов
3. Добавьте логирование в Unity методы

### Проблема: Flutter не получает сообщения

**Решение:**
1. Используйте `SendToFlutter.Send()` в Unity
2. Проверьте реализацию native plugins
3. Тестируйте на реальном устройстве

### Проблема: Сборка не проходит

**Решение:**
1. Проверьте версии Unity (2022.3 LTS)
2. Убедитесь в правильности экспорта
3. Очистите кеши: `flutter clean`

### Отладка коммуникации

В Unity добавьте подробное логирование:

```csharp
void OnEnable()
{
    Debug.Log("FlutterUnityManager включен и готов принимать сообщения");
}

public void SetPaintColor(string hexColor)
{
    Debug.Log($"📨 Получено сообщение SetPaintColor: {hexColor}");
    // ... остальной код
}
```

## ✅ Чек-лист интеграции

### Unity проект
- [ ] Настроены Player Settings (IL2CPP, API levels)
- [ ] Добавлен FlutterUnityManager.cs
- [ ] Добавлен SendToFlutter.cs  
- [ ] GameObject назван "FlutterUnityManager"
- [ ] Включен "Export Project" при сборке

### Flutter проект
- [ ] Добавлена зависимость flutter_embed_unity
- [ ] Unity проект экспортирован в правильную папку
- [ ] Настроены native конфигурации (Podfile, build.gradle)
- [ ] EmbedUnity виджет добавлен в UI

### Тестирование
- [ ] Unity запускается в Flutter
- [ ] Сообщения от Flutter доходят до Unity
- [ ] Сообщения от Unity доходят до Flutter
- [ ] Функциональность работает на реальном устройстве

---

## 🚀 Готово!

После выполнения всех шагов у вас должна работать полная двусторонняя коммуникация между Flutter и Unity. Для дальнейшей разработки используйте этот шаблон и добавляйте новые методы по мере необходимости.

**Удачной разработки! 🎉**