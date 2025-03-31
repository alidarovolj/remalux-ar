import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/features/checkout/domain/models/delivery_type.dart';
import 'package:remalux_ar/features/checkout/domain/models/payment_method.dart';
import 'package:remalux_ar/features/recipients/domain/models/recipient.dart';
import 'package:remalux_ar/core/services/api_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:remalux_ar/features/cart/domain/providers/cart_providers.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:remalux_ar/core/config/app_config.dart';
import 'package:remalux_ar/core/services/storage_service.dart';

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

// Провайдер для принятия условий соглашения
final termsAcceptedProvider = StateProvider<bool>((ref) => false);

// Провайдер для сообщений об ошибках валидации
final validationErrorProvider = StateProvider<String?>((ref) => null);

// Провайдер для создания заказа
final orderProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<int?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderNotifier(apiClient, ref);
});

class OrderNotifier extends StateNotifier<AsyncValue<int?>> {
  final ApiClient _apiClient;
  final Ref _ref;

  OrderNotifier(this._apiClient, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> validateOrderData() {
    final isDelivery = _ref.read(selectedDeliveryTypeProvider)?.id == 1;
    final selectedAddressId = _ref.read(selectedAddressIdProvider);
    final selectedDeliveryTime = _ref.read(selectedDeliveryTimeProvider);
    final selectedRecipient = _ref.read(selectedRecipientProvider);

    if (isDelivery) {
      // При доставке обязательны: адрес, время, получатель
      if (selectedAddressId == null || selectedAddressId.isEmpty) {
        _ref.read(validationErrorProvider.notifier).state =
            'checkout.validation.address_required'.tr();
        return Future.value(false);
      }

      if (selectedDeliveryTime == null) {
        _ref.read(validationErrorProvider.notifier).state =
            'checkout.validation.delivery_time_required'.tr();
        return Future.value(false);
      }
    }

    // Получатель обязателен всегда (и при доставке, и при самовывозе)
    if (selectedRecipient == null) {
      _ref.read(validationErrorProvider.notifier).state =
          'checkout.validation.recipient_required'.tr();
      return Future.value(false);
    }

    // Если все проверки пройдены
    _ref.read(validationErrorProvider.notifier).state = null;
    return Future.value(true);
  }

  Future<void> createOrder(String note) async {
    // Сначала проверяем валидность данных
    final isValid = await validateOrderData();
    if (!isValid) {
      return;
    }

    try {
      state = const AsyncValue.loading();

      final cartItems = _ref.read(cartItemsProvider);
      final selectedDeliveryType = _ref.read(selectedDeliveryTypeProvider);
      final isOnlinePayment = _ref.read(isOnlinePaymentProvider);
      final selectedAddressId = _ref.read(selectedAddressIdProvider);
      final selectedRecipient = _ref.read(selectedRecipientProvider);
      final selectedDeliveryTime = _ref.read(selectedDeliveryTimeProvider);
      final cartSummary = _ref.read(cartSummaryProvider);

      // Формируем список товаров для запроса
      final productVariants = cartItems
          .map((item) => {
                "product_variant_id": item.productVariant.id,
                "quantity": item.quantity,
                "price": item.productVariant.price.toString(),
                "color_id": item.colorId != null ? item.colorId!['id'] : null
              })
          .toList();

      // Определяем метод оплаты (по умолчанию 1 - онлайн, 2 - наличными)
      final paymentMethodId = isOnlinePayment ? 1 : 2;

      // Формируем тело запроса на создание заказа
      final Map<String, dynamic> requestBody = {
        "product_variants": productVariants,
        "delivery_address_id": selectedDeliveryType?.id == 1
            ? int.parse(selectedAddressId!)
            : null,
        "recipient_id": selectedRecipient?.id,
        "note": note.isNotEmpty ? note : null,
        "delivery_type_id": selectedDeliveryType?.id,
        "payment_method_id": paymentMethodId,
        "total_amount": cartSummary.finalAmount.toInt(),
        "agreement": true,
        "delivery_date":
            selectedDeliveryType?.id == 1 && selectedDeliveryTime != null
                ? selectedDeliveryTime.toIso8601String()
                : null,
      };

      print('📦 Sending order request: $requestBody');

      try {
        // Получаем токен напрямую из хранилища
        final token = await StorageService.getToken();

        // Используем более прямой подход к запросу
        final dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));

        print('📦 Token for request: ${token?.substring(0, 10)}...');
        print('📦 Request URL: ${AppConfig.apiUrl}/orders');
        print('📦 Request method: POST');
        print('📦 Request headers: ${dio.options.headers}');
        print('📦 Request body (stringified): ${jsonEncode(requestBody)}');

        // Отправляем тело запроса как строку JSON
        final response = await dio.post(
          '/orders',
          data: requestBody, // Отправляем как Map, без ручной сериализации
          options: Options(
            validateStatus: (status) => true, // Принимаем любой статус
            contentType: 'application/json',
            responseType: ResponseType.plain, // Получаем ответ как текст
          ),
        );

        print('📦 Response status code: ${response.statusCode}');
        print('📦 Response headers: ${response.headers}');
        print('📦 Raw response data type: ${response.data.runtimeType}');
        print('📦 Raw response data: ${response.data}');

        // Проверяем, содержит ли ответ строку с префиксом
        if (response.data is String &&
            response.data.toString().contains('Array to string conversion')) {
          final jsonStr = response.data
              .toString()
              .replaceFirst('Array to string conversion', '');
          print('📦 JSON string after prefix removal: $jsonStr');
          try {
            final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
            print('📦 Parsed JSON: $jsonData');
            final orderId = jsonData['order_id'];
            print('✅ Order created successfully. Order ID: $orderId');
            state = AsyncValue.data(orderId);
            return;
          } catch (e) {
            print('❌ Failed to parse response: $e');
            throw Exception('Failed to parse response: $e');
          }
        } else if (response.statusCode! >= 200 && response.statusCode! < 300) {
          try {
            // Попробуем напрямую разобрать строку ответа как JSON
            if (response.data is String) {
              final jsonData = jsonDecode(response.data.toString());
              print('📦 Directly parsed JSON: $jsonData');
              final orderId = jsonData['order_id'];
              print('✅ Order created successfully. Order ID: $orderId');
              state = AsyncValue.data(orderId);
              return;
            } else {
              // Если это не строка, предполагаем, что это уже объект JSON
              final orderId = response.data['order_id'];
              print('✅ Order created successfully. Order ID: $orderId');
              state = AsyncValue.data(orderId);
              return;
            }
          } catch (e) {
            print('❌ Failed to parse successful response: $e');
            throw Exception('Failed to parse successful response: $e');
          }
        } else {
          print('❌ Request failed with status code: ${response.statusCode}');
          throw Exception('Request failed with status ${response.statusCode}');
        }
      } catch (error) {
        print('❌ Failed to create order with direct approach: $error');
        rethrow;
      }
    } catch (error, stackTrace) {
      print('❌ Failed to create order: $error');
      print('❌ Stack trace: $stackTrace');
      if (error is DioException) {
        print('❌ Response data: ${error.response?.data}');
        print('❌ Response headers: ${error.response?.headers}');
        print('❌ Request data: ${error.requestOptions.data}');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
