class City {
  final int id;
  final String title;
  final String titleKz;
  final String titleEn;

  City({
    required this.id,
    required this.title,
    required this.titleKz,
    required this.titleEn,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      title: json['title'] as String,
      titleKz: json['title_kz'] as String,
      titleEn: json['title_en'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_kz': titleKz,
      'title_en': titleEn,
    };
  }
}
