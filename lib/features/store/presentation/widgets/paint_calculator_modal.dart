import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';

class PaintCalculatorModal extends StatefulWidget {
  final double expense;
  final String selectedWeight;

  const PaintCalculatorModal({
    super.key,
    required this.expense,
    required this.selectedWeight,
  });

  @override
  State<PaintCalculatorModal> createState() => _PaintCalculatorModalState();
}

class _PaintCalculatorModalState extends State<PaintCalculatorModal> {
  final widthController = TextEditingController(text: '6');
  final heightController = TextEditingController(text: '6');
  final layersController = TextEditingController(text: '1');

  double get totalArea {
    final width = double.tryParse(widthController.text) ?? 0;
    final height = double.tryParse(heightController.text) ?? 0;
    return width * height;
  }

  double get requiredPaint {
    final layers = double.tryParse(layersController.text) ?? 0;
    return (totalArea * widget.expense * layers) / 1000; // Convert g to kg
  }

  int get requiredPackages {
    final selectedWeight = double.tryParse(widget.selectedWeight) ?? 1;
    return (requiredPaint / selectedWeight)
        .ceil(); // Округляем вверх до целого числа
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Калькулятор краски',
                style: GoogleFonts.ysabeau(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ширина, м',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: widthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Высота, м',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Слои',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: layersController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Общая площадь:',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${totalArea.toStringAsFixed(0)} м²',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Требуется краски:',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${requiredPaint.toStringAsFixed(1)} кг',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Количество упаковок:',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$requiredPackages шт по ${widget.selectedWeight} кг',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Добавить $requiredPackages шт в корзину',
                  onPressed: () {
                    Navigator.pop(context, requiredPackages);
                  },
                  backgroundColor: const Color(0xFFB71D18),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    layersController.dispose();
    super.dispose();
  }
}
