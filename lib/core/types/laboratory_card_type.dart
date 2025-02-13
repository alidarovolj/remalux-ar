class Laboratory {
  final String id;
  final String name;
  final String image;
  final double rating;
  final double distance;
  final int? discount;

  const Laboratory({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.distance,
    this.discount,
  });
}
