import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:remalux_ar/features/checkout/domain/models/delivery_type.dart';
import 'package:remalux_ar/features/checkout/domain/models/payment_method.dart';
import 'package:remalux_ar/features/recipients/domain/models/recipient.dart';
import 'package:dio/dio.dart';

final deliveryTypesProvider = FutureProvider<List<DeliveryType>>((ref) async {
  try {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 1));
    return [
      DeliveryType.fromJson({
        'id': 1,
        'title': {'ru': 'Доставка', 'en': 'Delivery', 'kz': 'Жеткізу'}
      }),
      DeliveryType.fromJson({
        'id': 2,
        'title': {'ru': 'Самовывоз', 'en': 'Pickup', 'kz': 'Өзі алып кету'}
      }),
    ];
  } catch (e) {
    throw Exception('Failed to load delivery types');
  }
});

final selectedDeliveryTypeProvider = StateProvider<DeliveryType?>((ref) {
  // Set delivery (id: 1) as default
  final deliveryTypes = ref.watch(deliveryTypesProvider);
  return deliveryTypes.whenOrNull(
    data: (types) => types.firstWhere((type) => type.id == 1),
  );
});

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  try {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 1));
    return [
      PaymentMethod.fromJson({
        'id': 1,
        'title': {'ru': 'Наличными', 'en': 'Cash', 'kz': 'Қолма-қол'}
      }),
      PaymentMethod.fromJson({
        'id': 2,
        'title': {'ru': 'Картой', 'en': 'Card', 'kz': 'Картамен'}
      }),
      PaymentMethod.fromJson({
        'id': 3,
        'title': {'ru': 'Kaspi', 'en': 'Kaspi', 'kz': 'Kaspi'}
      }),
    ];
  } catch (e) {
    throw Exception('Failed to load payment methods');
  }
});

// Selected payment method
final selectedPaymentMethodProvider =
    StateProvider<PaymentMethod?>((ref) => null);

// Selected address
final selectedAddressIdProvider = StateProvider<String?>((ref) => null);

// Selected delivery time
final selectedDeliveryTimeProvider = StateProvider<DateTime?>((ref) => null);

// Selected recipient
final selectedRecipientProvider = StateProvider<Recipient?>((ref) => null);

final orderCommentProvider = StateProvider<String>((ref) => '');

final isOnlinePaymentProvider = StateProvider<bool>((ref) => true);
