import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/home/domain/providers/colors_provider.dart';
import '../widgets/ar_color_bottom_sheet.dart';
import '../../domain/models/unity_models.dart';
import '../../domain/services/unity_color_manager.dart';

class UnityArPage extends ConsumerStatefulWidget {
  final Color? initialColor;

  const UnityArPage({super.key, this.initialColor});

  @override
  ConsumerState<UnityArPage> createState() => _UnityArPageState();
}

class _UnityArPageState extends ConsumerState<UnityArPage>
    with WidgetsBindingObserver {
  final UnityColorManager _unityManager = UnityColorManager();

  // Состояние UI
  List<UnityClass> _availableClasses = [];
  Color? _selectedColor;
  bool _isUnityReady = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupUnityCallbacks();
    _selectedColor = widget.initialColor;

    // Таймер для принудительного убирания загрузки
    _startUnityInitTimer();
  }

  void _startUnityInitTimer() {
    // Через 3 секунды тестируем коммуникацию
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _unityManager.requestAvailableClasses();
      }
    });

    // Через 8 секунд принудительно убираем загрузку если Unity не ответил
    Future.delayed(const Duration(seconds: 8), () {
      if (_isLoading && mounted) {
        setState(() {
          _isLoading = false;
          _isUnityReady = true;
          // Создаем класс стены по умолчанию
          if (_availableClasses.isEmpty) {
            _availableClasses = [
              const UnityClass(
                  classId: 0, className: 'wall', currentColor: '#0074D9'),
            ];
            // Всегда работаем со стенами
          }
        });
        // Принудительно ставим Unity в состояние "готов"
        _unityManager.forceReady();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unityManager.dispose();
    super.dispose();
  }

  void _setupUnityCallbacks() {
    _unityManager.onUnityReady = () {
      if (mounted) {
        setState(() {
          _isUnityReady = true;
          _isLoading = false;
          _errorMessage = null;
          // Инициализируем стену как единственный класс
          if (_availableClasses.isEmpty) {
            _availableClasses = [
              const UnityClass(
                  classId: 0, className: 'wall', currentColor: '#0074D9'),
            ];
            // Всегда работаем со стенами
          }
        });
      }
    };

    _unityManager.onClassesReceived = (classes) {
      if (mounted) {
        setState(() {
          _availableClasses = classes;
        });
      }
    };

    _unityManager.onClassClicked = (clickedClass) {
      // Всегда работаем только со стенами, игнорируем клики по классам
    };

    _unityManager.onColorChanged = (colorEvent) {
      // Показываем успешное уведомление
      _showSnackBar('Цвет применен к ${colorEvent.className}', isSuccess: true);
    };

    _unityManager.onError = (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error;
        });
        _showSnackBar(error, isSuccess: false);
      }
    };

    // Инициализируем менеджер
    _unityManager.initialize();
  }

  // Убрали выбор класса - работаем только со стенами

  void _onColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
    });

    // Всегда применяем цвет к стенам (classId: 0)
    _unityManager.setClassColor(0, color);
  }

  void _showColorBottomSheet({int? mainColorId, String? categoryName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArColorBottomSheet(
        onColorSelected: _onColorSelected,
        selectedColor: _selectedColor,
        preselectedMainColorId: mainColorId,
        categoryName: categoryName,
      ),
    );
  }

  String _getImageName(String colorName) {
    final colorKey = colorName.toLowerCase();
    switch (colorKey) {
      case 'grey':
        return 'grey.png';
      case 'blue':
        return 'Blue.png';
      case 'pink':
        return 'Pink.png';
      case 'orange':
        return 'Coral.png';
      case 'purple':
        return 'Purple.png';
      case 'brown':
        return 'Brown.png';
      case 'white':
        return 'aqua.png';
      case 'green':
        return 'Green.png';
      case 'yellow':
        return 'Yellow.png';
      default:
        return 'grey.png';
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 280, left: 16, right: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Черный фон для всего экрана
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Unity AR Widget на весь экран
          if (_errorMessage == null)
            EmbedUnity(
              onMessageFromUnity: (message) {
                _unityManager.handleUnityMessage(message);
              },
            ),

          // Черная маска с прозрачным окном поверх камеры
          if (_errorMessage == null)
            Positioned.fill(
              child: CustomPaint(
                painter: _CameraMaskPainter(),
              ),
            ),

          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(),

          // Error State
          if (_errorMessage != null) _buildErrorState(),

          // UI Controls - показываем когда Unity готов или принудительно через 8 секунд
          if (_isUnityReady && _errorMessage == null) ...[
            // Убрали список классов - работаем только со стенами

            // Скролл основных цветов снизу внутри рамки
            Positioned(
              bottom: 60, // +20 для новой рамки снизу
              left: 42, // +10 для новых отступов
              right: 42, // +10 для новых отступов
              child: Container(
                height: 80,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(25),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: ref.watch(colorsProvider).when(
                      data: (colors) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: colors
                              .map((color) => GestureDetector(
                                    onTap: () => _showColorBottomSheet(
                                      mainColorId: color.id,
                                      categoryName: color.title['ru'] ??
                                          color.title['en'] ??
                                          '',
                                    ),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'lib/core/assets/images/colors/${_getImageName(color.title['en']?.toLowerCase() ?? '')}',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      error: (error, stack) => const Center(
                        child: Text(
                          'Ошибка загрузки',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
              ),
            ),
          ],
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
          color: Colors.black.withValues(alpha: 0.5),
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
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SvgPicture.asset(
          'lib/core/assets/icons/logo.svg',
          height: 32,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Инициализация AR...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Пожалуйста, подождите',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                    _setupUnityCallbacks();
                  },
                  child: const Text('Повторить'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Вернуться'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как использовать Remalux Visualizer'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Наведите камеру на стены',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'Направьте камеру устройства на стены комнаты для активации AR технологии.'),
              SizedBox(height: 16),
              Text(
                '2. Выберите цвет краски',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'Используйте палитру цветов с RAL кодами для выбора подходящего оттенка Remalux.'),
              SizedBox(height: 16),
              Text(
                '3. Просматривайте результат',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'AR покажет в реальном времени, как будут выглядеть ваши стены в выбранном цвете краски Remalux.'),
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

/// CustomPainter для создания черной маски с прозрачным окном
class _CameraMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Создаем полный черный прямоугольник
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Создаем прямоугольник для прозрачного окна
    const margin = EdgeInsets.only(left: 26, right: 26, top: 36, bottom: 36);
    final windowRect = Rect.fromLTWH(
      margin.left,
      margin.top,
      size.width - margin.left - margin.right,
      size.height - margin.top - margin.bottom,
    );

    // Создаем скругленный прямоугольник для окна
    final windowRRect = RRect.fromRectAndRadius(
      windowRect,
      const Radius.circular(16),
    );

    // Создаем путь с вырезом
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(windowRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
