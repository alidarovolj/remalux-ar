import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remalux_ar/core/providers/auth/auth_state.dart';
import 'custom_tabbar.dart';

class MainTabBarScreen extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainTabBarScreen({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<MainTabBarScreen> createState() => _MainTabBarScreenState();
}

class _MainTabBarScreenState extends ConsumerState<MainTabBarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, int> _routesToTabIndex = {
    '/': 0,
    '/store': 1,
    '/ar': 2,
    '/cart': 3,
    '/profile': 4,
  };

  final Map<int, String> _tabIndexToRoutes = {
    0: '/',
    1: '/store',
    2: '/ar',
    3: '/cart',
    4: '/profile',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _updateTabIndex();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _navigateToTab(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(MainTabBarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateTabIndex();
    }
  }

  void _updateTabIndex() {
    final index = _routesToTabIndex[widget.currentRoute] ?? 0;
    if (_tabController.index != index) {
      _tabController.index = index;
    }
  }

  void _navigateToTab(int index) {
    final route = _tabIndexToRoutes[index];
    if (route != null && widget.currentRoute != route) {
      if (index == 4) {
        final authState = ref.read(authProvider);
        if (!authState.isAuthenticated) {
          context.go('/profile');
          return;
        }
      }
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomTabBar(tabController: _tabController),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
