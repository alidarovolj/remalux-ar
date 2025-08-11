import 'package:flutter/foundation.dart';

@immutable
class Idea {
  final int id;
  final Map<String, String> title;
  final Map<String, String> shortDescription;
  final String? ideaType;
  final Map<String, dynamic>? colorTitle;
  final Map<String, dynamic>? roomTitle;
  final String imageUrl;
  final List<List<Map<String, dynamic>>>? values;
  final List<Map<String, dynamic>>? colors;

  const Idea({
    required this.id,
    required this.title,
    required this.shortDescription,
    this.ideaType,
    this.colorTitle,
    this.roomTitle,
    required this.imageUrl,
    this.values,
    this.colors,
  });

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      id: json['id'],
      title: _parseTranslations(json['title']),
      shortDescription: _parseTranslations(json['short_description']),
      ideaType: json['idea_type'],
      colorTitle: json['color_title'],
      roomTitle: json['room_title'],
      imageUrl: json['image_url'],
      values: json['values'] != null
          ? List<List<Map<String, dynamic>>>.from(
              json['values'].map(
                (section) => List<Map<String, dynamic>>.from(
                  section.map((item) => Map<String, dynamic>.from(item)),
                ),
              ),
            )
          : null,
      colors: json['colors'] != null
          ? List<Map<String, dynamic>>.from(
              json['colors'].map((color) => Map<String, dynamic>.from(color)),
            )
          : null,
    );
  }

  static Map<String, String> _parseTranslations(Map<String, dynamic>? json) {
    if (json == null) return {};
    return {
      'ru': json['ru']?.toString() ?? '',
      'kz': json['kz']?.toString() ?? '',
      'en': json['en']?.toString() ?? '',
    };
  }
}

class ColorTitle {
  final int id;
  final Map<String, String> title;
  final String hex;

  const ColorTitle({
    required this.id,
    required this.title,
    required this.hex,
  });

  factory ColorTitle.fromJson(Map<String, dynamic> json) {
    try {
      return ColorTitle(
        id: json['id'] as int,
        title: Idea._parseTranslations({
          'ru': json['ru'],
          'kz': json['kz'],
          'en': json['en'],
        }),
        hex: json['hex'] as String,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class RoomTitle {
  final int id;
  final Map<String, String> title;

  const RoomTitle({
    required this.id,
    required this.title,
  });

  factory RoomTitle.fromJson(Map<String, dynamic> json) {
    try {
      return RoomTitle(
        id: json['id'] as int,
        title: Idea._parseTranslations({
          'ru': json['ru'],
          'kz': json['kz'],
          'en': json['en'],
        }),
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ContentItem {
  final String type;
  final Map<String, dynamic> content;

  const ContentItem({
    required this.type,
    required this.content,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    try {
      return ContentItem(
        type: json['type'] as String,
        content: json['content'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ColorInfo {
  final int id;
  final String hex;
  final String ral;
  final Map<String, String> title;

  const ColorInfo({
    required this.id,
    required this.hex,
    required this.ral,
    required this.title,
  });

  factory ColorInfo.fromJson(Map<String, dynamic> json) {
    try {
      return ColorInfo(
        id: json['id'] as int,
        hex: json['hex'] as String,
        ral: json['ral'] as String,
        title: Idea._parseTranslations(json['title']),
      );
    } catch (e) {
      rethrow;
    }
  }
}
