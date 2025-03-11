class DetailedColor {
  final int id;
  final Map<String, String> title;
  final String hex;
  final String ral;
  final bool isFavourite;
  final DetailedColor? parentColor;

  DetailedColor({
    required this.id,
    required this.title,
    required this.hex,
    required this.ral,
    this.isFavourite = false,
    this.parentColor,
  });

  factory DetailedColor.fromJson(Map<String, dynamic> json) {
    return DetailedColor(
      id: json['id'] as int,
      title: Map<String, String>.from(json['title'] as Map),
      hex: json['hex'] as String,
      ral: json['ral'] as String,
      isFavourite: json['isFavourite'] as bool? ?? false,
      parentColor: json['parentColor'] != null
          ? DetailedColor.fromJson(json['parentColor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hex': hex,
      'ral': ral,
      'isFavourite': isFavourite,
      'parentColor': parentColor?.toJson(),
    };
  }

  DetailedColor copyWith({
    int? id,
    Map<String, String>? title,
    String? hex,
    String? ral,
    bool? isFavourite,
    DetailedColor? parentColor,
  }) {
    return DetailedColor(
      id: id ?? this.id,
      title: title ?? this.title,
      hex: hex ?? this.hex,
      ral: ral ?? this.ral,
      isFavourite: isFavourite ?? this.isFavourite,
      parentColor: parentColor ?? this.parentColor,
    );
  }
}
