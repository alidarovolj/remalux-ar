import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/core/widgets/custom_button.dart';
import 'package:remalux_ar/features/addresses/domain/models/address.dart';
import 'package:remalux_ar/features/addresses/domain/providers/addresses_provider.dart';
import 'package:remalux_ar/features/cart/domain/providers/cart_providers.dart';
import 'package:remalux_ar/features/checkout/domain/providers/checkout_providers.dart';
import 'package:remalux_ar/features/checkout/presentation/widgets/checkout_skeleton.dart';
import 'package:remalux_ar/features/checkout/presentation/widgets/address_selection_modal.dart';
import 'package:remalux_ar/features/checkout/presentation/widgets/recipient_selection_modal.dart';
import 'package:remalux_ar/features/recipients/domain/providers/recipients_provider.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryTypesAsync = ref.watch(deliveryTypesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final recipientsAsync = ref.watch(recipientsProvider);
    final cartSummary = ref.watch(cartSummaryProvider);
    final orderAsync = ref.watch(orderProvider);
    final validationError = ref.watch(validationErrorProvider);

    final selectedDeliveryType = ref.watch(selectedDeliveryTypeProvider);
    final selectedPaymentMethod = ref.watch(selectedPaymentMethodProvider);
    final selectedAddressId = ref.watch(selectedAddressIdProvider);
    final selectedDeliveryTime = ref.watch(selectedDeliveryTimeProvider);
    final selectedRecipient = ref.watch(selectedRecipientProvider);
    final isOnlinePayment = ref.watch(isOnlinePaymentProvider);

    final addresses = addressesAsync.value ?? [];
    final selectedAddress = addresses.cast<Address>().firstWhereOrNull(
          (address) => address.id.toString() == selectedAddressId,
        );

    // Контроллер для комментария к заказу
    final commentController = TextEditingController();
    // Состояние принятия условий соглашения
    final termsAccepted = ref.watch(termsAcceptedProvider);

    // Если заказ успешно создан
    if (orderAsync.hasValue && orderAsync.value != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'checkout.success.title'.tr(),
          showBottomBorder: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'checkout.success.message'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'checkout.success.order_number'.tr(
                    namedArgs: {'number': orderAsync.value.toString()},
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onPressed: () {
                    // Возврат на главную страницу
                    context.go('/');
                  },
                  label: 'checkout.success.continue_shopping'.tr(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show skeleton while any of the data is loading
    if (deliveryTypesAsync.isLoading ||
        paymentMethodsAsync.isLoading ||
        addressesAsync.isLoading ||
        recipientsAsync.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'checkout.title'.tr(),
          showBottomBorder: true,
        ),
        body: const CheckoutSkeleton(),
      );
    }

    // Show error if any of the requests failed
    if (deliveryTypesAsync.hasError ||
        paymentMethodsAsync.hasError ||
        addressesAsync.hasError ||
        recipientsAsync.hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'checkout.title'.tr(),
          showBottomBorder: true,
        ),
        body: Center(
          child: Text('checkout.error.loading'.tr()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'checkout.title'.tr(),
        showBottomBorder: true,
      ),
      body: Column(
        children: [
          // Показываем ошибку валидации, если она есть
          if (validationError != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      validationError,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      ref.read(validationErrorProvider.notifier).state = null;
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Основное содержимое
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Delivery Type Section
                Text(
                  'checkout.delivery_type.title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.buttonSecondary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B4D8B).withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref
                                  .read(selectedDeliveryTypeProvider.notifier)
                                  .state =
                              deliveryTypesAsync.value
                                  ?.firstWhere((type) => type.id == 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: selectedDeliveryType?.id == 1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: selectedDeliveryType?.id == 1
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF3B4D8B)
                                            .withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'lib/core/assets/icons/cart/truck.svg',
                                  width: 20,
                                  height: 20,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'checkout.delivery_type.courier'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: selectedDeliveryType?.id == 1
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref
                                  .read(selectedDeliveryTypeProvider.notifier)
                                  .state =
                              deliveryTypesAsync.value
                                  ?.firstWhere((type) => type.id == 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: selectedDeliveryType?.id == 2
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: selectedDeliveryType?.id == 2
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF3B4D8B)
                                            .withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.store_outlined,
                                  size: 20,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'checkout.delivery_type.pickup'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: selectedDeliveryType?.id == 2
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Delivery Address Section
                if (selectedDeliveryType?.id == 1) ...[
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'lib/core/assets/icons/cart/truck.svg',
                              width: 20,
                              height: 20,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'checkout.delivery_address.title'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedAddress != null)
                          Text(
                            selectedAddress.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          Text(
                            'checkout.delivery_address.hint'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showAddressSelectionModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.buttonSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'lib/core/assets/icons/cart/edit.svg',
                                  width: 16,
                                  height: 16,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedAddress != null
                                      ? 'checkout.delivery_address.change'.tr()
                                      : 'checkout.delivery_address.add'.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Delivery Time Section
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'lib/core/assets/icons/cart/calendar.svg',
                              width: 20,
                              height: 20,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'checkout.delivery_time.title'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedDeliveryTime != null)
                          Text(
                            DateFormat('EEEE, d MMMM, HH:mm',
                                    context.locale.languageCode)
                                .format(selectedDeliveryTime),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          Text(
                            'checkout.delivery_time.hint'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showDeliveryTimeModal(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.buttonSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'lib/core/assets/icons/cart/edit.svg',
                                  width: 16,
                                  height: 16,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedDeliveryTime != null
                                      ? 'checkout.delivery_time.change'.tr()
                                      : 'checkout.delivery_time.add'.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Recipient Section
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'checkout.recipient.title'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (selectedRecipient != null)
                        Text(
                          '${selectedRecipient.name}, ${selectedRecipient.phoneNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Text(
                          'checkout.recipient.hint'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showRecipientSelectionModal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.buttonSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'lib/core/assets/icons/cart/edit.svg',
                                width: 16,
                                height: 16,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedRecipient != null
                                    ? 'checkout.recipient.change'.tr()
                                    : 'checkout.recipient.add'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method Section
                Text(
                  'checkout.payment.title'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.buttonSecondary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B4D8B).withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(isOnlinePaymentProvider.notifier).state =
                                true;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isOnlinePayment
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isOnlinePayment
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF3B4D8B)
                                            .withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'lib/core/assets/icons/cart/credit.svg',
                                  width: 20,
                                  height: 20,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'checkout.payment.online'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: selectedPaymentMethod?.id == 1
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(isOnlinePaymentProvider.notifier).state =
                                false;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: !isOnlinePayment
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: !isOnlinePayment
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF3B4D8B)
                                            .withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'lib/core/assets/icons/cart/cash.svg',
                                  width: 20,
                                  height: 20,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'checkout.payment.cash'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    fontWeight: selectedPaymentMethod?.id == 2
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Methods List
                if (isOnlinePayment) ...[
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // TODO: Handle Kaspi selection
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                true ? AppColors.buttonSecondary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: true
                                  ? AppColors.primary
                                  : const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'lib/core/assets/icons/cart/kaspi.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'checkout.payment.kaspi'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: selectedPaymentMethod?.id == 3
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (true)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // TODO: Handle Halyk selection
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: false
                                ? AppColors.buttonSecondary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: false
                                  ? AppColors.primary
                                  : const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'lib/core/assets/icons/cart/halyk.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'checkout.payment.halyk'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontWeight: selectedPaymentMethod?.id == 4
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (false)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Comments Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'checkout.comments.placeholder'.tr(),
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Terms and Conditions
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: termsAccepted,
                        onChanged: (value) {
                          ref.read(termsAcceptedProvider.notifier).state =
                              value ?? false;
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'checkout.terms'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bottom Bar with Order Summary
                Container(
                  padding: const EdgeInsets.all(0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'store.cart.summary.title'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'store.cart.summary.products'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${cartSummary.totalAmount} ${'common.currency'.tr()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'store.cart.summary.discount'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${cartSummary.discount} ₸',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'store.cart.summary.total'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${cartSummary.totalAmount} ${'common.currency'.tr()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: orderAsync.maybeWhen(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          orElse: () => CustomButton(
                            onPressed: !termsAccepted
                                ? null
                                : () {
                                    ref
                                        .read(orderProvider.notifier)
                                        .createOrder(
                                          commentController.text,
                                        );
                                  },
                            isEnabled: termsAccepted,
                            label: 'store.cart.summary.continue'.tr(
                              namedArgs: {
                                'count': cartSummary.totalProducts.toString(),
                                'amount': cartSummary.finalAmount.toString()
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddressSelectionModal(),
    );
  }

  void _showDeliveryTimeModal(BuildContext context, WidgetRef ref) {
    DateTime? selectedDateTime = ref.read(selectedDeliveryTimeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: 320,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'common.cancel'.tr(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedDateTime != null) {
                      ref.read(selectedDeliveryTimeProvider.notifier).state =
                          selectedDateTime;
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    'common.confirm'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: selectedDateTime ??
                    DateTime.now().add(const Duration(hours: 1)),
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 7)),
                mode: CupertinoDatePickerMode.dateAndTime,
                use24hFormat: true,
                onDateTimeChanged: (dateTime) {
                  selectedDateTime = dateTime;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipientSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecipientSelectionModal(),
    );
  }
}
