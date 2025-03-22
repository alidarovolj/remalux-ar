class PaymentMethod {
  final int id;
  final Map<String, String> title;

  const PaymentMethod({
    required this.id,
    required this.title,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      title: Map<String, String>.from(json['title']),
    );
  }
}
