class DetailedColorModel {
  final int id;
  final String hex;
  final Map<String, String> title;
  final String ral;
  final ParentColor? parentColor;
  final Catalog catalog;
  final bool isFavourite;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DetailedColorModel({
    required this.id,
    required this.hex,
    required this.title,
    required this.ral,
    this.parentColor,
    required this.catalog,
    required this.isFavourite,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory DetailedColorModel.fromJson(Map<String, dynamic> json) {
    return DetailedColorModel(
      id: json['id'] as int,
      hex: json['hex'] as String,
      title: Map<String, String>.from(json['title'] as Map),
      ral: json['ral'] as String,
      parentColor: json['parent_color'] != null
          ? ParentColor.fromJson(json['parent_color'] as Map<String, dynamic>)
          : null,
      catalog: Catalog.fromJson(json['catalog'] as Map<String, dynamic>),
      isFavourite: json['is_favourite'] as bool,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hex': hex,
      'ral': ral,
      'title': title,
      'parent_color': parentColor?.toJson(),
      'catalog': catalog.toJson(),
      'is_favourite': isFavourite,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
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
      id: json['id'] as int,
      hex: json['hex'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hex': hex,
      'title': title,
    };
  }
}

class Catalog {
  final int id;
  final String title;
  final String code;

  Catalog({
    required this.id,
    required this.title,
    required this.code,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      id: json['id'] as int,
      title: json['title'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'code': code,
    };
  }
}
