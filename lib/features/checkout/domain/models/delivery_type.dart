class DeliveryType {
  final int id;
  final Map<String, String> title;

  const DeliveryType({
    required this.id,
    required this.title,
  });

  factory DeliveryType.fromJson(Map<String, dynamic> json) {
    return DeliveryType(
      id: json['id'],
      title: Map<String, String>.from(json['title']),
    );
  }
}
