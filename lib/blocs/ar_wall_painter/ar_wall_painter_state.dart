import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

/// Модель мазка кисти
class PaintStroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final DateTime timestamp;

  const PaintStroke({
    required this.points,
    required this.color,
    required this.size,
    required this.timestamp,
  });

  PaintStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    DateTime? timestamp,
  }) {
    return PaintStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Состояние AR Wall Painter
class ARWallPainterState extends Equatable {
  // Состояние камеры
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final bool isCameraError;
  final String? cameraErrorMessage;

  // Состояние AI модели
  final bool isAIModelLoaded;
  final bool isAIModelError;
  final String? aiErrorMessage;
  final ui.Path? wallMask;
  final double aiConfidence;

  // Состояние рисования
  final List<PaintStroke> paintStrokes;
  final PaintStroke? currentStroke;
  final bool isPainting;

  // UI настройки
  final Color selectedColor;
  final double brushSize;
  final bool isUIVisible;
  final bool showSegmentationOverlay;

  // Общее состояние
  final bool isInitializing;
  final bool isReady;
  final bool isProcessingFrame;
  final String? errorMessage;

  const ARWallPainterState({
    // Камера
    this.cameraController,
    this.isCameraInitialized = false,
    this.isCameraError = false,
    this.cameraErrorMessage,

    // AI модель
    this.isAIModelLoaded = false,
    this.isAIModelError = false,
    this.aiErrorMessage,
    this.wallMask,
    this.aiConfidence = 0.0,

    // Рисование
    this.paintStrokes = const [],
    this.currentStroke,
    this.isPainting = false,

    // UI
    this.selectedColor = Colors.blue,
    this.brushSize = 20.0,
    this.isUIVisible = true,
    this.showSegmentationOverlay = true, // Включаем по умолчанию для отладки

    // Общее
    this.isInitializing = false,
    this.isReady = false,
    this.isProcessingFrame = false,
    this.errorMessage,
  });

  /// Начальное состояние
  static const initial = ARWallPainterState();

  /// Состояние инициализации
  ARWallPainterState get initializing => copyWith(
        isInitializing: true,
        isReady: false,
        errorMessage: null,
      );

  /// Состояние готовности
  ARWallPainterState get ready => copyWith(
        isInitializing: false,
        isReady: true,
        errorMessage: null,
      );

  /// Состояние ошибки
  ARWallPainterState withError(String message) => copyWith(
        isInitializing: false,
        isReady: false,
        errorMessage: message,
      );

  ARWallPainterState copyWith({
    // Камера
    CameraController? cameraController,
    bool? isCameraInitialized,
    bool? isCameraError,
    String? cameraErrorMessage,

    // AI модель
    bool? isAIModelLoaded,
    bool? isAIModelError,
    String? aiErrorMessage,
    ui.Path? wallMask,
    double? aiConfidence,

    // Рисование
    List<PaintStroke>? paintStrokes,
    PaintStroke? currentStroke,
    bool? isPainting,

    // UI
    Color? selectedColor,
    double? brushSize,
    bool? isUIVisible,
    bool? showSegmentationOverlay,

    // Общее
    bool? isInitializing,
    bool? isReady,
    bool? isProcessingFrame,
    String? errorMessage,
  }) {
    return ARWallPainterState(
      // Камера
      cameraController: cameraController ?? this.cameraController,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      isCameraError: isCameraError ?? this.isCameraError,
      cameraErrorMessage: cameraErrorMessage ?? this.cameraErrorMessage,

      // AI модель
      isAIModelLoaded: isAIModelLoaded ?? this.isAIModelLoaded,
      isAIModelError: isAIModelError ?? this.isAIModelError,
      aiErrorMessage: aiErrorMessage ?? this.aiErrorMessage,
      wallMask: wallMask ?? this.wallMask,
      aiConfidence: aiConfidence ?? this.aiConfidence,

      // Рисование
      paintStrokes: paintStrokes ?? this.paintStrokes,
      currentStroke: currentStroke ?? this.currentStroke,
      isPainting: isPainting ?? this.isPainting,

      // UI
      selectedColor: selectedColor ?? this.selectedColor,
      brushSize: brushSize ?? this.brushSize,
      isUIVisible: isUIVisible ?? this.isUIVisible,
      showSegmentationOverlay:
          showSegmentationOverlay ?? this.showSegmentationOverlay,

      // Общее
      isInitializing: isInitializing ?? this.isInitializing,
      isReady: isReady ?? this.isReady,
      isProcessingFrame: isProcessingFrame ?? this.isProcessingFrame,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        cameraController,
        isCameraInitialized,
        isCameraError,
        cameraErrorMessage,
        isAIModelLoaded,
        isAIModelError,
        aiErrorMessage,
        wallMask,
        aiConfidence,
        paintStrokes,
        currentStroke,
        isPainting,
        selectedColor,
        brushSize,
        isUIVisible,
        showSegmentationOverlay,
        isInitializing,
        isReady,
        isProcessingFrame,
        errorMessage,
      ];
}
