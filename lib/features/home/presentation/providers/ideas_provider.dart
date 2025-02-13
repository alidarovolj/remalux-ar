import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/home/data/repositories/ideas_repository.dart';
import 'package:remalux_ar/features/home/domain/models/idea.dart';

final ideasRepositoryProvider = Provider((ref) => IdeasRepository());

final ideasProvider = FutureProvider<List<Idea>>((ref) async {
  final repository = ref.read(ideasRepositoryProvider);
  return repository.getIdeas();
});
