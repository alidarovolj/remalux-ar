import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import '../widgets/unity_color_palette_widget.dart';
import '../../domain/models/unity_models.dart';
import '../../domain/services/unity_color_manager.dart';

class UnityArPage extends StatefulWidget {
  final Color? initialColor;

  const UnityArPage({super.key, this.initialColor});

  @override
  State<UnityArPage> createState() => _UnityArPageState();
}

class _UnityArPageState extends State<UnityArPage> with WidgetsBindingObserver {
  final UnityColorManager _unityManager = UnityColorManager();

  // Состояние UI
  List<UnityClass> _availableClasses = [];
  UnityClass? _selectedClass;
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
            _selectedClass = _availableClasses.first;
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
            _selectedClass = _availableClasses.first;
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
      if (mounted) {
        setState(() {
          _selectedClass = clickedClass;
        });
      }
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
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // Unity AR Widget
          if (_errorMessage == null)
            Container(
              child: EmbedUnity(
                onMessageFromUnity: (message) {
                  _unityManager.handleUnityMessage(message);
                },
              ),
            ),

          // Loading Overlay
          if (_isLoading) _buildLoadingOverlay(),

          // Error State
          if (_errorMessage != null) _buildErrorState(),

          // UI Controls - показываем когда Unity готов или принудительно через 8 секунд
          if (_isUnityReady && _errorMessage == null) ...[
            // Инструкция
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _buildInstructionCard(),
            ),

            // Убрали список классов - работаем только со стенами

            // Цветовая палитра (показываем всегда если Unity готов)
            Positioned(
              bottom: 140, // Увеличили отступ снизу для новой высоты палитры
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Информация о текущем режиме
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Покраска стен',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Палитра цветов
                  UnityColorPaletteWidget(
                    onColorSelected: _onColorSelected,
                    selectedColor: _selectedColor,
                    isEnabled: true, // Всегда доступна
                  ),
                ],
              ),
            ),

            // Кнопки управления
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: _buildActionButtons(),
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
        child: Text(
          'AR Окрашивание 2.0',
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
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isUnityReady
                ? () {
                    _unityManager.requestAvailableClasses();
                  }
                : null,
          ),
        ),
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

  Widget _buildInstructionCard() {
    String instruction;
    IconData icon;
    Color color;

    if (!_isUnityReady) {
      instruction = 'Загрузка AR...';
      icon = Icons.hourglass_bottom;
      color = Colors.orange;
    } else if (_availableClasses.isEmpty) {
      instruction = 'Наведите камеру на комнату для поиска объектов';
      icon = Icons.camera_alt;
      color = Colors.blue;
    } else if (_selectedClass == null) {
      instruction = 'Выберите объект для покраски из списка ниже';
      icon = Icons.touch_app;
      color = Colors.green;
    } else {
      instruction = 'Выберите цвет для: ${_selectedClass!.className}';
      icon = Icons.palette;
      color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUnityReady
                ? () {
                    _unityManager.showAllClasses();
                  }
                : null,
            icon: const Icon(Icons.visibility),
            label: const Text('Показать все'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUnityReady
                ? () {
                    setState(() {
                      _selectedClass = null;
                      _selectedColor = null;
                    });
                    _unityManager.resetColors();
                    _showSnackBar('Цвета сброшены', isSuccess: true);
                  }
                : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Сбросить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как использовать AR 2.0'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Сканирование комнаты',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'Наведите камеру на разные объекты в комнате. Unity автоматически определит стены, пол, мебель и другие объекты.'),
              SizedBox(height: 16),
              Text(
                '2. Выбор объекта',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'Из списка обнаруженных объектов выберите тот, который хотите покрасить.'),
              SizedBox(height: 16),
              Text(
                '3. Выбор цвета',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'Используйте цветовую палитру для выбора подходящего цвета краски.'),
              SizedBox(height: 16),
              Text(
                '4. Просмотр результата',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                  'AR покажет в реальном времени, как будет выглядеть объект в выбранном цвете.'),
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
