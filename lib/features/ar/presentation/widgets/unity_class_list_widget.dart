import 'package:flutter/material.dart';
import '../../domain/models/unity_models.dart';

class UnityClassListWidget extends StatelessWidget {
  final List<UnityClass> classes;
  final Function(UnityClass) onClassSelected;
  final UnityClass? selectedClass;
  final bool isLoading;

  const UnityClassListWidget({
    super.key,
    required this.classes,
    required this.onClassSelected,
    this.selectedClass,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  const Text(
                    'Объекты для покраски:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  if (!isLoading && classes.isNotEmpty)
                    Text(
                      '${classes.length} найдено',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Список классов
              Expanded(
                child: _buildClassList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassList(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Text(
          'Загрузка объектов...',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Объекты не найдены',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final unityClass = classes[index];
        final isSelected = selectedClass?.classId == unityClass.classId;

        return _buildClassItem(context, unityClass, isSelected);
      },
    );
  }

  Widget _buildClassItem(
      BuildContext context, UnityClass unityClass, bool isSelected) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          onClassSelected(unityClass);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Цветовой индикатор
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: unityClass.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: unityClass.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),

              const SizedBox(height: 6),

              // Название класса
              Text(
                _formatClassName(unityClass.className),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.blue.shade800 : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ID класса
              Text(
                'ID: ${unityClass.classId}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Форматирует название класса для отображения
  String _formatClassName(String className) {
    // Преобразуем первую букву в заглавную
    if (className.isEmpty) return className;

    // Замена английских названий на русские
    final translations = {
      'wall': 'Стена',
      'floor': 'Пол',
      'ceiling': 'Потолок',
      'door': 'Дверь',
      'window': 'Окно',
      'furniture': 'Мебель',
      'bed': 'Кровать',
      'chair': 'Стул',
      'table': 'Стол',
      'cabinet': 'Шкаф',
      'shelf': 'Полка',
      'person': 'Человек',
      'plant': 'Растение',
      'pillow': 'Подушка',
      'picture': 'Картина',
      'mirror': 'Зеркало',
      'book': 'Книга',
      'lamp': 'Лампа',
      'curtain': 'Штора',
      'rug': 'Ковер',
      'towel': 'Полотенце',
    };

    final lowerCase = className.toLowerCase();
    if (translations.containsKey(lowerCase)) {
      return translations[lowerCase]!;
    }

    // Если перевода нет, просто делаем первую букву заглавной
    return className[0].toUpperCase() + className.substring(1);
  }
}
