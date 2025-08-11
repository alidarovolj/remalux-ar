import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'package:remalux_ar/features/projects/data/models/project_model.dart';

final projectsServiceProvider = Provider<ProjectsService>((ref) {
  final dio = ApiClient().dio;
  return ProjectsService(dio: dio);
});

class ProjectsService {
  final Dio dio;

  ProjectsService({required this.dio});

  Future<List<ProjectModel>> getProjects({bool forceRefresh = false}) async {
    try {
      final response = await dio.get(
        '/projects',
        options: Options(
          headers: {
            'Cache-Control':
                forceRefresh ? 'no-cache, no-store, must-revalidate' : null,
            'Pragma': forceRefresh ? 'no-cache' : null,
            'Expires': forceRefresh ? '0' : null,
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) {
          try {
            return ProjectModel.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            rethrow;
          }
        }).toList();
      }
      throw Exception('Failed to load projects');
    } catch (e) {
      rethrow;
    }
  }
}
