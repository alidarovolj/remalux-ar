class ColorModel {
  final int id;
  final String hex;
  final Map<String, String> title;

  ColorModel({
    required this.id,
    required this.hex,
    required this.title,
  });

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(
      id: json['id'] as int,
      hex: json['hex'] as String,
      title: Map<String, String>.from(json['title'] as Map),
    );
  }
}
