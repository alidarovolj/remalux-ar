class AuthResponse {
  final String accessToken;
  final String tokenType;
  final String expiresIn;
  final Role role;
  final List<dynamic> sections;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.role,
    required this.sections,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      role: Role.fromJson(json['role']),
      sections: json['sections'] ?? [],
    );
  }
}

class Role {
  final int id;
  final String name;
  final String code;

  Role({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }
}
