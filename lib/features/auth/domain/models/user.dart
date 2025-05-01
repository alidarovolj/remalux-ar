import 'package:remalux_ar/features/auth/domain/models/auth_response.dart';

class User {
  final int id;
  final String name;
  final String? email;
  final String phoneNumber;
  final bool isAdmin;
  final String? imageUrl;
  final int cityId;
  final Map<String, String> cityTitle;
  final List<dynamic> sections;
  final Role role;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.phoneNumber,
    required this.isAdmin,
    this.imageUrl,
    required this.cityId,
    required this.cityTitle,
    required this.sections,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      imageUrl: json['image_url'],
      cityId: json['city_id'] ?? 0,
      cityTitle: json['city_title'] != null
          ? Map<String, String>.from(json['city_title'])
          : {},
      sections: json['sections'] ?? [],
      role: Role.fromJson(json['role'] ?? {'id': 0, 'name': '', 'code': ''}),
    );
  }
}
