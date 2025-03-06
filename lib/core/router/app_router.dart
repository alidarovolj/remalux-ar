import 'package:go_router/go_router.dart';
import 'package:remalux_ar/features/home/presentation/pages/home_page.dart';
import 'package:remalux_ar/features/store/presentation/pages/store_page.dart';
import 'package:remalux_ar/features/store/presentation/pages/product_detail_page.dart';
import 'package:remalux_ar/features/storybook/presentation/pages/storybook.dart';
import 'package:remalux_ar/core/widgets/main_tabbar_screen.dart';
import 'package:remalux_ar/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:remalux_ar/features/news/presentation/pages/news_page.dart';
import 'package:remalux_ar/features/news/presentation/pages/news_detail_page.dart';
import 'package:remalux_ar/features/ideas/presentation/pages/ideas_page.dart';
import 'package:remalux_ar/features/ideas/presentation/pages/idea_detail_page.dart';
import 'package:remalux_ar/features/home/presentation/pages/colors_page.dart';
// import 'package:chucker_flutter/chucker_flutter.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    // observers: [ChuckerFlutter.navigatorObserver],
    // redirect: (context, state) async {
    //   final hasSeenOnboarding = await StorageService.getHasSeenOnboarding();
    //   if (!hasSeenOnboarding && state.uri.path != '/onboarding') {
    //     return '/onboarding';
    //   }
    //   return null;
    // },
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
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final initialFilterId = extra?['filter_id'] as int?;
              return StorePage(initialFilterId: initialFilterId);
            },
          ),
          GoRoute(
            path: '/news',
            name: 'news',
            builder: (context, state) => const NewsPage(),
          ),
          GoRoute(
            path: '/ideas',
            name: 'ideas',
            builder: (context, state) => const IdeasPage(),
          ),
        ],
      ),
      // Colors page route
      GoRoute(
        path: '/colors',
        name: 'colors',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final mainColorId = extra?['mainColorId'] as int?;
          return ColorsPage(mainColorId: mainColorId);
        },
      ),
      // Product detail route
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['id']!);
          final extra = state.extra as Map<String, dynamic>?;
          final initialWeight = extra?['initialWeight'] as String?;
          return ProductDetailPage(
            productId: productId,
            initialWeight: initialWeight,
          );
        },
      ),
      // News detail route
      GoRoute(
        path: '/news/:id',
        builder: (context, state) {
          final newsId = int.parse(state.pathParameters['id']!);
          return NewsDetailPage(newsId: newsId);
        },
      ),
      // Storybook and dynamic route
      GoRoute(
        path: '/storybook',
        builder: (context, state) => const StorybookScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/ideas/:id',
        builder: (context, state) {
          final ideaId = int.parse(state.pathParameters['id']!);
          return IdeaDetailPage(ideaId: ideaId);
        },
      ),
    ],
  );
}
