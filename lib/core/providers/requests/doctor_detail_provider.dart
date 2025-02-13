import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:remalux_ar/core/providers/requests/doctor_provider.dart';

class DoctorDetailsNotifier extends StateNotifier<AsyncValue<Doctor>> {
  DoctorDetailsNotifier({required this.id})
      : super(const AsyncValue.loading()) {
    fetchDoctorById();
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://6748e03f5801f51535926fc9.mockapi.io/api/v1/',
  ));
  final String id;

  Future<void> fetchDoctorById() async {
    try {
      print('Fetching doctor with ID: $id');
      final response = await _dio.get('doctors/$id');
      print('Response: ${response.data}');
      final doctor = Doctor.fromJson(response.data as Map<String, dynamic>);
      state = AsyncValue.data(doctor);
      print('Doctor fetched successfully.');
    } catch (error, stackTrace) {
      print('Error fetching doctor: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Провайдер для получения конкретного врача по ID
final doctorDetailsProvider = StateNotifierProvider.family<
    DoctorDetailsNotifier, AsyncValue<Doctor>, String>(
  (ref, id) => DoctorDetailsNotifier(id: id),
);
