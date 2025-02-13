import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/products_repository.dart';
import 'package:remalux_ar/features/home/domain/models/product.dart';

final productsRepositoryProvider = Provider((ref) => ProductsRepository());

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getProducts();
});
