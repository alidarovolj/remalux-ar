import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/models/detailed_color_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final selectedColorProvider =
    StateNotifierProvider<SelectedColorNotifier, DetailedColorModel?>((ref) {
  return SelectedColorNotifier();
});

class SelectedColorNotifier extends StateNotifier<DetailedColorModel?> {
  SelectedColorNotifier() : super(null) {
    _loadColor();
  }

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorJson = prefs.getString('selected_color');
    if (colorJson != null) {
      state = DetailedColorModel.fromJson(jsonDecode(colorJson));
    }
  }

  Future<void> setColor(DetailedColorModel color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_color', jsonEncode(color.toJson()));
    state = color;
  }

  Future<void> clearColor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_color');
    state = null;
  }
}
