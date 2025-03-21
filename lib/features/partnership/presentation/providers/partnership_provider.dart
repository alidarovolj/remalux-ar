import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/providers/api_provider.dart';
import 'package:remalux_ar/features/partnership/data/repositories/partnership_repository.dart';

final partnershipRepositoryProvider = Provider<PartnershipRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PartnershipRepository(apiService);
});
