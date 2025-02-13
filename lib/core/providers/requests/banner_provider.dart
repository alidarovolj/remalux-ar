import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';

class BannerPartner {
  final int id;
  final String name;
  final String imageUrl;

  BannerPartner({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory BannerPartner.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['image_url'] as String;
    // Validate URL and provide fallback if invalid
    if (!Uri.parse(imageUrl).isAbsolute || imageUrl == 'https://example') {
      imageUrl =
          'https://api.medix-ai.kz/storage/images/default_partner_logo.png';
    }

    return BannerPartner(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: imageUrl,
    );
  }
}

class BannerModule {
  final int id;
  final String name;
  final String code;

  BannerModule({
    required this.id,
    required this.name,
    required this.code,
  });

  factory BannerModule.fromJson(Map<String, dynamic> json) {
    return BannerModule(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class BannerModel {
  final int id;
  final String title;
  final String description;
  final String image;
  final String linkType;
  final String linkValue;
  final BannerPartner partner;
  final List<BannerModule> modules;

  BannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.linkType,
    required this.linkValue,
    required this.partner,
    required this.modules,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      image: json['image'] as String? ??
          'https://api.medix-ai.kz/storage/images/default_banner.jpg',
      linkType: json['link_type'] as String,
      linkValue: json['link_value'] as String,
      partner: BannerPartner.fromJson(json['partner'] as Map<String, dynamic>),
      modules: (json['modules'] as List<dynamic>)
          .map((e) => BannerModule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BannersNotifier extends StateNotifier<AsyncValue<List<BannerModel>>> {
  BannersNotifier({required this.module}) : super(const AsyncValue.loading()) {
    fetchBanners();
  }

  final String? module;
  final _apiClient = ApiClient();

  Future<void> fetchBanners() async {
    try {
      print('Fetching banners...');
      final response = await _apiClient.dio
          .get(
        '/banners',
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
      final List<BannerModel> banners = (responseData['data'] as List)
          .map((json) => BannerModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter banners by module if specified
      final filteredBanners = module != null
          ? banners
              .where((banner) => banner.modules.any((m) => m.name == module))
              .toList()
          : banners;

      state = AsyncValue.data(filteredBanners);
      print('Banners fetched successfully.');
    } catch (error, stackTrace) {
      print('Error fetching banners: $error');
      String errorMessage = 'Произошла ошибка при загрузке баннеров';

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

final bannersProvider = StateNotifierProvider.family<BannersNotifier,
    AsyncValue<List<BannerModel>>, String?>(
  (ref, module) => BannersNotifier(module: module),
);
