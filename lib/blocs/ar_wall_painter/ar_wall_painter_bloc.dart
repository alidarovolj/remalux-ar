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
    on<ChangeBrushSize>(_onChangeBrushSize);
    on<StartPainting>(_onStartPainting);
    on<ContinuePainting>(_onContinuePainting);
    on<EndPainting>(_onEndPainting);
    on<ClearPaintStrokes>(_onClearPaintStrokes);
    on<UndoLastStroke>(_onUndoLastStroke);
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
      );

      await cameraController.initialize();
      emit(state.copyWith(
        cameraController: cameraController,
        isCameraInitialized: true,
      ));

      print('✅ Камера инициализирована');

      // 2. Инициализация AI модели (без колбэка)
      final aiInitialized = await _segmentationService.initialize();

      if (aiInitialized) {
        emit(state.copyWith(
          isAIModelLoaded: true,
        ));
        print('✅ AI модель загружена');
      } else {
        emit(state.copyWith(
          isAIModelError: true,
          aiErrorMessage: 'Не удалось загрузить AI модель',
        ));
        print('❌ Ошибка загрузки AI модели');
      }

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
      final wallMask = await _segmentationService.processFrameAndGetMask(
        event.cameraImage,
        event.screenWidth,
        event.screenHeight,
      );

      if (wallMask != null && !emit.isDone) {
        emit(state.copyWith(
          wallMask: wallMask,
          aiConfidence: 0.85,
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

  /// Изменение размера кисти
  void _onChangeBrushSize(
    ChangeBrushSize event,
    Emitter<ARWallPainterState> emit,
  ) {
    emit(state.copyWith(brushSize: event.size));
  }

  /// Начало рисования
  void _onStartPainting(
    StartPainting event,
    Emitter<ARWallPainterState> emit,
  ) {
    print('🎨 Начало рисования в точке: ${event.position}');

    // Проверяем, находится ли точка на стене
    if (!_segmentationService.isPointOnWall(event.position, state.wallMask)) {
      print('❌ Точка не на стене - рисование заблокировано');
      return; // Не рисуем если точка не на стене
    }

    print('✅ Точка на стене - создаем новый мазок');
    final newStroke = PaintStroke(
      points: [event.position],
      color: state.selectedColor,
      size: state.brushSize,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      currentStroke: newStroke,
      isPainting: true,
    ));
  }

  /// Продолжение рисования
  void _onContinuePainting(
    ContinuePainting event,
    Emitter<ARWallPainterState> emit,
  ) {
    if (!state.isPainting || state.currentStroke == null) return;

    // Проверяем, находится ли точка на стене
    if (!_segmentationService.isPointOnWall(event.position, state.wallMask)) {
      print('❌ Точка ${event.position} не на стене - пропускаем');
      return; // Не добавляем точку если она не на стене
    }

    print('✅ Добавляем точку ${event.position} к мазку');
    final updatedStroke = state.currentStroke!.copyWith(
      points: [...state.currentStroke!.points, event.position],
    );

    emit(state.copyWith(currentStroke: updatedStroke));
  }

  /// Окончание рисования
  void _onEndPainting(
    EndPainting event,
    Emitter<ARWallPainterState> emit,
  ) {
    if (!state.isPainting || state.currentStroke == null) return;

    final finalStrokes = [...state.paintStrokes, state.currentStroke!];

    emit(state.copyWith(
      paintStrokes: finalStrokes,
      currentStroke: null,
      isPainting: false,
    ));
  }

  /// Очистка всех мазков
  void _onClearPaintStrokes(
    ClearPaintStrokes event,
    Emitter<ARWallPainterState> emit,
  ) {
    emit(state.copyWith(
      paintStrokes: [],
      currentStroke: null,
      isPainting: false,
    ));
  }

  /// Отмена последнего мазка
  void _onUndoLastStroke(
    UndoLastStroke event,
    Emitter<ARWallPainterState> emit,
  ) {
    if (state.paintStrokes.isEmpty) return;

    final newStrokes =
        state.paintStrokes.sublist(0, state.paintStrokes.length - 1);
    emit(state.copyWith(paintStrokes: newStrokes));
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
      await _segmentationService.dispose();
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
