import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ArScreen extends StatefulWidget {
  const ArScreen({Key? key}) : super(key: key);

  @override
  _ArScreenState createState() => _ArScreenState();
}

class _ArScreenState extends State<ArScreen> {
  Color _selectedColor = Colors.blue; // Начальный цвет

  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.cyan,
    Colors.pink
  ];

  bool _isUnityReady = false;

  @override
  void initState() {
    super.initState();
  }

  void _onMessageFromUnity(String message) {
    debugPrint('📩 Сообщение от Unity: $message');

    // Простой парсер сообщений "eventType:data"
    final parts = message.split(':');
    if (parts.length >= 2) {
      final eventType = parts.first;
      final data = parts.sublist(1).join(':');

      _handleUnityEvent(eventType, data);
    } else {
      _handleUnityEvent(message, '');
    }
  }

  void _handleUnityEvent(String eventType, String data) {
    switch (eventType) {
      case 'onUnityReady':
        debugPrint('✅ Unity готов к работе!');
        setState(() {
          _isUnityReady = true;
        });
        // Отправляем начальный цвет, как только Unity будет готов
        _sendColorToUnity(_selectedColor);
        break;
      case 'colorChanged':
        debugPrint('🎨 Unity подтвердил изменение цвета: $data');
        break;
      case 'error':
        debugPrint('❌ Ошибка от Unity: $data');
        // Показываем SnackBar с ошибкой
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка в Unity: $data'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      default:
        debugPrint('❔ Неизвестное событие от Unity: $eventType');
    }
  }

  void _sendToUnity(String gameObjectName, String methodName, String message) {
    if (_isUnityReady) {
      sendToUnity(gameObjectName, methodName, message);
      debugPrint(
          '🚀 Отправлено в Unity -> GO: $gameObjectName, Method: $methodName, Msg: $message');
    } else {
      debugPrint('⚠️ Unity не готов. Сообщение не отправлено.');
    }
  }

  void _sendColorToUnity(Color color) {
    // Конвертируем цвет в HEX-строку
    String hexColor =
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    _sendToUnity(
      'FlutterUnityManager',
      'SetPaintColor',
      hexColor,
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Готово'),
              onPressed: () {
                _sendColorToUnity(_selectedColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Покраска (Embed)'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: _showColorPicker,
          ),
        ],
      ),
      body: Stack(
        children: [
          EmbedUnity(
            onMessageFromUnity: _onMessageFromUnity,
          ),
          if (!_isUnityReady)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildColorPalette(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    return Container(
      height: 60,
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _availableColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });

                  _sendColorToUnity(color);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? Colors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
