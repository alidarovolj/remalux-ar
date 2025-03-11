import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Order {
  final int id;
  final String totalAmount;
  final List<OrderItem> orderItems;
  final String? comments;
  final String deliveryDate;
  final OrderStatus status;
  final String createdAt;
  final bool isPaid;
  final UserAddress userAddress;
  final PaymentMethod paymentMethod;
  final Manager manager;

  Order({
    required this.id,
    required this.totalAmount,
    required this.orderItems,
    this.comments,
    required this.deliveryDate,
    required this.status,
    required this.createdAt,
    required this.isPaid,
    required this.userAddress,
    required this.paymentMethod,
    required this.manager,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['order_items'] != null) {
      items = (json['order_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'],
      totalAmount: json['total_amount'],
      orderItems: items,
      comments: json['comments'],
      deliveryDate: json['delivery_date'],
      status: OrderStatus.fromJson(json['status']),
      createdAt: json['created_at'],
      isPaid: json['is_paid'],
      userAddress: UserAddress.fromJson(json['user_address']),
      paymentMethod: PaymentMethod.fromJson(json['payment_method']),
      manager: Manager.fromJson(json['manager']),
    );
  }

  String get formattedCreatedAt {
    final dateTime = DateTime.parse(createdAt);
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(dateTime);
  }

  String get formattedDeliveryDate {
    final dateTime = DateTime.parse(deliveryDate);
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(dateTime);
  }

  int get itemCount => orderItems.isEmpty ? 3 : orderItems.length;
}

class OrderItem {
  final int? id;
  final String? value;
  final String? sku;
  final int? quantity;
  final String? imageUrl;
  final int? productId;
  final String? productTitle;
  final String? price;
  final String? discountPrice;
  final bool? isFavourite;
  final dynamic rating;
  final Map<String, dynamic>? rawData;

  OrderItem({
    this.id,
    this.value,
    this.sku,
    this.quantity,
    this.imageUrl,
    this.productId,
    this.productTitle,
    this.price,
    this.discountPrice,
    this.isFavourite,
    this.rating,
    this.rawData,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Extract product data if available
    final product = json['product'] as Map<String, dynamic>?;

    return OrderItem(
      id: json['id'],
      value: json['value']?.toString(),
      sku: json['sku'],
      quantity: json['quantity'],
      imageUrl: json['image_url'],
      productId: product?['id'],
      productTitle: product?['title']?['ru'],
      price: json['price']?.toString(),
      discountPrice: json['discount_price']?.toString(),
      isFavourite: json['is_favourite'],
      rating: json['rating'],
      rawData: json, // Store the raw data for future reference
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  String? get displayImage => imageUrl ?? rawData?['product']?['image_url'];
}

class OrderStatus {
  final String code;
  final String title;

  OrderStatus({
    required this.code,
    required this.title,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      code: json['code'],
      title: json['title'],
    );
  }

  Color get color {
    switch (code) {
      case 'delivered':
        return const Color(0xFF4CAF50); // Green
      case 'cancel':
        return const Color(0xFFE53935); // Red
      case 'processing':
        return const Color(0xFFFFA000); // Amber
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  Color get backgroundColor {
    switch (code) {
      case 'delivered':
        return const Color(0xFFE8F5E9); // Light Green
      case 'cancel':
        return const Color(0xFFFFEBEE); // Light Red
      case 'processing':
        return const Color(0xFFFFF8E1); // Light Amber
      default:
        return const Color(0xFFE3F2FD); // Light Blue
    }
  }
}

class UserAddress {
  final int id;
  final String address;
  final String? entrance;
  final String? floor;
  final String? float;
  final City city;
  final Country country;

  UserAddress({
    required this.id,
    required this.address,
    this.entrance,
    this.floor,
    this.float,
    required this.city,
    required this.country,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'],
      address: json['address'],
      entrance: json['entrance'],
      floor: json['floor'],
      float: json['float'],
      city: City.fromJson(json['city']),
      country: Country.fromJson(json['country']),
    );
  }
}

class City {
  final String title;
  final String titleKz;
  final String titleEn;

  City({
    required this.title,
    required this.titleKz,
    required this.titleEn,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      title: json['title'],
      titleKz: json['title_kz'],
      titleEn: json['title_en'],
    );
  }
}

class Country {
  final String title;
  final String titleKz;
  final String titleEn;

  Country({
    required this.title,
    required this.titleKz,
    required this.titleEn,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      title: json['title'],
      titleKz: json['title_kz'],
      titleEn: json['title_en'],
    );
  }
}

class PaymentMethod {
  final int id;
  final String title;
  final String titleKz;
  final String titleEn;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.titleKz,
    required this.titleEn,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      title: json['title'],
      titleKz: json['title_kz'],
      titleEn: json['title_en'],
    );
  }
}

class Manager {
  final int id;
  final String name;

  Manager({
    required this.id,
    required this.name,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'],
      name: json['name'],
    );
  }
}
