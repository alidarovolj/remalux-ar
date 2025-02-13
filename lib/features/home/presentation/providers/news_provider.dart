import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/news_repository.dart';
import 'package:remalux_ar/features/home/domain/models/news.dart';

final newsRepositoryProvider = Provider((ref) => NewsRepository());

final newsProvider = FutureProvider<List<News>>((ref) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getNews();
});
