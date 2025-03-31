import 'package:remalux_ar/core/services/api_service.dart';

class PartnershipRepository {
  final ApiService _apiService;

  PartnershipRepository(this._apiService);

  Future<bool> checkEmailAvailability(String email) async {
    try {
      final response = await _apiService.dio.get(
        '/auth/email-exists',
        queryParameters: {'email': email},
      );
      return !response.data['exists'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkPhoneAvailability(String phoneNumber) async {
    try {
      final response = await _apiService.dio.get(
        '/auth/phone-exists',
        queryParameters: {'phone_number': phoneNumber},
      );
      return !response.data['exists'];
    } catch (e) {
      return false;
    }
  }

  Future<void> submitApplication({
    required String name,
    required String phoneNumber,
    required String bin,
    required int cityId,
    required String email,
    required bool agreement,
  }) async {
    await _apiService.dio.post(
      '/partners',
      data: {
        'name': name,
        'phone_number': phoneNumber,
        'bin': bin,
        'city_id': cityId,
        'email': email,
        'agreement': agreement,
      },
    );
  }
}
