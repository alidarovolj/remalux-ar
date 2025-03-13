class LocalizedText {
  final String ru;
  final String kz;
  final String en;

  LocalizedText({
    required this.ru,
    required this.kz,
    required this.en,
  });

  factory LocalizedText.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return LocalizedText(ru: '', kz: '', en: '');
    }
    return LocalizedText(
      ru: json['ru'] as String? ?? '',
      kz: json['kz'] as String? ?? '',
      en: json['en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ru': ru,
      'kz': kz,
      'en': en,
    };
  }
}

class ProjectModel {
  final int id;
  final LocalizedText title;
  final LocalizedText description;
  final List<String> images;
  final String location;
  final int? floors;
  final String? area;
  final int? year;
  final List<String>? features;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.location,
    this.floors,
    this.area,
    this.year,
    this.features,
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProjectModel(
        id: 0,
        title: LocalizedText(ru: '', kz: '', en: ''),
        description: LocalizedText(ru: '', kz: '', en: ''),
        images: [],
        location: '',
        createdAt: DateTime.now(),
      );
    }
    return ProjectModel(
      id: json['id'] as int? ?? 0,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>?),
      description:
          LocalizedText.fromJson(json['description'] as Map<String, dynamic>?),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      location: json['location'] as String? ?? '',
      floors: json['floors'] as int?,
      area: json['area'] as String?,
      year: json['year'] as int?,
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title.toJson(),
      'description': description.toJson(),
      'images': images,
      'location': location,
      'floors': floors,
      'area': area,
      'year': year,
      'features': features,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    int? id,
    LocalizedText? title,
    LocalizedText? description,
    List<String>? images,
    String? location,
    int? floors,
    String? area,
    int? year,
    List<String>? features,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      location: location ?? this.location,
      floors: floors ?? this.floors,
      area: area ?? this.area,
      year: year ?? this.year,
      features: features ?? this.features,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
