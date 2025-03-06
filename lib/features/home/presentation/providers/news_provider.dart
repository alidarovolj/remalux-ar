import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/news_repository.dart';
import 'package:remalux_ar/features/home/domain/models/news.dart';

final newsRepositoryProvider = Provider((ref) => NewsRepository());

final newsProvider = FutureProvider<List<News>>((ref) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getNews();
});

final newsDetailProvider =
    FutureProvider.family<News, int>((ref, newsId) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getNewsDetail(newsId);
});

// Провайдер для предварительной загрузки
final preloadedNewsProvider =
    StateProvider.family<AsyncValue<News>, int>((ref, newsId) {
  return const AsyncValue.loading();
});
