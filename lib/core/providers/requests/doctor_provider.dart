import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remalux_ar/core/api/api_client.dart';

class WorkPlace {
  final String name;
  final String address;

  WorkPlace({required this.name, required this.address});

  // Переопределяем оператор == для сравнения по значениям
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkPlace && other.name == name && other.address == address;
  }

  // Переопределяем hashCode
  @override
  int get hashCode => name.hashCode ^ address.hashCode;

  // Добавляем метод fromJson
  factory WorkPlace.fromJson(Map<String, dynamic> json) {
    return WorkPlace(
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }
}

class Price {
  final int main;
  final List<OtherPrice> other;

  Price({
    required this.main,
    required this.other,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      main: json['main'] as int,
      other: (json['other'] as List<dynamic>)
          .map((e) => OtherPrice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OtherPrice {
  final String name;
  final int price;

  OtherPrice({
    required this.name,
    required this.price,
  });

  factory OtherPrice.fromJson(Map<String, dynamic> json) {
    return OtherPrice(
      name: json['name'] as String,
      price: json['price'] as int,
    );
  }
}

class Review {
  final double rating;
  final DateTime date;
  final String review;
  final String author;

  Review({
    required this.rating,
    required this.date,
    required this.review,
    required this.author,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      rating: json['rating'].toDouble(),
      date: DateTime.parse(json['date']),
      review: json['review'] as String,
      author: json['author'] as String,
    );
  }
}

class About {
  final String text;
  final List<String> keyPoints;

  About({
    required this.text,
    required this.keyPoints,
  });

  factory About.fromJson(Map<String, dynamic> json) {
    return About(
      text: json['text'] as String,
      keyPoints: List<String>.from(json['key_points'] as List<dynamic>),
    );
  }
}

class DoctorUser {
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String? email;

  DoctorUser({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.email,
  });

  factory DoctorUser.fromJson(Map<String, dynamic> json) {
    return DoctorUser(
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      email: json['email'] as String?,
    );
  }
}

class DoctorAbout {
  final String description;
  final int experience;
  final String icon;
  final bool isFemale;

  DoctorAbout({
    required this.description,
    required this.experience,
    required this.icon,
    required this.isFemale,
  });

  factory DoctorAbout.fromJson(Map<String, dynamic> json) {
    return DoctorAbout(
      description: json['description'] as String,
      experience: json['experience'] as int,
      icon: json['icon'] as String,
      isFemale: json['is_female'] as bool,
    );
  }

  // Compatibility getters
  String get text => description;
  List<String> get keyPoints => [];
}

class Doctor {
  final int id;
  final DoctorUser user;
  final DoctorAbout about;
  final List<String> specializations;
  final List<String> descriptionItems;

  Doctor({
    required this.id,
    required this.user,
    required this.about,
    required this.specializations,
    required this.descriptionItems,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      user: DoctorUser.fromJson(json['user'] as Map<String, dynamic>),
      about: DoctorAbout.fromJson(json['about'] as Map<String, dynamic>),
      specializations: List<String>.from(json['specializations'] as List),
      descriptionItems: List<String>.from(json['description_items'] as List),
    );
  }

  // Compatibility getters for old fields
  String get stringId => id.toString(); // Add string ID getter
  String get name => fullName;
  String get fullName => '${user.firstName} ${user.lastName}';
  double get rating => 0.0; // Default value since it's not in the new API
  String get avatar => about.icon;
  List<String> get positions => specializations;
  int get experience => about.experience;
  List<WorkPlace> get workPlaces => [
        WorkPlace(
          name: 'Не указано',
          address: 'Не указано',
        )
      ];
  Price get price => Price(
        main: 0,
        other: [],
      );
  List<Review> get reviews => [];
  About get aboutOld => About(
        text: about.description,
        keyPoints: descriptionItems,
      );
  String get qualification => '';
  List<String> get schedule => [];
  DateTime? get availableDatetime => null;
  String get type => '';
}

class DoctorsNotifier extends StateNotifier<AsyncValue<List<Doctor>>> {
  DoctorsNotifier() : super(const AsyncValue.loading()) {
    fetchDoctors();
  }

  final _apiClient = ApiClient();

  Future<void> fetchDoctors() async {
    try {
      print('Fetching doctors...');
      final response = await _apiClient.dio.get('/doctors');
      print('Response: ${response.data}');
      final responseData = response.data as Map<String, dynamic>;
      final List<Doctor> doctors = (responseData['data'] as List)
          .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(doctors);
      print('Doctors fetched successfully.');
    } catch (error, stackTrace) {
      print('Error fetching doctors: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final doctorsProvider =
    StateNotifierProvider<DoctorsNotifier, AsyncValue<List<Doctor>>>(
  (ref) => DoctorsNotifier(),
);
