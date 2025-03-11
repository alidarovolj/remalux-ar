class Recipient {
  final int id;
  final String name;
  final String phoneNumber;

  Recipient({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
    };
  }
}
