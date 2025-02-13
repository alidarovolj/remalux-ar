import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/categories_repository.dart';
import 'package:remalux_ar/features/home/domain/models/category.dart';

final categoriesRepositoryProvider = Provider((ref) => CategoriesRepository());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(categoriesRepositoryProvider);
  return repository.getCategories();
});
