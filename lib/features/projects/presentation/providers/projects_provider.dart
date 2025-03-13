import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:remalux_ar/core/constants/api_constants.dart';
import 'package:remalux_ar/features/projects/data/models/project_model.dart';
import 'package:remalux_ar/core/network/dio_provider.dart';
import 'package:remalux_ar/features/projects/domain/services/projects_service.dart';

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<List<ProjectModel>>>(
        (ref) {
  final dio = ref.watch(dioProvider);
  return ProjectsNotifier(ProjectsService(dio: dio));
});

class ProjectsNotifier extends StateNotifier<AsyncValue<List<ProjectModel>>> {
  final ProjectsService _service;

  ProjectsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> fetchProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _service.getProjects();
      state = AsyncValue.data(projects);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
