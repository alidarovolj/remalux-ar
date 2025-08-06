import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

class ArState {
  final bool isUnityLoaded;
  final bool isLoading;
  final Color selectedColor;
  final List<Color> availableColors;
  final String? errorMessage;
  final bool isPainting;

  const ArState({
    this.isUnityLoaded = false,
    this.isLoading = true,
    this.selectedColor = const Color(0xFF2196F3),
    this.availableColors = const [
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFF795548), // Brown
      Color(0xFF607D8B), // Blue Grey
      Color(0xFFE91E63), // Pink
      Color(0xFF00BCD4), // Cyan
      Color(0xFFCDDC39), // Lime
      Color(0xFF3F51B5), // Indigo
      Color(0xFFFFEB3B), // Yellow
    ],
    this.errorMessage,
    this.isPainting = false,
  });

  ArState copyWith({
    bool? isUnityLoaded,
    bool? isLoading,
    Color? selectedColor,
    List<Color>? availableColors,
    String? errorMessage,
    bool? isPainting,
  }) {
    return ArState(
      isUnityLoaded: isUnityLoaded ?? this.isUnityLoaded,
      isLoading: isLoading ?? this.isLoading,
      selectedColor: selectedColor ?? this.selectedColor,
      availableColors: availableColors ?? this.availableColors,
      errorMessage: errorMessage ?? this.errorMessage,
      isPainting: isPainting ?? this.isPainting,
    );
  }
}

class ArNotifier extends StateNotifier<ArState> {
  ArNotifier() : super(const ArState()) {
    // Начинаем с загрузки Unity
    state = state.copyWith(
      isUnityLoaded: false,
      isLoading: true,
    );
    _initializeUnity();
  }

  void _initializeUnity() {
    // Даем Unity время на инициализацию
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(
          isUnityLoaded: true,
          isLoading: false,
        );
        // Отправляем текущий цвет после инициализации Unity
        _sendColorToUnity(state.selectedColor);
        print('Unity инициализирован, отправлен начальный цвет: ${state.selectedColor}');
      }
    });
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String error) {
    state = state.copyWith(
      errorMessage: error,
      isLoading: false,
    );
  }

  void selectColor(Color color) {
    state = state.copyWith(selectedColor: color);
    _sendColorToUnity(color);
  }

  void setPaintingMode(bool isPainting) {
    state = state.copyWith(isPainting: isPainting);
    _sendPaintingModeToUnity(isPainting);
  }

  void _sendColorToUnity(Color color) {
    if (!state.isUnityLoaded) {
      print('🔴 Unity еще не загружен, отложена отправка цвета');
      return;
    }

    final colorHex =
        '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';

    try {
      print('🎨 Отправляем цвет в Unity: $colorHex (RGB: ${color.red}, ${color.green}, ${color.blue})');
      
      // Используем новый API для отправки сообщений
      sendToUnity(
        'FlutterUnityManager',
        'SetPaintColor',
        colorHex,
      );
      print('✅ Цвет успешно отправлен в Unity: $colorHex');
    } catch (e) {
      print('❌ Ошибка отправки цвета в Unity: $e');
      setError('Не удалось отправить цвет в Unity');
    }
  }

  void _sendPaintingModeToUnity(bool isPainting) {
    if (!state.isUnityLoaded) {
      print('Unity еще не загружен, отложена отправка режима рисования');
      return;
    }

    try {
      sendToUnity(
        'FlutterUnityManager',
        'SetPaintingMode',
        isPainting ? 'true' : 'false',
      );
      print('Отправлен режим рисования в Unity: $isPainting');
    } catch (e) {
      print('Ошибка отправки режима рисования в Unity: $e');
    }
  }

  void resetWalls() {
    if (!state.isUnityLoaded) {
      print('Unity еще не загружен, нельзя сбросить стены');
      return;
    }

    try {
      sendToUnity(
        'FlutterUnityManager',
        'ResetWalls',
        '',
      );
      print('Отправлен сброс стен в Unity');
    } catch (e) {
      print('Ошибка сброса стен в Unity: $e');
    }
  }

  void toggleFlashlight() {
    if (!state.isUnityLoaded) {
      print('Unity еще не загружен, нельзя переключить вспышку');
      return;
    }

    try {
      sendToUnity(
        'FlutterUnityManager',
        'ToggleFlashlight',
        '',
      );
      print('Отправлено переключение вспышки в Unity');
    } catch (e) {
      print('Ошибка переключения вспышки в Unity: $e');
    }
  }
}

final arProvider = StateNotifierProvider<ArNotifier, ArState>((ref) {
  return ArNotifier();
});
