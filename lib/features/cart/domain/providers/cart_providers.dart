import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/cart/domain/models/cart_summary.dart';
import 'package:remalux_ar/features/cart/domain/models/cart_item.dart';
import 'package:remalux_ar/features/cart/domain/providers/cart_provider.dart';

// Провайдер для списка товаров в корзине
final cartItemsProvider = Provider<List<CartItem>>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.value ?? [];
});

// Провайдер для промокода
final promoCodeProvider = StateProvider<String?>((ref) => null);

// Провайдер для итоговой информации корзины
final cartSummaryProvider = Provider<CartSummary>((ref) {
  final items = ref.watch(cartItemsProvider);
  final promoCode = ref.watch(promoCodeProvider);

  // Подсчет общей суммы
  final totalAmount = items.fold<int>(
    0,
    (sum, item) =>
        sum + (int.parse(item.productVariant.price.toString()) * item.quantity),
  );

  // Подсчет общего количества товаров
  final totalProducts = items.fold<int>(
    0,
    (sum, item) => sum + item.quantity,
  );

  // Расчет скидки (пока просто по промокоду)
  int discount = 0;
  if (promoCode != null) {
    // Здесь можно добавить логику расчета скидки по промокоду
    // Например, если промокод DEAL12, то скидка 12%
    if (promoCode == 'DEAL12') {
      discount = (totalAmount * 0.12).round();
    }
  }

  return CartSummary(
    totalProducts: totalProducts,
    totalAmount: totalAmount,
    discount: discount,
    finalAmount: totalAmount - discount,
  );
});
