import 'dart:async';
import 'package:flutter/material.dart';
import '../services/model_manager.dart';

/// Виджет для отображения статистики использования памяти моделей
class MemoryStatsOverlay extends StatefulWidget {
  final bool visible;
  final Alignment alignment;

  const MemoryStatsOverlay({
    Key? key,
    this.visible = false,
    this.alignment = Alignment.topLeft,
  }) : super(key: key);

  @override
  State<MemoryStatsOverlay> createState() => _MemoryStatsOverlayState();
}

class _MemoryStatsOverlayState extends State<MemoryStatsOverlay> {
  Timer? _updateTimer;
  Map<String, dynamic> _memoryStats = {};
  final ModelManager _modelManager = ModelManager();

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _startUpdating();
    }
  }

  @override
  void didUpdateWidget(MemoryStatsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _startUpdating();
      } else {
        _stopUpdating();
      }
    }
  }

  @override
  void dispose() {
    _stopUpdating();
    super.dispose();
  }

  void _startUpdating() {
    _updateStats();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateStats();
      }
    });
  }

  void _stopUpdating() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  void _updateStats() {
    setState(() {
      _memoryStats = _modelManager.getMemoryStats();
    });
  }

  Color _getMemoryColor(int totalSizeMB) {
    if (totalSizeMB <= 10) return Colors.green;
    if (totalSizeMB <= 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final totalModels = _memoryStats['totalModels'] ?? 0;
    final totalSizeMB = _memoryStats['totalSizeMB'] ?? 0;
    final maxModels = _memoryStats['maxModels'] ?? 0;
    final modelDetails = _memoryStats['modelDetails'] as List? ?? [];

    return Positioned(
      top: 120,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.memory,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Memory Stats',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Общая статистика
            _buildStatRow(
              'Models',
              '$totalModels/$maxModels',
              totalModels >= maxModels ? Colors.orange : Colors.green,
            ),

            _buildStatRow(
              'Total',
              '${totalSizeMB}MB',
              _getMemoryColor(totalSizeMB),
            ),

            // Детали по моделям
            if (modelDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),
              ...modelDetails.map((model) => _buildModelRow(model)).toList(),
            ],

            // Кнопки действий
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  Icons.refresh,
                  'GC',
                  () async {
                    await _modelManager.forceGarbageCollection();
                    _updateStats();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сборка мусора выполнена'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  Icons.clear_all,
                  'Unload All',
                  () async {
                    await _modelManager.unloadAllModels();
                    _updateStats();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Все модели выгружены'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelRow(Map<String, dynamic> model) {
    final name = model['name'] as String? ?? 'Unknown';
    final sizeMB = model['sizeMB'] as int? ?? 0;
    final delegate = model['delegate'] as String? ?? 'CPU';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Название модели (сокращенное)
          SizedBox(
            width: 80,
            child: Text(
              name.length > 10 ? '${name.substring(0, 10)}...' : name,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),

          // Размер
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '${sizeMB}MB',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Делегат
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: delegate == 'GPU' ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              delegate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            color: Colors.white70,
            size: 12,
          ),
        ),
      ),
    );
  }
}

/// Миксин для управления отображением статистики памяти
mixin MemoryStatsOverlayMixin<T extends StatefulWidget> on State<T> {
  bool _showMemoryStats = false;

  bool get showMemoryStats => _showMemoryStats;

  void toggleMemoryStats() {
    setState(() {
      _showMemoryStats = !_showMemoryStats;
    });
  }

  Widget buildMemoryStatsOverlay() {
    return MemoryStatsOverlay(
      visible: _showMemoryStats,
    );
  }
}
