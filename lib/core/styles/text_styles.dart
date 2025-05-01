import 'package:flutter/material.dart';
import 'package:remalux_ar/core/styles/constants.dart';

class AppTextStyles {
  // Стили заголовков для Ysabeau
  static TextStyle heading1({
    Color color = const Color(0xFF1F1F1F),
    FontWeight weight = FontWeight.w600,
    double height = 1.2,
  }) {
    return TextStyle(
      fontSize: 23,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle heading2({
    Color color = const Color(0xFF1F1F1F),
    FontWeight weight = FontWeight.w600,
    double height = 1.2,
  }) {
    return TextStyle(
      fontSize: 19,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle heading3({
    Color color = const Color(0xFF1F1F1F),
    FontWeight weight = FontWeight.w600,
    double height = 1.2,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  // Стили для YsabeauInfant
  static TextStyle infantHeading({
    double fontSize = 19,
    Color color = const Color(0xFF1F1F1F),
    FontWeight weight = FontWeight.w600,
    double height = 1.2,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  // Стили для текста тела
  static TextStyle bodyText({
    double fontSize = 15,
    Color color = const Color(0xFF1F1F1F),
    FontWeight weight = FontWeight.normal,
    double height = 1.5,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  // Дополнительные стили по необходимости
  static TextStyle caption({
    double fontSize = 12,
    Color color = const Color(0xFF1F1F1F),
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
    );
  }
}
