import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/ar/domain/providers/ar_provider.dart';

class ArControlsWidget extends ConsumerWidget {
  const ArControlsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arState = ref.watch(arProvider);
    final arNotifier = ref.read(arProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(top: 120, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current color indicator
          _buildCurrentColorIndicator(arState.selectedColor),

          // Control buttons
          Row(
            children: [
              _buildControlButton(
                icon: Icons.flashlight_on,
                label: 'Фонарик',
                onTap: () => arNotifier.toggleFlashlight(),
              ),
              const SizedBox(width: 12),
              _buildControlButton(
                icon: Icons.refresh,
                label: 'Сбросить',
                onTap: () => _showResetDialog(context, arNotifier),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentColorIndicator(Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}'
                  .toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, ArNotifier arNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить окрашивание'),
        content: const Text(
          'Вы уверены, что хотите удалить все изменения и вернуть стены к исходному виду?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              arNotifier.resetWalls();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Стены сброшены к исходному виду'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
