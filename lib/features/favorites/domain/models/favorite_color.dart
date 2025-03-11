class FavoriteColor {
  final int id;
  final ColorData color;

  FavoriteColor({
    required this.id,
    required this.color,
  });

  factory FavoriteColor.fromJson(Map<String, dynamic> json) {
    return FavoriteColor(
      id: json['id'],
      color: ColorData.fromJson(json['color']),
    );
  }
}

class ColorData {
  final int id;
  final String hex;
  final Map<String, String> title;
  final String ral;
  final ParentColor parentColor;
  final ColorCatalog catalog;
  final bool isFavourite;

  ColorData({
    required this.id,
    required this.hex,
    required this.title,
    required this.ral,
    required this.parentColor,
    required this.catalog,
    required this.isFavourite,
  });

  factory ColorData.fromJson(Map<String, dynamic> json) {
    return ColorData(
      id: json['id'],
      hex: json['hex'],
      title: Map<String, String>.from(json['title']),
      ral: json['ral'],
      parentColor: ParentColor.fromJson(json['parent_color']),
      catalog: ColorCatalog.fromJson(json['catalog']),
      isFavourite: json['is_favourite'],
    );
  }
}

class ParentColor {
  final int id;
  final String hex;
  final String title;

  ParentColor({
    required this.id,
    required this.hex,
    required this.title,
  });

  factory ParentColor.fromJson(Map<String, dynamic> json) {
    return ParentColor(
      id: json['id'],
      hex: json['hex'],
      title: json['title'],
    );
  }
}

class ColorCatalog {
  final int id;
  final String title;
  final String code;

  ColorCatalog({
    required this.id,
    required this.title,
    required this.code,
  });

  factory ColorCatalog.fromJson(Map<String, dynamic> json) {
    return ColorCatalog(
      id: json['id'],
      title: json['title'],
      code: json['code'],
    );
  }
}

class FavoriteColorsResponse {
  final List<FavoriteColor> data;

  FavoriteColorsResponse({required this.data});

  factory FavoriteColorsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteColorsResponse(
      data: (json['data'] as List)
          .map((item) => FavoriteColor.fromJson(item))
          .toList(),
    );
  }
}
