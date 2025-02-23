import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/services/storage_service.dart';
import 'package:remalux_ar/features/home/presentation/pages/home_page.dart';
import 'package:remalux_ar/features/store/presentation/pages/store_page.dart';
import 'package:remalux_ar/features/storybook/presentation/pages/storybook.dart';
import 'package:remalux_ar/core/widgets/main_tabbar_screen.dart';
import 'package:remalux_ar/features/onboarding/presentation/pages/onboarding_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final hasSeenOnboarding = await StorageService.getHasSeenOnboarding();
      if (!hasSeenOnboarding && state.uri.path != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      // Main app routes (with a tab bar layout)
      ShellRoute(
        builder: (context, state, child) {
          return MainTabBarScreen(
            currentRoute: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/store',
            name: 'store',
            builder: (context, state) => const StorePage(),
          ),
        ],
      ),
      // Storybook and dynamic route
      GoRoute(
        path: '/storybook',
        builder: (context, state) => const StorybookScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      )
    ],
  );
}
