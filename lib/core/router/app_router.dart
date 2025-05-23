import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/features/home/presentation/pages/home_page.dart';
import 'package:remalux_ar/features/store/presentation/pages/store_page.dart';
import 'package:remalux_ar/features/store/presentation/pages/product_detail_page.dart';
import 'package:remalux_ar/features/store/presentation/pages/compare_products_page.dart';
import 'package:remalux_ar/features/storybook/presentation/pages/storybook.dart';
import 'package:remalux_ar/core/widgets/main_tabbar_screen.dart';
import 'package:remalux_ar/features/news/presentation/pages/news_page.dart';
import 'package:remalux_ar/features/news/presentation/pages/news_detail_page.dart';
import 'package:remalux_ar/features/ideas/presentation/pages/ideas_page.dart';
import 'package:remalux_ar/features/ideas/presentation/pages/idea_detail_page.dart';
import 'package:remalux_ar/features/home/presentation/pages/colors_page.dart';
import 'package:remalux_ar/features/profile/presentation/pages/profile_page.dart';
import 'package:remalux_ar/features/auth/presentation/pages/login_page.dart';
import 'package:remalux_ar/features/auth/presentation/pages/registration_page.dart';
import 'package:remalux_ar/features/orders/presentation/pages/orders_page.dart';
import 'package:remalux_ar/features/favorites/presentation/pages/favorites_page.dart';
import 'package:remalux_ar/features/recipients/presentation/pages/recipients_page.dart';
import 'package:remalux_ar/features/addresses/presentation/pages/addresses_page.dart';
import 'package:remalux_ar/features/addresses/presentation/pages/add_address_page.dart';
import 'package:remalux_ar/features/contacts/presentation/pages/contacts_page.dart';
import 'package:remalux_ar/features/projects/presentation/pages/projects_page.dart';
import 'package:remalux_ar/features/faq/presentation/pages/faq_page.dart';
import 'package:remalux_ar/features/partnership/presentation/pages/partnership_page.dart';
import 'package:remalux_ar/features/partnership/presentation/pages/partnership_application_page.dart';
import 'package:remalux_ar/features/about/presentation/pages/about_page.dart';
import 'package:remalux_ar/features/cart/presentation/pages/cart_page.dart';
import 'package:remalux_ar/features/checkout/presentation/pages/checkout_page.dart';
// import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:remalux_ar/features/auth/presentation/pages/phone_verification_page.dart';
import 'package:remalux_ar/screens/wall_painter_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
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
      // Colors route moved outside ShellRoute
      GoRoute(
        path: '/colors',
        name: 'colors',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final productId = extra?['productId'] as int?;
          final fromProductDetail =
              extra?['fromProductDetail'] as bool? ?? false;

          // Get mainColorId from query parameters
          final mainColorIdStr = state.uri.queryParameters['mainColorId'];
          final mainColorId =
              mainColorIdStr != null ? int.parse(mainColorIdStr) : null;

          return ColorsPage(
            mainColorId: mainColorId,
            productId: productId,
            fromProductDetail: fromProductDetail,
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
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
              final categoryId =
                  extra?['filters[product.category_id]'] as String?;
              final autoFocus = extra?['autoFocus'] as bool? ?? false;
              return StorePage(
                initialCategoryId:
                    categoryId != null ? int.parse(categoryId) : null,
                autoFocus: autoFocus,
              );
            },
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartPage(),
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
          GoRoute(
            path: '/addresses',
            name: 'addresses',
            builder: (context, state) => const AddressesPage(),
          ),
          GoRoute(
            path: '/recipients',
            name: 'recipients',
            builder: (context, state) => const RecipientsPage(),
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
            path: '/about',
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsPage(),
          ),
          GoRoute(
            path: '/projects',
            name: 'projects',
            builder: (context, state) => const ProjectsPage(),
          ),
          GoRoute(
            path: '/partnership',
            name: 'partnership',
            builder: (context, state) => const PartnershipPage(),
          ),
          GoRoute(
            path: '/partnership/application',
            name: 'partnership_application',
            builder: (context, state) => const PartnershipApplicationPage(),
          ),
          GoRoute(
            path: '/faq',
            name: 'faq',
            builder: (context, state) => const FaqPage(),
          ),
          GoRoute(
            path: '/ideas/:id',
            builder: (context, state) {
              final ideaId = int.parse(state.pathParameters['id']!);
              return IdeaDetailPage(ideaId: ideaId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      // Product detail route moved inside ShellRoute
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
      // Compare products route
      GoRoute(
        path: '/compare-products',
        name: 'compare_products',
        builder: (context, state) => const CompareProductsPage(),
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
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/addresses/add',
        name: 'add_address',
        builder: (context, state) => const AddAddressPage(),
      ),
      GoRoute(
        path: '/registration',
        name: 'registration',
        builder: (context, state) => const RegistrationPage(),
      ),
      GoRoute(
        path: '/phone-verification',
        builder: (context, state) => const PhoneVerificationPage(),
      ),
      // Добавляем маршрут для AR-перекрашивания стен
      GoRoute(
        path: '/wall-painter',
        name: 'wall_painter',
        builder: (context, state) {
          // Получаем цвет из параметров, если он был передан
          final colorHex = state.uri.queryParameters['color'];
          final color = colorHex != null
              ? Color(int.parse(colorHex, radix: 16) | 0xFF000000)
              : null;

          return WallPainterScreen(initialColor: color);
        },
      ),
    ],
  );
}
