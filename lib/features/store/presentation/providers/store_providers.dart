import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/store/data/repositories/filters_repository.dart';
import 'package:remalux_ar/features/store/data/repositories/products_repository.dart';
import 'package:remalux_ar/features/store/domain/models/filter.dart';
import 'package:remalux_ar/features/store/domain/models/product.dart';

final filtersRepositoryProvider = Provider((ref) => FiltersRepository());
final productsRepositoryProvider = Provider((ref) => ProductsRepository());

final filtersProvider = FutureProvider<List<Filter>>((ref) async {
  final repository = ref.read(filtersRepositoryProvider);
  return repository.getFilters();
});

final selectedFiltersProvider = StateProvider<List<int>>((ref) => []);
final searchQueryProvider = StateProvider<String>((ref) => '');
final currentPageProvider = StateProvider<int>((ref) => 1);

final productsProvider = FutureProvider<List<ProductVariant>>((ref) async {
  final repository = ref.read(productsRepositoryProvider);
  final selectedFilters = ref.watch(selectedFiltersProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final currentPage = ref.watch(currentPageProvider);

  return repository.getProducts(
    page: currentPage,
    filterIds: selectedFilters,
    searchQuery: searchQuery,
  );
});
