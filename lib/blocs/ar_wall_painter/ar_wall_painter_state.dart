import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

import 'package:remalux_ar/core/services/segmentation_service_simple.dart';

@immutable
class ARWallPainterState extends Equatable {
  // Состояние инициализации
  final bool isInitializing;
  final bool isReady;
  final bool isCameraInitialized;
  final bool isAIModelLoaded;
  final bool isAIModelError;
  final String? aiErrorMessage;

  // Контроллер камеры
  final CameraController? cameraController;

  // Состояние обработки
  final bool isProcessingFrame;

  // Результаты AI
  final SegmentationResult? segmentationResult;
  final ui.Path? paintedWallPath; // Path для закрашенной стены
  final double aiConfidence;

  // Состояние UI
  final Color selectedColor;
  final bool isUIVisible;
  final bool showSegmentationOverlay;
  final String? errorMessage;

  const ARWallPainterState({
    this.isInitializing = true,
    this.isReady = false,
    this.isCameraInitialized = false,
    this.isAIModelLoaded = false,
    this.isAIModelError = false,
    this.aiErrorMessage,
    this.cameraController,
    this.isProcessingFrame = false,
    this.segmentationResult,
    this.paintedWallPath,
    this.aiConfidence = 0.0,
    this.selectedColor = const Color(0xFF2196F3),
    this.isUIVisible = true,
    this.showSegmentationOverlay = false,
    this.errorMessage,
  });

  static const initial = ARWallPainterState();

  ARWallPainterState get initializing =>
      copyWith(isInitializing: true, isReady: false, paintedWallPath: null);

  ARWallPainterState get ready =>
      copyWith(isInitializing: false, isReady: true);

  ARWallPainterState withError(String message) => copyWith(
        errorMessage: message,
        isInitializing: false,
        isReady: false,
      );

  ARWallPainterState copyWith({
    bool? isInitializing,
    bool? isReady,
    bool? isCameraInitialized,
    bool? isAIModelLoaded,
    bool? isAIModelError,
    String? aiErrorMessage,
    CameraController? cameraController,
    bool? isProcessingFrame,
    SegmentationResult? segmentationResult,
    ui.Path? paintedWallPath,
    double? aiConfidence,
    Color? selectedColor,
    bool? isUIVisible,
    bool? showSegmentationOverlay,
    String? errorMessage,
    bool? clearPaintedWallPath,
  }) {
    return ARWallPainterState(
      isInitializing: isInitializing ?? this.isInitializing,
      isReady: isReady ?? this.isReady,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      isAIModelLoaded: isAIModelLoaded ?? this.isAIModelLoaded,
      isAIModelError: isAIModelError ?? this.isAIModelError,
      aiErrorMessage: aiErrorMessage ?? this.aiErrorMessage,
      cameraController: cameraController ?? this.cameraController,
      isProcessingFrame: isProcessingFrame ?? this.isProcessingFrame,
      segmentationResult: segmentationResult ?? this.segmentationResult,
      paintedWallPath: clearPaintedWallPath == true
          ? null
          : paintedWallPath ?? this.paintedWallPath,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      selectedColor: selectedColor ?? this.selectedColor,
      isUIVisible: isUIVisible ?? this.isUIVisible,
      showSegmentationOverlay:
          showSegmentationOverlay ?? this.showSegmentationOverlay,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Свойства для удобства доступа в UI
  ui.Path? get wallMask => segmentationResult?.path;

  @override
  List<Object?> get props => [
        isInitializing,
        isReady,
        isCameraInitialized,
        isAIModelLoaded,
        isAIModelError,
        aiErrorMessage,
        cameraController,
        isProcessingFrame,
        segmentationResult,
        paintedWallPath,
        aiConfidence,
        selectedColor,
        isUIVisible,
        showSegmentationOverlay,
        errorMessage,
      ];
}
