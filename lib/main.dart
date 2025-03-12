import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'core/api/firebase_setup.dart';
// import 'core/utils/notification_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
// import 'package:remalux_ar/features/auth/presentation/pages/auth_check_page.dart';
import 'package:remalux_ar/core/services/analytics_service.dart';
import 'package:remalux_ar/core/router/app_router.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart';
// import 'package:yandex_search/yandex_search.dart';
// import 'package:chucker_flutter/chucker_flutter.dart';

Future<void> main() async {
  try {
    await dotenv.load();
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Chucker
    // ChuckerFlutter.showOnRelease = false;

    // Initialize Firebase
    // await initializeFirebase();

    // Initialize Amplitude
    final amplitudeApiKey = dotenv.env['AMPLITUDE_API_KEY'];
    if (amplitudeApiKey != null) {
      await AnalyticsService.init(amplitudeApiKey);
    }

    // Request notification permissions
    // await requestNotificationPermissions();

    // Set up notification listeners
    // setupNotificationListeners();

    await initializeDateFormatting('ru', null);

    // Check if user has seen onboarding
    final hasSeenOnboarding = await StorageService.hasSeenOnboarding();

    // Initialize Yandex MapKit
    // await YandexMapKit.init(
    //   apiKey: dotenv.env['YANDEX_MAPKIT_API_KEY'] ?? '',
    // );

    runApp(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            try {
              // Initialize auth state
              ref.read(authProvider.notifier).initializeAuth();
            } catch (e) {
              print('Ошибка инициализации авторизации: $e');
            }

            // If user hasn't seen onboarding, redirect to it
            if (!hasSeenOnboarding) {
              Future.microtask(() => StorageService.setHasSeenOnboarding());
              return const MyApp(initialRoute: '/onboarding');
            }

            return const MyApp(initialRoute: '/');
          },
        ),
      ),
    );
  } catch (e) {
    print('Ошибка запуска: $e');
    // Запускаем минимальное приложение в случае ошибки
    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Remalux Error'),
          ),
          body: Center(
            child: Text(
              'Произошла ошибка при запуске: $e',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding';

  static Future<bool> hasSeenOnboarding() async {
    return _storage
        .read(key: _hasSeenOnboardingKey)
        .then((value) => value != null);
  }

  static Future<void> setHasSeenOnboarding() async {
    await _storage.write(key: _hasSeenOnboardingKey, value: 'true');
  }
}
