class Clinic {
  final String id;
  final String createdAt;
  final String name;
  final String image;
  final Discount discount;
  final String description;
  final Place place;
  final double rating;

  Clinic({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.image,
    required this.discount,
    required this.description,
    required this.place,
    required this.rating,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String,
      createdAt: json['createdAt'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      discount: Discount.fromJson(json['discount'] as Map<String, dynamic>),
      description: json['description'] as String,
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      rating: json['rating'].toDouble(),
    );
  }
}

class Discount {
  final String title;
  final int value;

  Discount({
    required this.title,
    required this.value,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      title: json['title'] as String,
      value: json['value'] as int,
    );
  }
}

class Place {
  final String address;
  final String latitude;
  final String longitude;
  final String distance;

  Place({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      address: json['address'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      distance: json['distance'] as String,
    );
  }
}
