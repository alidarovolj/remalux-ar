import 'package:remalux_ar/features/store/domain/models/product.dart';

class FavoriteProduct {
  final int id;
  final ProductVariant product;

  FavoriteProduct({
    required this.id,
    required this.product,
  });

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] as Map<String, dynamic>;
    final productJson = {
      ...productData,
      'attributes': {'product': productData},
    };

    return FavoriteProduct(
      id: json['id'] as int,
      product: ProductVariant.fromJson(productJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
    };
  }
}

class FavoriteProductsResponse {
  final List<FavoriteProduct> data;

  FavoriteProductsResponse({required this.data});

  factory FavoriteProductsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteProductsResponse(
      data: (json['data'] as List)
          .map((item) => FavoriteProduct.fromJson(item))
          .toList(),
    );
  }
}
