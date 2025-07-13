import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart' as auth_state;
import 'package:remalux_ar/core/services/analytics_service.dart';
import 'package:remalux_ar/core/router/app_router.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/core/providers/shared_preferences_provider.dart';
import 'package:remalux_ar/features/store/domain/providers/product_storage_service.dart';
import 'package:remalux_ar/features/store/presentation/providers/compare_products_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:remalux_ar/core/api/firebase_setup.dart';

// Function to configure Google Fonts to use local fonts
Future<void> _loadGoogleFonts() async {
  // Отключаем загрузку шрифтов через интернет
  GoogleFonts.config.allowRuntimeFetching = false;

  // Используем предварительно загруженные локальные шрифты
  print('Fonts configured to use only bundled assets');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Основной код приложения
  try {
    await dotenv.load();
    await EasyLocalization.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Load Google Fonts before app starts
    await _loadGoogleFonts();

    // Initialize Firebase setup and request permissions
    await initializeFirebase();
    await requestNotificationPermissions();

    // Get FCM token with APNS handling
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Request APNS token first
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print('APNS Token: $apnsToken');

      // Wait for APNS token to be set
      if (apnsToken == null) {
        print('Waiting for APNS token...');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // Get FCM token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken');

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // TODO: Send this token to your server
    });

    print('Initializing SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    print('SharedPreferences initialized successfully with instance: $prefs');

    // Initialize Amplitude
    final amplitudeApiKey = dotenv.env['AMPLITUDE_API_KEY'];
    if (amplitudeApiKey != null) {
      await AnalyticsService.init(amplitudeApiKey);
    }

    await initializeDateFormatting('ru', null);
    final router = AppRouter.router;

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
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            productStorageServiceProvider.overrideWithValue(
              ProductStorageService(prefs),
            ),
          ],
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
