import 'package:flutter/foundation.dart'; // Import this for VoidCallback

class Category {
  final String name;
  final String iconPath;
  final String? route;
  final VoidCallback onTap;

  Category({
    required this.name,
    required this.iconPath,
    this.route,
    required this.onTap,
  });
}

class SaleCategory extends Category {
  final bool sale;
  final int saleValue;

  SaleCategory(
      {required super.name,
      required super.iconPath,
      required super.route,
      required super.onTap,
      required this.sale,
      required this.saleValue});
}
