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

/// Закрасить стену в указанной точке
class PaintWallAtPoint extends ARWallPainterEvent {
  final Offset position;
  final double screenWidth;
  final double screenHeight;

  const PaintWallAtPoint(this.position, this.screenWidth, this.screenHeight);

  @override
  List<Object?> get props => [position, screenWidth, screenHeight];
}

/// Очистить закрашенную стену
class ClearPaintedWall extends ARWallPainterEvent {
  const ClearPaintedWall();
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
