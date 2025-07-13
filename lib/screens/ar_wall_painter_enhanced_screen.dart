import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

// AR Plugin imports
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';

import 'package:remalux_ar/blocs/ar_wall_painter/ar_wall_painter_bloc.dart';
import 'package:remalux_ar/blocs/ar_wall_painter/ar_wall_painter_event.dart';
import 'package:remalux_ar/blocs/ar_wall_painter/ar_wall_painter_state.dart';

/// Enhanced AR Wall Painter с поддержкой AR plane detection
class ARWallPainterEnhancedScreen extends StatefulWidget {
  const ARWallPainterEnhancedScreen({super.key});

  @override
  State<ARWallPainterEnhancedScreen> createState() =>
      _ARWallPainterEnhancedScreenState();
}

class _ARWallPainterEnhancedScreenState
    extends State<ARWallPainterEnhancedScreen> {
  late ARWallPainterBloc _bloc;

  // AR Managers
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  ARLocationManager? _arLocationManager;

  // AR State
  final List<ARPlaneAnchor> _detectedPlanes = [];
  bool _isPlaneDetectionEnabled = true;

  // UI State
  Color _selectedColor = Colors.blue;
  bool _isArReady = false;

  // Available colors for painting
  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _bloc = ARWallPainterBloc();
    _bloc.add(const InitializeARWallPainter());
  }

  @override
  void dispose() {
    _arSessionManager?.dispose();
    _bloc.add(const DisposeARWallPainter());
    _bloc.close();
    super.dispose();
  }

  /// Callback when AR view is created
  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    setState(() {
      _arSessionManager = arSessionManager;
      _arObjectManager = arObjectManager;
      _arAnchorManager = arAnchorManager;
      _arLocationManager = arLocationManager;
      _isArReady = true;
    });

    // Configure AR session
    _setupARSession();

    debugPrint('✅ AR Session созданa с поддержкой plane detection');
  }

  /// Configure AR session with plane detection
  void _setupARSession() {
    if (_arSessionManager == null) return;

    // Enable plane detection callbacks
    _arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTap;

    debugPrint('🎯 AR plane detection настроен');
  }

  /// Handle tap on detected plane or point
  void _onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) {
    if (hitTestResults.isEmpty) return;

    final hitResult = hitTestResults.first;

    // Check if hit result is on a plane
    if (hitResult.type == ARHitTestResultType.plane) {
      _handlePlaneHit(hitResult);
    } else {
      _handlePointHit(hitResult);
    }
  }

  /// Handle hit on detected plane
  void _handlePlaneHit(ARHitTestResult hitResult) {
    debugPrint('🎯 Попадание в плоскость: ${hitResult.worldTransform}');

    // Create anchor on the plane
    final anchor = ARPlaneAnchor(
      transformation: hitResult.worldTransform,
      name: "wall_anchor_${DateTime.now().millisecondsSinceEpoch}",
    );

    _addWallAnchor(anchor, _selectedColor);
  }

  /// Handle hit on arbitrary point
  void _handlePointHit(ARHitTestResult hitResult) {
    debugPrint('🎯 Попадание в точку: ${hitResult.worldTransform}');

    // For non-plane hits, we can still add painting
    final anchor = ARPlaneAnchor(
      transformation: hitResult.worldTransform,
      name: "point_anchor_${DateTime.now().millisecondsSinceEpoch}",
    );

    _addWallAnchor(anchor, _selectedColor);
  }

  /// Add wall anchor with painting visualization
  void _addWallAnchor(ARPlaneAnchor anchor, Color color) async {
    if (_arAnchorManager == null || _arObjectManager == null) return;

    try {
      // Add anchor to AR session
      final success = await _arAnchorManager!.addAnchor(anchor);

      if (success == true) {
        // Create visual node for the painted area
        final node = ARNode(
          type: NodeType.webGLB,
          uri: _generatePaintedWallGLB(color),
          scale: vector.Vector3(0.1, 0.1, 0.01), // Thin wall painting
          position: vector.Vector3(0, 0, 0),
          rotation: vector.Vector4(0, 0, 0, 1),
        );

        // Attach node to anchor
        final nodeSuccess =
            await _arObjectManager!.addNode(node, planeAnchor: anchor);

        if (nodeSuccess == true) {
          setState(() {
            _detectedPlanes.add(anchor);
          });

          debugPrint('✅ Стена покрашена якорем: ${anchor.name}');

          // Trigger haptic feedback
          _triggerHapticFeedback();
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка добавления якоря: $e');
    }
  }

  /// Generate GLB content for painted wall (simplified)
  String _generatePaintedWallGLB(Color color) {
    // For demo purposes, we'll use a simple colored plane
    // In production, this would generate actual GLB content
    return "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/BoxAnimated/glTF-Binary/BoxAnimated.glb";
  }

  /// Trigger haptic feedback
  void _triggerHapticFeedback() {
    // Add haptic feedback when painting is applied
    // Implementation depends on platform
  }

  /// Clear all painted walls
  void _clearAllPaintedWalls() {
    if (_arAnchorManager == null) return;

    for (final anchor in _detectedPlanes) {
      _arAnchorManager!.removeAnchor(anchor);
    }

    setState(() {
      _detectedPlanes.clear();
    });

    debugPrint('🧹 Все покрашенные стены очищены');
  }

  /// Toggle plane detection visualization
  void _togglePlaneDetection() {
    setState(() {
      _isPlaneDetectionEnabled = !_isPlaneDetectionEnabled;
    });

    debugPrint(
        '🔄 Детекция плоскостей: ${_isPlaneDetectionEnabled ? "включена" : "выключена"}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ARWallPainterBloc, ARWallPainterState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // AR View with plane detection
                _buildARView(),

                // UI Overlay
                _buildUIOverlay(state),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build AR View with plane detection
  Widget _buildARView() {
    return ARView(
      onARViewCreated: _onARViewCreated,
      planeDetectionConfig:
          PlaneDetectionConfig.vertical, // Detect vertical planes (walls)
      showPlatformType: false,
    );
  }

  /// Build UI overlay
  Widget _buildUIOverlay(ARWallPainterState state) {
    return SafeArea(
      child: Column(
        children: [
          // Top controls
          _buildTopControls(),

          const Spacer(),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  /// Build top controls
  Widget _buildTopControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _buildControlButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),

          // AR status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isArReady ? Icons.camera_alt : Icons.camera_alt_outlined,
                  color: _isArReady ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isArReady ? 'AR Готов' : 'Инициализация AR...',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          // Plane detection toggle
          _buildControlButton(
            icon: _isPlaneDetectionEnabled ? Icons.grid_on : Icons.grid_off,
            onPressed: _togglePlaneDetection,
          ),
        ],
      ),
    );
  }

  /// Build bottom controls
  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info panel
          if (_isArReady) _buildInfoPanel(),

          const SizedBox(height: 16),

          // Color palette
          _buildColorPalette(),

          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Build info panel
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Плоскости', '${_detectedPlanes.length}'),
          _buildInfoItem('Покрашено', '${_detectedPlanes.length}'),
          _buildInfoItem(
              'Цвет',
              _selectedColor.value
                  .toRadixString(16)
                  .substring(2)
                  .toUpperCase()),
        ],
      ),
    );
  }

  /// Build info item
  Widget _buildInfoItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Build color palette
  Widget _buildColorPalette() {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _availableColors.map((color) {
          final isSelected = color == _selectedColor;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.palette,
          label: 'Цвет',
          onPressed: () {
            // Color picker could be shown here
          },
        ),
        _buildActionButton(
          icon: Icons.clear,
          label: 'Очистить',
          onPressed: _clearAllPaintedWalls,
        ),
        _buildActionButton(
          icon: Icons.touch_app,
          label: 'Покрасить',
          onPressed: () {
            // Info about tapping on walls
            _showPaintingInstructions();
          },
        ),
      ],
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Show painting instructions
  void _showPaintingInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как покрасить стену'),
        content: const Text(
          'Наведите камеру на стену и коснитесь экрана в месте, где хотите нанести краску. '
          'AR автоматически детектирует плоскости стен для точного позиционирования.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}
