import 'dart:async';
import 'dart:ui' as ui;
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:remalux_ar/blocs/ar_wall_painter/ar_wall_painter_event.dart';
import 'package:remalux_ar/blocs/ar_wall_painter/ar_wall_painter_state.dart';
import 'package:remalux_ar/core/services/segmentation_service_simple.dart';

class ARWallPainterBloc extends Bloc<ARWallPainterEvent, ARWallPainterState> {
  final SegmentationServiceSimple _segmentationService =
      SegmentationServiceSimple.instance;

  ARWallPainterBloc() : super(ARWallPainterState.initial) {
    // Регистрируем обработчики событий
    on<InitializeARWallPainter>(_onInitialize);
    on<ProcessCameraFrame>(_onProcessCameraFrame);
    on<ChangeSelectedColor>(_onChangeSelectedColor);
    on<PaintWallAtPoint>(_onPaintWallAtPoint);
    on<ClearPaintedWall>(_onClearPaintedWall);
    on<ToggleUIVisibility>(_onToggleUIVisibility);
    on<ToggleSegmentationOverlay>(_onToggleSegmentationOverlay);
    on<DisposeARWallPainter>(_onDispose);
  }

  /// Инициализация камеры и AI модели
  Future<void> _onInitialize(
    InitializeARWallPainter event,
    Emitter<ARWallPainterState> emit,
  ) async {
    emit(state.initializing);

    try {
      print('🚀 ARWallPainterBloc: Начинаем инициализацию');

      // 1. Инициализация камеры
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(state.withError('Камера недоступна'));
        return;
      }

      final cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await cameraController.initialize();
      emit(state.copyWith(
        cameraController: cameraController,
        isCameraInitialized: true,
      ));

      print('✅ Камера инициализирована');

      // 2. Инициализация AI модели (без колбэка)
      await _segmentationService.initialize();

      // Если мы дошли до сюда, значит модель загрузилась без ошибок
      emit(state.copyWith(
        isAIModelLoaded: true,
      ));
      print('✅ AI модель загружена');

      // 3. Финальное состояние готовности
      if (state.isCameraInitialized && state.isAIModelLoaded) {
        emit(state.ready);
        print('🎉 ARWallPainterBloc готов к работе');
      }
    } catch (e) {
      emit(state.withError('Ошибка инициализации: $e'));
      print('❌ Ошибка инициализации: $e');
    }
  }

  /// Обработка кадра с камеры
  Future<void> _onProcessCameraFrame(
    ProcessCameraFrame event,
    Emitter<ARWallPainterState> emit,
  ) async {
    if (!state.isReady || state.isProcessingFrame) return;

    emit(state.copyWith(isProcessingFrame: true));

    try {
      // Получаем результат сегментации напрямую
      final result = await _segmentationService.processCameraImage(
        event.cameraImage,
        event.screenWidth,
        event.screenHeight,
      );

      if (result != null && !emit.isDone) {
        emit(state.copyWith(
          segmentationResult: result,
          aiConfidence: 0.85, // Placeholder
        ));
      }
    } catch (e) {
      print('❌ Ошибка обработки кадра: $e');
    } finally {
      if (!emit.isDone) {
        emit(state.copyWith(isProcessingFrame: false));
      }
    }
  }

  /// Изменение выбранного цвета
  void _onChangeSelectedColor(
    ChangeSelectedColor event,
    Emitter<ARWallPainterState> emit,
  ) {
    emit(state.copyWith(selectedColor: event.color));
  }

  /// Закрасить стену по точке касания
  void _onPaintWallAtPoint(
    PaintWallAtPoint event,
    Emitter<ARWallPainterState> emit,
  ) {
    final paintedPath = _segmentationService.getPaintedWallPath(
      event.position,
      event.screenWidth,
      event.screenHeight,
    );

    if (paintedPath != null) {
      emit(state.copyWith(paintedWallPath: paintedPath));
    }
  }

  /// Очистка закрашенной стены
  void _onClearPaintedWall(
    ClearPaintedWall event,
    Emitter<ARWallPainterState> emit,
  ) {
    emit(state.copyWith(clearPaintedWallPath: true));
  }

  /// Переключение видимости UI
  void _onToggleUIVisibility(
    ToggleUIVisibility event,
    Emitter<ARWallPainterState> emit,
  ) {
    emit(state.copyWith(isUIVisible: !state.isUIVisible));
  }

  /// Переключение показа сегментации
  void _onToggleSegmentationOverlay(
    ToggleSegmentationOverlay event,
    Emitter<ARWallPainterState> emit,
  ) {
    emit(state.copyWith(
        showSegmentationOverlay: !state.showSegmentationOverlay));
  }

  /// Освобождение ресурсов
  Future<void> _onDispose(
    DisposeARWallPainter event,
    Emitter<ARWallPainterState> emit,
  ) async {
    print('🧹 ARWallPainterBloc: Освобождение ресурсов');

    try {
      await state.cameraController?.dispose();
      _segmentationService.dispose();
    } catch (e) {
      print('❌ Ошибка при освобождении ресурсов: $e');
    }

    emit(ARWallPainterState.initial);
  }

  @override
  Future<void> close() async {
    add(const DisposeARWallPainter());
    return super.close();
  }
}
