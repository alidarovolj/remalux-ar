import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/partnership/data/repositories/cities_repository.dart';
import 'package:remalux_ar/features/partnership/domain/models/city.dart';

final citiesRepositoryProvider = Provider((ref) => CitiesRepository());

final citiesProvider = FutureProvider<List<City>>((ref) async {
  final repository = ref.read(citiesRepositoryProvider);
  return repository.getCities();
});
