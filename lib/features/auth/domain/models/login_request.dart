class LoginRequest {
  final String phoneNumber;
  final String password;

  LoginRequest({
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'password': password,
    };
  }
}
