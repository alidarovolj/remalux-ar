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
import 'package:remalux_ar/features/profile/presentation/pages/profile_page.dart';
import 'package:remalux_ar/features/auth/presentation/pages/login_page.dart';
import 'package:remalux_ar/features/orders/presentation/pages/orders_page.dart';
import 'package:remalux_ar/features/favorites/presentation/pages/favorites_page.dart';
import 'package:remalux_ar/features/recipients/presentation/pages/recipients_page.dart';
import 'package:remalux_ar/features/addresses/presentation/pages/addresses_page.dart';
import 'package:remalux_ar/features/contacts/presentation/pages/contacts_page.dart';
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
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
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
      // Recipients page route
      GoRoute(
        path: '/recipients',
        name: 'recipients',
        builder: (context, state) => const RecipientsPage(),
      ),
      // Addresses page route
      GoRoute(
        path: '/addresses',
        name: 'addresses',
        builder: (context, state) => const AddressesPage(),
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
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FavoritesPage(
            initialTabIndex: extra?['initialTabIndex'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsPage(),
      ),
    ],
  );
}
