import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/ideas_repository.dart';
import 'package:remalux_ar/features/home/domain/models/idea.dart';
import 'package:remalux_ar/core/api/api_client.dart';

final ideasRepositoryProvider = Provider((ref) => IdeasRepository());

final ideasProvider = FutureProvider<List<Idea>>((ref) async {
  final repository = ref.watch(ideasRepositoryProvider);
  return repository.getIdeas();
});

final ideaDetailProvider = FutureProvider.family<Idea, int>((ref, id) async {
  final apiClient = ApiClient();
  final response = await apiClient.get('/ideas/$id');
  return Idea.fromJson(response);
});
