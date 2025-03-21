class RegisterRequest {
  final String name;
  final String phoneNumber;
  final String email;
  final String password;
  final String passwordConfirmation;
  final bool agreement;

  RegisterRequest({
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.agreement,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'agreement': agreement,
    };
  }
}
