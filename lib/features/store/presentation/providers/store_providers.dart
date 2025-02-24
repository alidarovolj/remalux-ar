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

final selectedFiltersProvider =
    StateNotifierProvider<SelectedFiltersNotifier, Set<int>>((ref) {
  return SelectedFiltersNotifier();
});

class SelectedFiltersNotifier extends StateNotifier<Set<int>> {
  SelectedFiltersNotifier() : super({});

  void toggleFilter(int id) {
    final newState = Set<int>.from(state);
    if (state.contains(id)) {
      newState.remove(id);
    } else {
      newState.add(id);
    }
    state = newState;
  }

  void reset() {
    state = {};
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');
final currentPageProvider = StateProvider<int>((ref) => 1);

final sortingProvider = StateProvider<String?>((ref) => null);

class ProductsNotifier extends StateNotifier<AsyncValue<ProductsResponse>> {
  final ProductsRepository _repository;

  ProductsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  Future<void> fetchProducts({Map<String, dynamic>? queryParams}) async {
    state = const AsyncValue.loading();

    try {
      final filterIds = queryParams?.entries
          .where((e) => e.key.startsWith('filter_ids['))
          .map((e) => int.parse(e.value))
          .toList();

      final orderBy = queryParams?['order_by'];

      final response = await _repository.getProducts(
        filterIds: filterIds,
        orderBy: orderBy,
        page: 1,
        perPage: 50,
      );

      if (mounted) {
        state = AsyncValue.data(response);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }
}

class ProductsResponse {
  final List<ProductVariant> data;
  final Meta meta;

  ProductsResponse({required this.data, required this.meta});
}

class Meta {
  final int total;

  Meta({required this.total});
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<ProductsResponse>>(
        (ref) {
  final repository = ref.read(productsRepositoryProvider);
  return ProductsNotifier(repository);
});
