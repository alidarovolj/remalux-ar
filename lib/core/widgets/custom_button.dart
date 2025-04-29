import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';

enum ButtonType { small, normal, big } // Типы кнопок

enum ButtonVariant {
  primary,
  secondary,
}

class CustomButton extends StatefulWidget {
  final String label; // Текст на кнопке
  final VoidCallback? onPressed; // Действие при нажатии
  final ButtonType type; // Тип кнопки
  final bool isEnabled; // Определяет, включена ли кнопка
  final bool isFullWidth; // Растягивать ли кнопку на всю ширину
  final bool isLoading; // Add this line
  final bool isBackGradient;
  final Color? backgroundColor; // Add this line
  final Color? textColor; // Add this line
  final ButtonVariant variant;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ButtonType.normal, // Тип по умолчанию
    this.isEnabled = true, // Кнопка включена по умолчанию
    this.isFullWidth = true, // По умолчанию на всю ширину
    this.isLoading = false, // Add this line
    this.isBackGradient = false,
    this.backgroundColor, // Add this line
    this.textColor, // Add this line
    this.variant = ButtonVariant.primary,
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  late TextStyle _textStyle;
  late EdgeInsets _padding;

  @override
  void initState() {
    super.initState();
    _applyButtonStyle();
  }

  void _applyButtonStyle() {
    switch (widget.type) {
      case ButtonType.small:
        _textStyle = const TextStyle(
          fontSize: AppLength.xs,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        );
        _padding = const EdgeInsets.symmetric(
            vertical: AppLength.tiny, horizontal: AppLength.xs);
        break;
      case ButtonType.normal:
        _textStyle = const TextStyle(
          fontSize: AppLength.sm,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        );
        _padding = const EdgeInsets.symmetric(
            horizontal: AppLength.xs, vertical: AppLength.none);
        break;
      case ButtonType.big:
        _textStyle = const TextStyle(
          fontSize: AppLength.body,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        );
        _padding = const EdgeInsets.symmetric(
            horizontal: AppLength.xs, vertical: AppLength.xs);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultBgColor = switch (widget.variant) {
      ButtonVariant.primary =>
        widget.isEnabled ? AppColors.primary : AppColors.buttonDisabled,
      ButtonVariant.secondary =>
        widget.isEnabled ? AppColors.buttonSecondary : AppColors.buttonDisabled,
    };

    final defaultTextColor = switch (widget.variant) {
      ButtonVariant.primary => Colors.white,
      ButtonVariant.secondary => AppColors.primary,
    };

    final Color actualBgColor = widget.backgroundColor ?? defaultBgColor;
    final Color actualTextColor = widget.textColor ?? defaultTextColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: widget.isBackGradient && widget.isEnabled
            ? const LinearGradient(
                colors: [
                  Color(0xFFC41B5E),
                  Color(0xFFD32253),
                  Color(0xFFE02427),
                ],
                stops: [0.0, 0.47, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: !widget.isEnabled
            ? const Color(0xFFE0E0E0) // Серый цвет для disabled состояния
            : widget.isBackGradient
                ? null
                : actualBgColor,
        borderRadius: BorderRadius.circular(AppLength.xs),
      ),
      child: MaterialButton(
        minWidth: widget.isFullWidth ? double.infinity : 0.0,
        height: widget.type == ButtonType.small ? 24 : 48,
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onPressed: widget.isEnabled ? widget.onPressed : null,
        color: Colors.transparent,
        disabledColor: Colors.transparent,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        child: widget.isLoading
            ? SizedBox(
                height: widget.type == ButtonType.small ? 12 : 16,
                width: widget.type == ButtonType.small ? 12 : 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isEnabled
                        ? AppColors.white
                        : AppColors.textSecondary,
                  ),
                ),
              )
            : AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: _textStyle.copyWith(
                  color: actualTextColor,
                ),
                child: Text(widget.label),
              ),
      ),
    );
  }
}
