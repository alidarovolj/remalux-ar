import 'dart:async';
import 'package:flutter/material.dart';
import '../services/hybrid_wall_segmentation_service.dart';

/// Виджет для управления режимами сегментации
class SegmentationModeOverlay extends StatefulWidget {
  final bool visible;

  const SegmentationModeOverlay({
    Key? key,
    this.visible = false,
  }) : super(key: key);

  @override
  State<SegmentationModeOverlay> createState() =>
      _SegmentationModeOverlayState();
}

class _SegmentationModeOverlayState extends State<SegmentationModeOverlay> {
  Timer? _updateTimer;
  Map<String, dynamic> _stats = {};
  final HybridWallSegmentationService _hybridService =
      HybridWallSegmentationService();

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _startUpdating();
    }
  }

  @override
  void didUpdateWidget(SegmentationModeOverlay oldWidget) {
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
      _stats = _hybridService.getPerformanceStats();
    });
  }

  Color _getModeColor(SegmentationMode mode) {
    switch (mode) {
      case SegmentationMode.localOnly:
        return Colors.blue;
      case SegmentationMode.roboflowOnly:
        return Colors.green;
      case SegmentationMode.hybrid:
        return Colors.purple;
      case SegmentationMode.adaptive:
        return Colors.orange;
    }
  }

  String _getModeDisplayName(SegmentationMode mode) {
    switch (mode) {
      case SegmentationMode.localOnly:
        return 'Local Only';
      case SegmentationMode.roboflowOnly:
        return 'Roboflow API';
      case SegmentationMode.hybrid:
        return 'Hybrid';
      case SegmentationMode.adaptive:
        return 'Adaptive';
    }
  }

  String _getModeDescription(SegmentationMode mode) {
    switch (mode) {
      case SegmentationMode.localOnly:
        return 'Fast local models only';
      case SegmentationMode.roboflowOnly:
        return 'High-quality cloud API';
      case SegmentationMode.hybrid:
        return 'Best of both worlds';
      case SegmentationMode.adaptive:
        return 'Smart auto-selection';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final currentModeStr = _stats['currentMode'] as String? ?? 'adaptive';
    final currentMode = SegmentationMode.values.firstWhere(
      (mode) => mode.name == currentModeStr,
      orElse: () => SegmentationMode.adaptive,
    );

    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Segmentation Mode',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getModeColor(currentMode),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getModeDisplayName(currentMode).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Режимы сегментации
            Row(
              children: SegmentationMode.values.map((mode) {
                final isSelected = mode == currentMode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () {
                        _hybridService.setMode(mode);
                        _updateStats();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Switched to ${_getModeDisplayName(mode)}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getModeColor(mode).withOpacity(0.8)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _getModeColor(mode)
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getModeIcon(mode),
                              color: isSelected ? Colors.white : Colors.white60,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getModeDisplayName(mode),
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white60,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Описание текущего режима
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getModeColor(currentMode).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getModeDescription(currentMode),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 12),

            // Статистика производительности
            if (_stats.isNotEmpty) _buildPerformanceStats(),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(SegmentationMode mode) {
    switch (mode) {
      case SegmentationMode.localOnly:
        return Icons.smartphone;
      case SegmentationMode.roboflowOnly:
        return Icons.cloud;
      case SegmentationMode.hybrid:
        return Icons.merge_type;
      case SegmentationMode.adaptive:
        return Icons.auto_awesome;
    }
  }

  Widget _buildPerformanceStats() {
    final avgApiLatency = _stats['averageApiLatency'] as double? ?? 0.0;
    final avgLocalLatency = _stats['averageLocalLatency'] as double? ?? 0.0;
    final apiFailures = _stats['consecutiveApiFailures'] as int? ?? 0;
    final isInitialized = _stats['isInitialized'] as bool? ?? false;

    return Column(
      children: [
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Performance',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isInitialized ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isInitialized ? 'READY' : 'INIT',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildLatencyCard(
                'Local',
                avgLocalLatency,
                Colors.blue,
                Icons.smartphone,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLatencyCard(
                'API',
                avgApiLatency,
                Colors.green,
                Icons.cloud,
              ),
            ),
          ],
        ),
        if (apiFailures > 0) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 14),
                const SizedBox(width: 4),
                Text(
                  'API Failures: $apiFailures',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLatencyCard(
      String label, double latency, Color color, IconData icon) {
    final latencyText = latency > 0 ? '${latency.round()}ms' : '--';
    final isGood = latency > 0 && latency < 50;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            latencyText,
            style: TextStyle(
              color: isGood ? Colors.white : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Миксин для управления отображением режимов сегментации
mixin SegmentationModeOverlayMixin<T extends StatefulWidget> on State<T> {
  bool _showSegmentationMode = false;

  bool get showSegmentationMode => _showSegmentationMode;

  void toggleSegmentationMode() {
    setState(() {
      _showSegmentationMode = !_showSegmentationMode;
    });
  }

  Widget buildSegmentationModeOverlay() {
    return SegmentationModeOverlay(
      visible: _showSegmentationMode,
    );
  }
}
