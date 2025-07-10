import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARWallPainterScreen extends StatefulWidget {
  const ARWallPainterScreen({super.key});

  @override
  State<ARWallPainterScreen> createState() => _ARWallPainterScreenState();
}

class _ARWallPainterScreenState extends State<ARWallPainterScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  Color _selectedColor = const Color(0xFFF44336); // Красный по умолчанию

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Wall Painter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearAll,
          )
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.vertical,
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath:
          "assets/ml/triangle.png", // Можно заменить на более подходящую текстуру
      showWorldOrigin: false,
      handleTaps: true,
    );
    arObjectManager.onInitialize();

    arSessionManager.onPlaneOrPointTap = onPlaneOrPointTap;
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hits) async {
    // TODO: Раскомментировать и исправить после проверки базовой работоспособности
    // final hit = hits.firstWhere(
    //   (hit) => hit.type == ARHitTestResultType.plane,
    //   orElse: () => hits.first,
    // );

    // final newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    // final bool? didAddAnchor = await arAnchorManager.addAnchor(newAnchor);

    // if (didAddAnchor != null && didAddAnchor) {
    //   anchors.add(newAnchor);

    //   // Создаем узел с моделью "мазка"
    //   final newNode = ARNode(
    //     type: NodeType.webGLB, // Используем webGLB, т.к. localGLTF2 может быть не поддержан
    //     uri:
    //         "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb", // Загрузим простую сферу для теста
    //     scale: vector.Vector3(0.05, 0.05, 0.01), // Делаем мазок плоским
    //     transformation: newAnchor.transformation,
    //     data: {
    //       'color': [
    //         _selectedColor.red / 255.0,
    //         _selectedColor.green / 255.0,
    //         _selectedColor.blue / 255.0,
    //         _selectedColor.alpha / 255.0,
    //       ]
    //     },
    //   );

    //   final bool? didAddNode = await arObjectManager.addNode(newNode);
    //   if (didAddNode != null && didAddNode) {
    //     nodes.add(newNode);
    //   } else {
    //     arSessionManager.onError("Adding node failed");
    //   }
    // } else {
    //   arSessionManager.onError("Adding anchor failed");
    // }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  void _clearAll() {
    for (final node in nodes) {
      arObjectManager.removeNode(node);
    }
    for (final anchor in anchors) {
      arAnchorManager.removeAnchor(anchor);
    }
    nodes.clear();
    anchors.clear();
  }
}
