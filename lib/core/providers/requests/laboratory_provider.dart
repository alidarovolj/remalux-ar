import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/types/laboratory_card_type.dart';

final laboratoriesProvider = FutureProvider<List<Laboratory>>((ref) async {
  // Simulate API delay
  await Future.delayed(const Duration(seconds: 1));

  return [
    const Laboratory(
      id: '1',
      name: 'Danaher',
      image: 'lib/core/assets/images/analyses/1.jpg',
      rating: 4.7,
      distance: 2.2,
      discount: 20,
    ),
    const Laboratory(
      id: '2',
      name: 'Bio Rad',
      image: 'lib/core/assets/images/analyses/2.jpg',
      rating: 4.7,
      distance: 2.2,
    ),
    const Laboratory(
      id: '3',
      name: 'Bio Rad',
      image: 'lib/core/assets/images/analyses/3.jpg',
      rating: 4.7,
      distance: 2.2,
    ),
    // Add more mock data as needed
  ];
});
