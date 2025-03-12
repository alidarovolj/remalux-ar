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
      title: json['title'] as String,
      titleKz: json['title_kz'] as String,
      titleEn: json['title_en'] as String,
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
      title: json['title'] as String,
      titleKz: json['title_kz'] as String,
      titleEn: json['title_en'] as String,
    );
  }
}

class Address {
  final int id;
  final String address;
  final String? entrance;
  final String? floor;
  final String? apartment;
  final double latitude;
  final double longitude;
  final City city;
  final Country country;

  Address({
    required this.id,
    required this.address,
    this.entrance,
    this.floor,
    this.apartment,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int,
      address: json['address'] as String,
      entrance: json['entrance'] as String?,
      floor: json['floor'] as String?,
      apartment: json['apartment'] as String?,
      latitude: json['latitude'] as double? ?? 0.0,
      longitude: json['longitude'] as double? ?? 0.0,
      city: City.fromJson(json['city'] as Map<String, dynamic>),
      country: Country.fromJson(json['country'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'entrance': entrance,
      'floor': floor,
      'apartment': apartment,
      'latitude': latitude,
      'longitude': longitude,
      'city': {
        'title': city.title,
        'title_kz': city.titleKz,
        'title_en': city.titleEn,
      },
      'country': {
        'title': country.title,
        'title_kz': country.titleKz,
        'title_en': country.titleEn,
      },
    };
  }

  Address copyWith({
    int? id,
    String? address,
    String? entrance,
    String? floor,
    String? apartment,
    double? latitude,
    double? longitude,
    City? city,
    Country? country,
  }) {
    return Address(
      id: id ?? this.id,
      address: address ?? this.address,
      entrance: entrance ?? this.entrance,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}
