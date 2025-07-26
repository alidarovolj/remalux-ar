import 'dart:async';
import 'package:flutter/material.dart';
import '../services/performance_profiler.dart';
import '../services/cv_wall_painter_service.dart';

/// Виджет для отображения метрик производительности в реальном времени
class PerformanceOverlay extends StatefulWidget {
  final bool visible;
  final Alignment alignment;

  const PerformanceOverlay({
    Key? key,
    this.visible = false,
    this.alignment = Alignment.topRight,
  }) : super(key: key);

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  Timer? _updateTimer;
  SystemPerformanceMetrics? _systemMetrics;
  int _currentFPS = 0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _startUpdating();
    }
  }

  @override
  void didUpdateWidget(PerformanceOverlay oldWidget) {
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
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _systemMetrics =
              CVWallPainterService.instance.getAverageSystemMetrics();
          _currentFPS = CVWallPainterService.instance.currentFPS;
        });
      }
    });
  }

  void _stopUpdating() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Color _getFPSColor(int fps) {
    if (fps >= 25) return Colors.green;
    if (fps >= 15) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor(int memoryMB) {
    if (memoryMB <= 100) return Colors.green;
    if (memoryMB <= 200) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned(
      top: 50,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: _isExpanded ? _buildExpandedView() : _buildCompactView(),
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // FPS индикатор
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getFPSColor(_currentFPS),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${_currentFPS}fps',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.analytics_outlined,
          color: Colors.white70,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildExpandedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовок
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 4),
            const Text(
              'Performance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // FPS
        _buildMetricRow(
          'FPS',
          '$_currentFPS',
          _getFPSColor(_currentFPS),
        ),

        // Память (если доступна)
        if (_systemMetrics != null) ...[
          _buildMetricRow(
            'RAM',
            '${_systemMetrics!.memoryUsageMB}MB',
            _getMemoryColor(_systemMetrics!.memoryUsageMB),
          ),

          // CPU (если доступен)
          if (_systemMetrics!.cpuUsagePercent > 0)
            _buildMetricRow(
              'CPU',
              '${_systemMetrics!.cpuUsagePercent.toStringAsFixed(1)}%',
              _systemMetrics!.cpuUsagePercent > 70 ? Colors.red : Colors.green,
            ),

          // Время кадра
          _buildMetricRow(
            'Frame',
            '${_systemMetrics!.frameRenderTimeMs}ms',
            _systemMetrics!.frameRenderTimeMs > 20 ? Colors.red : Colors.green,
          ),
        ],

        const SizedBox(height: 4),

        // Кнопки действий
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              Icons.refresh,
              'Reset',
              () {
                // Очистить метрики
                setState(() {
                  _systemMetrics = null;
                  _currentFPS = 0;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              Icons.file_download,
              'Export',
              () {
                // Экспортировать метрики
                final metrics =
                    CVWallPainterService.instance.getPerformanceMetrics();
                debugPrint('Performance metrics exported: $metrics');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Метрики экспортированы в консоль'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
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

/// Миксин для удобного управления отображением метрик производительности
mixin PerformanceOverlayMixin<T extends StatefulWidget> on State<T> {
  bool _showPerformanceOverlay = false;

  bool get showPerformanceOverlay => _showPerformanceOverlay;

  void togglePerformanceOverlay() {
    setState(() {
      _showPerformanceOverlay = !_showPerformanceOverlay;
    });

    if (_showPerformanceOverlay) {
      CVWallPainterService.instance.enableProfiling();
    } else {
      CVWallPainterService.instance.disableProfiling();
    }
  }

  Widget buildPerformanceOverlay() {
    return PerformanceOverlay(
      visible: _showPerformanceOverlay,
    );
  }
}
