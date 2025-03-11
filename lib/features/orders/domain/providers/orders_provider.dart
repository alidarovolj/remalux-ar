import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/orders/domain/models/order.dart';
import 'package:remalux_ar/features/orders/domain/services/orders_service.dart';

final ordersServiceProvider = Provider<OrdersService>((ref) {
  return OrdersService();
});

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final ordersService = ref.watch(ordersServiceProvider);
  return ordersService.getMyOrders();
});

final ordersNotifierProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<Order>>>((ref) {
  final ordersService = ref.watch(ordersServiceProvider);
  return OrdersNotifier(ordersService);
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrdersService _ordersService;
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;

  OrdersNotifier(this._ordersService) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final orders = await _ordersService.getMyOrders(
        page: _currentPage,
        perPage: _perPage,
      );

      if (orders.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage++;
      }

      if (_currentPage == 1) {
        state = AsyncValue.data(orders);
      } else {
        final currentOrders = state.value ?? [];
        state = AsyncValue.data([...currentOrders, ...orders]);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadOrders(refresh: true);
  }
}
