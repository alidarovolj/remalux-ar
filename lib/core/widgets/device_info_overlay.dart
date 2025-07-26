import 'dart:async';
import 'package:flutter/material.dart';
import '../services/device_capability_detector.dart';

/// Виджет для отображения информации об устройстве и рекомендаций
class DeviceInfoOverlay extends StatefulWidget {
  final bool visible;

  const DeviceInfoOverlay({
    Key? key,
    this.visible = false,
  }) : super(key: key);

  @override
  State<DeviceInfoOverlay> createState() => _DeviceInfoOverlayState();
}

class _DeviceInfoOverlayState extends State<DeviceInfoOverlay> {
  DeviceCapabilities? _capabilities;
  bool _isLoading = false;
  final DeviceCapabilityDetector _detector = DeviceCapabilityDetector();

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _loadCapabilities();
    }
  }

  @override
  void didUpdateWidget(DeviceInfoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible && _capabilities == null) {
      _loadCapabilities();
    }
  }

  Future<void> _loadCapabilities() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final capabilities = await _detector.getDeviceCapabilities();
      if (mounted) {
        setState(() {
          _capabilities = capabilities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getPerformanceColor(DevicePerformanceTier tier) {
    switch (tier) {
      case DevicePerformanceTier.highEnd:
        return Colors.green;
      case DevicePerformanceTier.midRange:
        return Colors.orange;
      case DevicePerformanceTier.lowEnd:
        return Colors.red;
    }
  }

  Color _getGPUColor(GPUArchitecture gpu) {
    switch (gpu) {
      case GPUArchitecture.appleGPU:
        return Colors.blue;
      case GPUArchitecture.adreno:
        return Colors.green;
      case GPUArchitecture.mali:
        return Colors.orange;
      case GPUArchitecture.tegra:
        return Colors.purple;
      case GPUArchitecture.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned(
      top: 200,
      right: 16,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: _isLoading
            ? _buildLoading()
            : _capabilities != null
                ? _buildDeviceInfo()
                : _buildError(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(strokeWidth: 2),
        SizedBox(height: 8),
        Text(
          'Analyzing device...',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 24),
        const SizedBox(height: 8),
        const Text(
          'Failed to detect device capabilities',
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loadCapabilities,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white24,
            minimumSize: const Size(60, 30),
          ),
          child: const Text(
            'Retry',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    final caps = _capabilities!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовок
        Row(
          children: [
            const Icon(Icons.phone_android, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            const Text(
              'Device Info',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _detector.clearCache();
                _loadCapabilities();
              },
              child: const Icon(Icons.refresh, color: Colors.white54, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Модель устройства
        _buildInfoRow('Device', caps.deviceModel, null),
        _buildInfoRow('OS', caps.osVersion, null),

        const SizedBox(height: 8),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),

        // Performance Tier
        _buildInfoRow(
          'Tier',
          caps.performanceTier.name.toUpperCase(),
          _getPerformanceColor(caps.performanceTier),
        ),

        // GPU информация
        _buildInfoRow(
          'GPU',
          caps.gpuArchitecture.name.toUpperCase(),
          _getGPUColor(caps.gpuArchitecture),
        ),

        // Память
        _buildInfoRow(
          'RAM',
          '${caps.totalRAMMB}MB (${caps.availableRAMMB}MB free)',
          caps.availableRAMMB > 4096 ? Colors.green : Colors.orange,
        ),

        const SizedBox(height: 8),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),

        // Поддержка делегатов
        Row(
          children: [
            _buildCapabilityChip(
              'NNAPI',
              caps.supportsNNAPI,
            ),
            const SizedBox(width: 4),
            _buildCapabilityChip(
              'CoreML',
              caps.supportsCoreML,
            ),
            const SizedBox(width: 4),
            _buildCapabilityChip(
              'GPU',
              caps.supportsGPUDelegate,
            ),
          ],
        ),

        const SizedBox(height: 8),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),

        // Рекомендации
        _buildRecommendations(caps),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 10,
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityChip(String label, bool supported) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: supported
            ? Colors.green.withOpacity(0.7)
            : Colors.red.withOpacity(0.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecommendations(DeviceCapabilities caps) {
    final modelNames = ['Standard', 'Specialized', 'Mobile'];
    final recommendedModel = modelNames[caps.recommendedModelIndex];
    final settings = caps.optimizationSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),

        // Рекомендованная модель
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Model: $recommendedModel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Delegate: ${settings['preferredDelegate']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
              Text(
                'Target FPS: ${settings['targetFPS']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Дополнительные настройки
        Text(
          'Threads: ${settings['numThreads']} • '
          'Precision: ${settings['precision']} • '
          'GPU: ${settings['useGPU'] ? 'Yes' : 'No'}',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

/// Миксин для управления отображением информации об устройстве
mixin DeviceInfoOverlayMixin<T extends StatefulWidget> on State<T> {
  bool _showDeviceInfo = false;

  bool get showDeviceInfo => _showDeviceInfo;

  void toggleDeviceInfo() {
    setState(() {
      _showDeviceInfo = !_showDeviceInfo;
    });
  }

  Widget buildDeviceInfoOverlay() {
    return DeviceInfoOverlay(
      visible: _showDeviceInfo,
    );
  }
}
