import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/home/data/models/detailed_color_model.dart';

final currentPageProvider = StateProvider<int>((ref) => 1);
final searchQueryProvider = StateProvider<String>((ref) => '');

final detailedColorsProvider = StateNotifierProvider<DetailedColorsNotifier,
    AsyncValue<List<DetailedColorModel>>>((ref) => DetailedColorsNotifier(ref));

class DetailedColorsNotifier
    extends StateNotifier<AsyncValue<List<DetailedColorModel>>> {
  final Ref ref;
  bool _isLoading = false;
  bool _hasMore = true;
  Map<String, dynamic>? _currentParams;

  DetailedColorsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadColors();
  }

  Future<void> loadColors({
    bool isLoadMore = false,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (_isLoading || (!_hasMore && isLoadMore)) return;

    _isLoading = true;
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

      // Update current params
      if (additionalParams != null) {
        _currentParams = Map.from(additionalParams);
      }

      // Add current params to query
      if (_currentParams != null) {
        queryParams.addAll(_currentParams!);
      }

      final response =
          await apiClient.get('/colors', queryParameters: queryParams);

      if (response == null) {
        throw Exception('Failed to load colors');
      }

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

  void resetAndSearch(String query) {
    ref.read(currentPageProvider.notifier).state = 1;
    ref.read(searchQueryProvider.notifier).state = query;
    _hasMore = true;
    if (query.isEmpty) {
      _currentParams = null;
    }
    loadColors();
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}
