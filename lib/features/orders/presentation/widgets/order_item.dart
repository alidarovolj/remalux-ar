import 'package:flutter/material.dart';
import 'package:remalux_ar/core/theme/colors.dart';
import 'package:remalux_ar/features/orders/domain/models/order.dart';

class OrderItem extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderItem({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Заказ от ${order.formattedCreatedAt}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '№${order.id}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Order status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: order.status.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Delivery info
                  Text(
                    'Доставка курьером, ${order.formattedDeliveryDate}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Order total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Товары на ${order.totalAmount} ₸',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${order.itemCount} ${_getPositionText(order.itemCount)}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Product images
            if (order.orderItems.isNotEmpty)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: order.orderItems.length,
                  itemBuilder: (context, index) {
                    final item = order.orderItems[index];

                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: item.displayImage != null
                              ? NetworkImage(item.displayImage!)
                              : const AssetImage(
                                      'lib/core/assets/images/product_placeholder.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 3, // Placeholder for product images
                  itemBuilder: (context, index) {
                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: AssetImage(
                              'lib/core/assets/images/product_placeholder.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getPositionText(int count) {
    // Handle special cases for Russian pluralization
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod10 == 1 && mod100 != 11) {
      return 'позиция';
    } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'позиции';
    } else {
      return 'позиций';
    }
  }
}
