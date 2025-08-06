import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/ar/domain/providers/ar_provider.dart';
import 'package:remalux_ar/features/ar/presentation/widgets/color_palette_widget.dart';
import 'package:remalux_ar/features/ar/presentation/widgets/ar_controls_widget.dart';
import 'package:remalux_ar/features/ar/presentation/widgets/ar_loading_widget.dart';

class ArPage extends ConsumerStatefulWidget {
  final Color? initialColor;

  const ArPage({Key? key, this.initialColor}) : super(key: key);

  @override
  ConsumerState<ArPage> createState() => _ArPageState();
}

class _ArPageState extends ConsumerState<ArPage> {
  @override
  void initState() {
    super.initState();
    // Устанавливаем начальный цвет если он был передан
    if (widget.initialColor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(arProvider.notifier).selectColor(widget.initialColor!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final arState = ref.watch(arProvider);
    final arNotifier = ref.read(arProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Unity AR Widget
          if (arState.errorMessage == null)
            Container(
              child: EmbedUnity(
                onMessageFromUnity: (message) {
                  _handleUnityMessage(message, arNotifier);
                },
              ),
            ),

          // Loading Overlay
          if (arState.isLoading) const ArLoadingWidget(),

          // Error State
          if (arState.errorMessage != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка AR',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      arState.errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Вернуться'),
                    ),
                  ],
                ),
              ),
            ),

          // UI Controls
          if (arState.isUnityLoaded && arState.errorMessage == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ArControlsWidget(),
            ),

          // Color Palette
          if (arState.isUnityLoaded && arState.errorMessage == null)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: ColorPaletteWidget(),
            ),

          // Paint Toggle Button
          if (arState.isUnityLoaded && arState.errorMessage == null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _buildPaintToggleButton(arState, arNotifier),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'AR Окрашивание',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showHelpDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPaintToggleButton(ArState arState, ArNotifier arNotifier) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(30),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            arNotifier.setPaintingMode(!arState.isPainting);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: arState.isPainting
                    ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
                    : [Colors.grey.shade700, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  arState.isPainting ? Icons.brush : Icons.brush_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  arState.isPainting
                      ? 'Рисование включено'
                      : 'Включить рисование',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleUnityMessage(dynamic message, ArNotifier arNotifier) {
    print('📨 Сообщение от Unity: $message');

    try {
      // Обработка сообщений от Unity
      if (message is String) {
        if (message.contains('error')) {
          print('❌ Unity сообщает об ошибке: $message');
          arNotifier.setError('Ошибка в Unity: $message');
        } else if (message.contains('ready') || message.contains('loaded') || message.contains('onUnityReady')) {
          print('✅ Unity готов к работе, сообщение: $message');
          // Убеждаемся что Unity помечен как загруженный
          arNotifier.setLoading(false);
        } else if (message.contains('colorChanged')) {
          print('🎨 Unity подтверждает изменение цвета: $message');
        } else {
          print('ℹ️ Неизвестное сообщение от Unity: $message');
        }
      }
    } catch (e) {
      print('❌ Ошибка обработки сообщения от Unity: $e');
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как использовать AR'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Наведите камеру на стену',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('Убедитесь, что стена хорошо освещена и видна камере.'),
              SizedBox(height: 16),
              Text(
                '2. Выберите цвет',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('Используйте палитру внизу экрана для выбора цвета краски.'),
              SizedBox(height: 16),
              Text(
                '3. Включите рисование',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'Нажмите кнопку "Включить рисование" чтобы начать окрашивание.'),
              SizedBox(height: 16),
              Text(
                '4. Наслаждайтесь результатом',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('AR покажет как будет выглядеть стена в выбранном цвете.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}
