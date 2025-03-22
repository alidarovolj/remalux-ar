class ProductVariant {
  final int id;
  final String title;
  final String description;
  final String value;
  final String price;
  final String image;
  final bool isFavourite;

  ProductVariant({
    required this.id,
    required this.title,
    required this.description,
    required this.value,
    required this.price,
    required this.image,
    this.isFavourite = false,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      value: json['value'] as String? ?? '',
      price: (json['price'] as num?)?.toString() ?? '',
      image: json['image'] as String? ?? '',
      isFavourite: json['isFavourite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'value': value,
      'price': price,
      'image': image,
      'isFavourite': isFavourite,
    };
  }

  ProductVariant copyWith({
    int? id,
    String? title,
    String? description,
    String? value,
    String? price,
    String? image,
    bool? isFavourite,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      value: value ?? this.value,
      price: price ?? this.price,
      image: image ?? this.image,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}
