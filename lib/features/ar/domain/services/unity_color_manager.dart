import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import '../models/unity_models.dart';

/// Менеджер для управления коммуникацией с Unity AR сценой
class UnityColorManager {
  // Callback функции для обработки событий Unity
  Function(List<UnityClass>)? onClassesReceived;
  Function(UnityClass)? onClassClicked;
  Function(UnityColorChangedEvent)? onColorChanged;
  Function()? onUnityReady;
  Function(String)? onError;

  // Состояние менеджера
  bool _isUnityReady = false;
  List<UnityClass> _availableClasses = [];
  UnityClass? _selectedClass;

  // Геттеры для состояния
  bool get isUnityReady => _isUnityReady;
  List<UnityClass> get availableClasses => List.unmodifiable(_availableClasses);
  UnityClass? get selectedClass => _selectedClass;

  /// Инициализация менеджера
  void initialize() {
    developer.log('🎮 UnityColorManager: Инициализация...', name: 'Unity');
    _setupUnityMessageListener();
  }

  /// Настройка слушателя сообщений от Unity
  void _setupUnityMessageListener() {
    // Здесь будет настройка слушателя в методе onMessageFromUnity в виджете
    developer.log('🔧 UnityColorManager: Настройка слушателя сообщений',
        name: 'Unity');
  }

  /// Принудительно устанавливает Unity в состояние "готов"
  void forceReady() {
    if (!_isUnityReady) {
      developer.log(
          '🚦 UnityColorManager: Принудительная установка состояния "готов"',
          name: 'Unity');
      _isUnityReady = true;
    }
  }

  /// Обработка сообщений от Unity
  void handleUnityMessage(dynamic message) {
    developer.log('📨 Unity -> Flutter: $message', name: 'Unity');

    try {
      if (message == null) return;

      String messageStr = message.toString();

      // Проверяем формат сообщения (method:data)
      if (messageStr.contains(':')) {
        final colonIndex = messageStr.indexOf(':');
        final method = messageStr.substring(0, colonIndex).trim();
        final data = colonIndex < messageStr.length - 1
            ? messageStr.substring(colonIndex + 1).trim()
            : '';

        _processUnityEvent(method, data);
      } else {
        // Попробуем обработать как JSON
        if (messageStr.startsWith('{')) {
          final jsonData = jsonDecode(messageStr);
          if (jsonData is Map<String, dynamic>) {
            final method = jsonData['method'] as String?;
            final data = jsonData['data'];

            if (method != null) {
              _processUnityEvent(method, data?.toString() ?? '');
            }
          }
        } else {
          // Простое сообщение
          _processUnityEvent(messageStr, '');
        }
      }
    } catch (e) {
      developer.log('❌ Ошибка обработки сообщения Unity: $e', name: 'Unity');
      onError?.call('Ошибка обработки сообщения от Unity: $e');
    }
  }

  /// Обработка событий Unity
  void _processUnityEvent(String method, String data) {
    developer.log('🔄 Обработка события: $method, данные: $data',
        name: 'Unity');

    switch (method) {
      case 'onUnityReady':
        _handleUnityReady(data);
        break;
      case 'onAvailableClasses':
        _handleAvailableClasses(data);
        break;
      case 'onClassClicked':
        _handleClassClicked(data);
        break;
      case 'onColorChanged':
        _handleColorChanged(data);
        break;
      case 'error':
        _handleError(data);
        break;
      default:
        developer.log('⚠️ Неизвестное событие Unity: $method', name: 'Unity');
    }
  }

  /// Обработка готовности Unity
  void _handleUnityReady(String data) {
    developer.log('✅ Unity готов к работе', name: 'Unity');
    _isUnityReady = true;
    onUnityReady?.call();

    // Автоматически запрашиваем доступные классы
    Future.delayed(const Duration(milliseconds: 500), () {
      requestAvailableClasses();
    });
  }

  /// Обработка списка доступных классов
  void _handleAvailableClasses(String data) {
    try {
      final jsonData = jsonDecode(data);
      final response = UnityClassListResponse.fromJson(jsonData);

      _availableClasses = response.classes;
      developer.log('📝 Получен список классов: ${_availableClasses.length}',
          name: 'Unity');

      onClassesReceived?.call(_availableClasses);
    } catch (e) {
      developer.log('❌ Ошибка парсинга списка классов: $e', name: 'Unity');
      onError?.call('Ошибка получения списка классов');
    }
  }

  /// Обработка клика по классу
  void _handleClassClicked(String data) {
    try {
      final jsonData = jsonDecode(data);
      final clickEvent = UnityClassClickedEvent.fromJson(jsonData);
      final unityClass = clickEvent.toUnityClass();

      _selectedClass = unityClass;
      developer.log('👆 Клик по классу: ${unityClass.className}',
          name: 'Unity');

      onClassClicked?.call(unityClass);
    } catch (e) {
      developer.log('❌ Ошибка обработки клика по классу: $e', name: 'Unity');
      onError?.call('Ошибка обработки клика по объекту');
    }
  }

  /// Обработка изменения цвета
  void _handleColorChanged(String data) {
    try {
      final jsonData = jsonDecode(data);
      final colorEvent = UnityColorChangedEvent.fromJson(jsonData);

      developer.log(
          '🎨 Цвет изменен: ${colorEvent.className} -> ${colorEvent.color}',
          name: 'Unity');

      // Обновляем локальный список классов
      _updateClassColor(colorEvent.classId, colorEvent.color);

      onColorChanged?.call(colorEvent);
    } catch (e) {
      developer.log('❌ Ошибка обработки изменения цвета: $e', name: 'Unity');
      onError?.call('Ошибка обработки изменения цвета');
    }
  }

  /// Обработка ошибки Unity
  void _handleError(String data) {
    developer.log('❌ Ошибка Unity: $data', name: 'Unity');
    onError?.call(data);
  }

  /// Обновление цвета класса в локальном списке
  void _updateClassColor(int classId, String newColor) {
    final index = _availableClasses.indexWhere((c) => c.classId == classId);
    if (index != -1) {
      _availableClasses[index] =
          _availableClasses[index].copyWith(currentColor: newColor);

      // Обновляем выбранный класс, если это он
      if (_selectedClass?.classId == classId) {
        _selectedClass = _selectedClass!.copyWith(currentColor: newColor);
      }
    }
  }

  // ============ КОМАНДЫ В UNITY ============

  /// Устанавливает цвет для конкретного класса
  void setClassColor(int classId, Color color) {
    if (!_isUnityReady) {
      developer.log('⚠️ Unity не готов, отложена команда setClassColor',
          name: 'Unity');
      onError?.call('Unity еще не готов к работе');
      return;
    }

    try {
      final command = SetClassColorCommand.fromColor(classId, color);
      final message = command.toJsonString();

      developer.log('🎨 Flutter -> Unity: SetClassColorFromFlutter($message)',
          name: 'Unity');

      sendToUnity(
        'AsyncSegmentationManager',
        'SetClassColorFromFlutter',
        message,
      );

      developer.log('✅ Команда цвета отправлена в Unity', name: 'Unity');
    } catch (e) {
      developer.log('❌ Ошибка отправки цвета в Unity: $e', name: 'Unity');
      onError?.call('Не удалось отправить цвет в Unity');
    }
  }

  /// Запрашивает список доступных классов
  void requestAvailableClasses() {
    if (!_isUnityReady) {
      developer.log('⚠️ Unity не готов, отложен запрос классов', name: 'Unity');
      return;
    }

    try {
      developer.log('📝 Flutter -> Unity: GetAvailableClassesFromFlutter',
          name: 'Unity');

      sendToUnity(
        'AsyncSegmentationManager',
        'GetAvailableClassesFromFlutter',
        '',
      );

      developer.log('✅ Запрос классов отправлен в Unity', name: 'Unity');
    } catch (e) {
      developer.log('❌ Ошибка запроса классов: $e', name: 'Unity');
      onError?.call('Не удалось запросить список классов');
    }
  }

  /// Сбрасывает все пользовательские цвета
  void resetColors() {
    if (!_isUnityReady) {
      developer.log('⚠️ Unity не готов, отложена команда resetColors',
          name: 'Unity');
      onError?.call('Unity еще не готов к работе');
      return;
    }

    try {
      developer.log('🔄 Flutter -> Unity: ResetColorsFromFlutter',
          name: 'Unity');

      sendToUnity(
        'AsyncSegmentationManager',
        'ResetColorsFromFlutter',
        '',
      );

      developer.log('✅ Команда сброса цветов отправлена в Unity',
          name: 'Unity');

      // Очищаем локальное состояние
      _selectedClass = null;
    } catch (e) {
      developer.log('❌ Ошибка сброса цветов: $e', name: 'Unity');
      onError?.call('Не удалось сбросить цвета');
    }
  }

  /// Переключает в режим показа всех классов
  void showAllClasses() {
    if (!_isUnityReady) {
      developer.log('⚠️ Unity не готов, отложена команда showAllClasses',
          name: 'Unity');
      onError?.call('Unity еще не готов к работе');
      return;
    }

    try {
      developer.log('👁️ Flutter -> Unity: ShowAllClassesFromFlutter',
          name: 'Unity');

      sendToUnity(
        'AsyncSegmentationManager',
        'ShowAllClassesFromFlutter',
        '',
      );

      developer.log('✅ Команда показа всех классов отправлена в Unity',
          name: 'Unity');
    } catch (e) {
      developer.log('❌ Ошибка команды показа всех классов: $e', name: 'Unity');
      onError?.call('Не удалось переключить режим отображения');
    }
  }

  /// Устанавливает выбранный класс
  void setSelectedClass(UnityClass? unityClass) {
    _selectedClass = unityClass;
    developer.log('🎯 Выбран класс: ${unityClass?.className ?? 'null'}',
        name: 'Unity');
  }

  /// Очистка ресурсов
  void dispose() {
    developer.log('🧹 UnityColorManager: Очистка ресурсов', name: 'Unity');

    onClassesReceived = null;
    onClassClicked = null;
    onColorChanged = null;
    onUnityReady = null;
    onError = null;

    _isUnityReady = false;
    _availableClasses.clear();
    _selectedClass = null;
  }
}
