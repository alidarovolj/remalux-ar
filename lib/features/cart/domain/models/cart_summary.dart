class CartSummary {
  final int totalProducts;
  final int totalAmount;
  final int discount;
  final int finalAmount;

  const CartSummary({
    required this.totalProducts,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      totalProducts: json['total_products'] as int,
      totalAmount: json['total_amount'] as int,
      discount: json['discount'] as int,
      finalAmount: json['final_amount'] as int,
    );
  }
}
