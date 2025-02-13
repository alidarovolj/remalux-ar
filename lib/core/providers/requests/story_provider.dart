import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';

class StoryPartner {
  final int id;
  final String name;
  final String imageUrl;

  StoryPartner({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory StoryPartner.fromJson(Map<String, dynamic> json) {
    return StoryPartner(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
    );
  }
}

class StoryModule {
  final int id;
  final String name;
  final String code;

  StoryModule({
    required this.id,
    required this.name,
    required this.code,
  });

  factory StoryModule.fromJson(Map<String, dynamic> json) {
    return StoryModule(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class Story {
  final int id;
  final String title;
  final String description;
  final String image;
  final String screen;
  final StoryPartner partner;
  final List<StoryModule> modules;
  bool read;

  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.screen,
    required this.partner,
    required this.modules,
    this.read = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      image: json['screen'] as String,
      screen: json['image_url'] as String,
      partner: StoryPartner.fromJson(json['partner'] as Map<String, dynamic>),
      modules: (json['modules'] as List<dynamic>)
          .map((e) => StoryModule.fromJson(e as Map<String, dynamic>))
          .toList(),
      read: false,
    );
  }
}

class StoriesNotifier extends StateNotifier<AsyncValue<List<Story>>> {
  StoriesNotifier({required this.module}) : super(const AsyncValue.loading()) {
    fetchStories();
  }

  final String? module;
  final _apiClient = ApiClient();

  Future<void> fetchStories() async {
    try {
      print('Fetching stories...');
      final response = await _apiClient.dio
          .get(
        '/stories',
        queryParameters: module != null ? {'module': module} : null,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Превышено время ожидания запроса');
        },
      );

      print('Response: ${response.data}');
      final responseData = response.data as Map<String, dynamic>;
      final List<Story> stories = (responseData['data'] as List)
          .map((json) => Story.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter stories by module if specified
      final filteredStories = module != null
          ? stories
              .where((story) => story.modules.any((m) => m.name == module))
              .toList()
          : stories;

      state = AsyncValue.data(filteredStories);
      print('Stories fetched successfully.');
    } catch (error, stackTrace) {
      print('Error fetching stories: $error');
      String errorMessage = 'Произошла ошибка при загрузке историй';

      if (error is SocketException) {
        errorMessage = 'Отсутствует подключение к интернету';
      } else if (error is TimeoutException) {
        errorMessage = 'Превышено время ожидания запроса';
      } else if (error is DioException) {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Превышено время ожидания запроса';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Ошибка подключения к серверу';
            break;
          default:
            errorMessage = 'Ошибка сервера: ${error.message}';
        }
      }

      state = AsyncValue.error(errorMessage, stackTrace);
    }
  }
}

final storiesProvider = StateNotifierProvider.family<StoriesNotifier,
    AsyncValue<List<Story>>, String?>(
  (ref, module) => StoriesNotifier(module: module),
);
