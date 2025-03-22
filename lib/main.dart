import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'core/api/firebase_setup.dart';
// import 'core/utils/notification_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart' as auth_state;
// import 'package:remalux_ar/features/auth/presentation/pages/auth_check_page.dart';
import 'package:remalux_ar/core/services/analytics_service.dart';
import 'package:remalux_ar/core/router/app_router.dart';
import 'package:remalux_ar/core/services/api_client.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart';
// import 'package:yandex_search/yandex_search.dart';
// import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  try {
    await dotenv.load();
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    // Initialize Amplitude
    final amplitudeApiKey = dotenv.env['AMPLITUDE_API_KEY'];
    if (amplitudeApiKey != null) {
      await AnalyticsService.init(amplitudeApiKey);
    }

    await initializeDateFormatting('ru', null);
    final router = AppRouter.router;

    // Initialize Yandex MapKit
    // await YandexMapKit.init(
    //   apiKey: dotenv.env['YANDEX_MAPKIT_API_KEY'] ?? '',
    // );

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('ru'),
          Locale('kz'),
        ],
        path: 'lib/core/assets/translations',
        fallbackLocale: const Locale('en'),
        useOnlyLangCode: true,
        child: ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              try {
                ref.read(auth_state.authProvider.notifier).initializeAuth();
                ref.read(tokenInitializerProvider);
              } catch (e) {
                print('Ошибка инициализации авторизации: $e');
              }

              return App(router: router, initialRoute: '/');
            },
          ),
        ),
      ),
    );
  } catch (e) {
    print('Error initializing app: $e');
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

class App extends StatelessWidget {
  final String initialRoute;
  final GoRouter router;

  const App({
    super.key,
    required this.initialRoute,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Remalux',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        context.localizationDelegates[0],
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('kk'),
      ],
      locale: context.locale,
      routerConfig: router,
    );
  }
}
