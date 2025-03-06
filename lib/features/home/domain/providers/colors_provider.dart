import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/data/models/color_model.dart';

final colorsProvider = FutureProvider<List<ColorModel>>((ref) async {
  final apiClient = ApiClient();
  final response = await apiClient.dio.get('/colors/main', queryParameters: {
    'page': 1,
    'perPage': 10,
  });

  if (response.statusCode != 200) {
    throw Exception('Failed to load colors');
  }

  final List<dynamic> colorsJson = response.data;
  return colorsJson.map((json) => ColorModel.fromJson(json)).toList();
});
