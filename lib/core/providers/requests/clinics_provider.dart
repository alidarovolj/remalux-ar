import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:remalux_ar/core/types/clinics_card_type.dart';

class ClinicsNotifier extends StateNotifier<AsyncValue<List<Clinic>>> {
  ClinicsNotifier() : super(const AsyncValue.loading()) {
    fetchClinics();
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://6748e03f5801f51535926fc9.mockapi.io/api/v1/',
  ));

  Future<void> fetchClinics() async {
    try {
      print('Fetching clinics...');
      final response = await _dio.get('clinics');
      print('Response: ${response.data}');
      final List<Clinic> clinics = (response.data as List)
          .map((json) => Clinic.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(clinics);
      print('Clinics fetched successfully.');
    } catch (error, stackTrace) {
      print('Error fetching clinics: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final clinicsProvider =
    StateNotifierProvider<ClinicsNotifier, AsyncValue<List<Clinic>>>(
  (ref) => ClinicsNotifier(),
);
