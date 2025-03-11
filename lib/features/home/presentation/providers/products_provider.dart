import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/products_repository.dart';
import 'package:remalux_ar/features/home/domain/models/product.dart';

final productsRepositoryProvider = Provider((ref) => ProductsRepository());

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repository = ProductsRepository();
  final forceRefresh = ref.watch(forceRefreshProvider);
  return repository.getProducts(forceRefresh: forceRefresh);
});

final forceRefreshProvider = StateProvider<bool>((ref) => false);
