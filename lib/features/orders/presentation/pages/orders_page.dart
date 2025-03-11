import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/orders/domain/providers/orders_provider.dart';
import 'package:remalux_ar/features/orders/presentation/widgets/order_item.dart';
import 'package:remalux_ar/features/orders/presentation/widgets/order_skeleton.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final ordersNotifier = ref.read(ordersNotifierProvider.notifier);
      ordersNotifier.loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersNotifierProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: const CustomAppBar(
          title: 'Заказы',
          showBottomBorder: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(ordersNotifierProvider.notifier).refresh();
          },
          child: ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/core/assets/images/empty_orders.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'У вас пока нет заказов',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Здесь будут отображаться ваши заказы',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: orders.length + 1, // +1 for loading indicator
                itemBuilder: (context, index) {
                  if (index == orders.length) {
                    return const SizedBox(height: 40);
                  }

                  final order = orders[index];
                  return OrderItem(
                    order: order,
                    onTap: () {
                      // Navigate to order details
                    },
                  );
                },
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const OrderSkeleton(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Не удалось загрузить заказы',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(ordersNotifierProvider.notifier).refresh();
                    },
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
