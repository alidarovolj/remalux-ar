import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

abstract class ARWallPainterEvent extends Equatable {
  const ARWallPainterEvent();

  @override
  List<Object?> get props => [];
}

/// Инициализация камеры и AI модели
class InitializeARWallPainter extends ARWallPainterEvent {
  const InitializeARWallPainter();
}

/// Обработка кадра с камеры
class ProcessCameraFrame extends ARWallPainterEvent {
  final CameraImage cameraImage;
  final double screenWidth;
  final double screenHeight;

  const ProcessCameraFrame({
    required this.cameraImage,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  List<Object?> get props => [cameraImage, screenWidth, screenHeight];
}

/// Изменение выбранного цвета
class ChangeSelectedColor extends ARWallPainterEvent {
  final Color color;

  const ChangeSelectedColor(this.color);

  @override
  List<Object?> get props => [color];
}

/// Изменение размера кисти
class ChangeBrushSize extends ARWallPainterEvent {
  final double size;

  const ChangeBrushSize(this.size);

  @override
  List<Object?> get props => [size];
}

/// Начало рисования
class StartPainting extends ARWallPainterEvent {
  final Offset position;

  const StartPainting(this.position);

  @override
  List<Object?> get props => [position];
}

/// Продолжение рисования
class ContinuePainting extends ARWallPainterEvent {
  final Offset position;

  const ContinuePainting(this.position);

  @override
  List<Object?> get props => [position];
}

/// Окончание рисования
class EndPainting extends ARWallPainterEvent {
  const EndPainting();
}

/// Очистка всех мазков
class ClearPaintStrokes extends ARWallPainterEvent {
  const ClearPaintStrokes();
}

/// Отмена последнего мазка
class UndoLastStroke extends ARWallPainterEvent {
  const UndoLastStroke();
}

/// Переключение видимости UI
class ToggleUIVisibility extends ARWallPainterEvent {
  const ToggleUIVisibility();
}

/// Переключение показа сегментации
class ToggleSegmentationOverlay extends ARWallPainterEvent {
  const ToggleSegmentationOverlay();
}

/// Освобождение ресурсов
class DisposeARWallPainter extends ARWallPainterEvent {
  const DisposeARWallPainter();
}
