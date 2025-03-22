import 'package:remalux_ar/features/store/domain/models/product.dart';

class CartItem {
  final int id;
  final String productImage;
  final Map<String, String> productTitle;
  final ProductVariant productVariant;
  final String price;
  final int quantity;
  final Map<String, dynamic>? colorId;

  CartItem({
    required this.id,
    required this.productImage,
    required this.productTitle,
    required this.productVariant,
    required this.price,
    required this.quantity,
    this.colorId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productImage: json['product_image'],
      productTitle: Map<String, String>.from(json['product_title']),
      productVariant: ProductVariant.fromJson(json['product_variant']),
      price: json['price'],
      quantity: json['quantity'],
      colorId: json['color_id'] != null
          ? Map<String, dynamic>.from(json['color_id'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_image': productImage,
      'product_title': productTitle,
      'product_variant': productVariant.toJson(),
      'price': price,
      'quantity': quantity,
      'color_id': colorId,
    };
  }
}
