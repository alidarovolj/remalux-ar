import 'dart:convert';
import 'package:flutter/material.dart';

/// Модель класса объекта в Unity
class UnityClass {
  final int classId;
  final String className;
  final String currentColor;

  const UnityClass({
    required this.classId,
    required this.className,
    required this.currentColor,
  });

  /// Создание из JSON
  factory UnityClass.fromJson(Map<String, dynamic> json) {
    return UnityClass(
      classId: json['classId'] as int,
      className: json['className'] as String,
      currentColor: json['currentColor'] as String,
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'currentColor': currentColor,
    };
  }

  /// Получение цвета как Color объект
  Color get color {
    try {
      String colorHex = currentColor;
      if (colorHex.startsWith('#')) {
        colorHex = colorHex.substring(1);
      }

      // Если 6 символов, добавляем полную прозрачность
      if (colorHex.length == 6) {
        colorHex = 'FF$colorHex';
      }

      return Color(int.parse(colorHex, radix: 16));
    } catch (e) {
      // Возвращаем серый цвет по умолчанию при ошибке
      return Colors.grey;
    }
  }

  /// Копирование с изменениями
  UnityClass copyWith({
    int? classId,
    String? className,
    String? currentColor,
  }) {
    return UnityClass(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      currentColor: currentColor ?? this.currentColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnityClass &&
        other.classId == classId &&
        other.className == className &&
        other.currentColor == currentColor;
  }

  @override
  int get hashCode => Object.hash(classId, className, currentColor);

  @override
  String toString() {
    return 'UnityClass(classId: $classId, className: $className, currentColor: $currentColor)';
  }
}

/// Ответ со списком классов от Unity
class UnityClassListResponse {
  final List<UnityClass> classes;

  const UnityClassListResponse({
    required this.classes,
  });

  /// Создание из JSON
  factory UnityClassListResponse.fromJson(Map<String, dynamic> json) {
    return UnityClassListResponse(
      classes: (json['classes'] as List<dynamic>)
          .map((x) => UnityClass.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'classes': classes.map((x) => x.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'UnityClassListResponse(classes: $classes)';
  }
}

/// Команда для установки цвета класса в Unity
class SetClassColorCommand {
  final int classId;
  final String color;

  const SetClassColorCommand({
    required this.classId,
    required this.color,
  });

  /// Создание из Flutter Color
  factory SetClassColorCommand.fromColor(int classId, Color color) {
    final colorHex =
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    return SetClassColorCommand(
      classId: classId,
      color: colorHex,
    );
  }

  /// Преобразование в JSON для отправки в Unity
  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'color': color,
    };
  }

  /// Преобразование в JSON строку
  String toJsonString() {
    return jsonEncode(toJson());
  }

  @override
  String toString() {
    return 'SetClassColorCommand(classId: $classId, color: $color)';
  }
}

/// Уведомление о клике по классу от Unity
class UnityClassClickedEvent {
  final int classId;
  final String className;
  final String currentColor;

  const UnityClassClickedEvent({
    required this.classId,
    required this.className,
    required this.currentColor,
  });

  /// Создание из JSON
  factory UnityClassClickedEvent.fromJson(Map<String, dynamic> json) {
    return UnityClassClickedEvent(
      classId: json['classId'] as int,
      className: json['className'] as String,
      currentColor: json['currentColor'] as String,
    );
  }

  /// Преобразование в UnityClass
  UnityClass toUnityClass() {
    return UnityClass(
      classId: classId,
      className: className,
      currentColor: currentColor,
    );
  }

  @override
  String toString() {
    return 'UnityClassClickedEvent(classId: $classId, className: $className, currentColor: $currentColor)';
  }
}

/// Уведомление об изменении цвета от Unity
class UnityColorChangedEvent {
  final int classId;
  final String color;
  final String className;

  const UnityColorChangedEvent({
    required this.classId,
    required this.color,
    required this.className,
  });

  /// Создание из JSON
  factory UnityColorChangedEvent.fromJson(Map<String, dynamic> json) {
    return UnityColorChangedEvent(
      classId: json['classId'] as int,
      color: json['color'] as String,
      className: json['className'] as String,
    );
  }

  @override
  String toString() {
    return 'UnityColorChangedEvent(classId: $classId, color: $color, className: $className)';
  }
}

/// Статус готовности Unity
class UnityReadyEvent {
  final String status;

  const UnityReadyEvent({
    required this.status,
  });

  /// Создание из JSON
  factory UnityReadyEvent.fromJson(Map<String, dynamic> json) {
    return UnityReadyEvent(
      status: json['status'] as String? ?? 'ready',
    );
  }

  /// Проверка готовности
  bool get isReady => status == 'ready';

  @override
  String toString() {
    return 'UnityReadyEvent(status: $status)';
  }
}
