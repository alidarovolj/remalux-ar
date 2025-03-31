import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/data/models/detailed_color_model.dart';

final currentPageProvider = StateProvider<int>((ref) => 1);
final searchQueryProvider = StateProvider<String>((ref) => '');

final detailedColorsProvider = StateNotifierProvider<DetailedColorsNotifier,
    AsyncValue<List<DetailedColorModel>>>((ref) {
  // Create a new instance each time
  final notifier = DetailedColorsNotifier(ref);
  // Dispose the old instance if it exists
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class DetailedColorsNotifier
    extends StateNotifier<AsyncValue<List<DetailedColorModel>>> {
  final Ref ref;
  bool _isLoading = false;
  bool _hasMore = true;
  Map<String, dynamic>? _currentParams;

  DetailedColorsNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Don't load colors automatically
  }

  Future<void> loadColors({
    bool isLoadMore = false,
    Map<String, dynamic>? additionalParams,
    bool forceRefresh = false,
  }) async {
    if (_isLoading || (!_hasMore && isLoadMore)) return;

    _isLoading = true;

    // Reset all state if force refresh is requested
    if (forceRefresh) {
      ref.read(currentPageProvider.notifier).state = 1;
      ref.read(searchQueryProvider.notifier).state = '';
      _hasMore = true;
      _currentParams = additionalParams;
    } else if (additionalParams != null) {
      _currentParams = additionalParams;
    }

    final currentPage = ref.read(currentPageProvider);
    final searchQuery = ref.read(searchQueryProvider);

    try {
      final apiClient = ApiClient();
      final Map<String, dynamic> queryParams = {
        'page': currentPage,
        'perPage': 10,
      };

      // Add search parameter if there is a search query
      if (searchQuery.isNotEmpty) {
        queryParams['searchKeyword'] = searchQuery;
      }

      // Add current params to query
      if (_currentParams != null) {
        queryParams.addAll(_currentParams!);
      }

      final response =
          await apiClient.get('/colors', queryParameters: queryParams);

      final List<dynamic> colorsJson = response['data'] as List<dynamic>;
      final newColors =
          colorsJson.map((json) => DetailedColorModel.fromJson(json)).toList();

      // Check if we have more pages
      final meta = response['meta'] as Map<String, dynamic>;
      _hasMore = currentPage < (meta['last_page'] as int);

      if (isLoadMore && state.hasValue) {
        state = AsyncValue.data([...state.value!, ...newColors]);
      } else {
        state = AsyncValue.data(newColors);
      }

      if (_hasMore) {
        ref.read(currentPageProvider.notifier).state = currentPage + 1;
      }
    } catch (error, stackTrace) {
      if (!isLoadMore) {
        state = AsyncValue.error(error, stackTrace);
      }
    } finally {
      _isLoading = false;
    }
  }

  void resetAndSearch(String query, {Map<String, dynamic>? additionalParams}) {
    ref.read(currentPageProvider.notifier).state = 1;
    ref.read(searchQueryProvider.notifier).state = query;
    _hasMore = true;

    if (query.isEmpty && additionalParams == null) {
      _currentParams = null;
    } else if (additionalParams != null) {
      _currentParams = additionalParams;
    }

    loadColors();
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}
