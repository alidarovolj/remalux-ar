import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class Idea {
  final int id;
  final Map<String, String> title;
  final Map<String, String> shortDescription;
  final String? ideaType;
  final ColorTitle colorTitle;
  final RoomTitle roomTitle;
  final String imageUrl;
  final List<List<ContentItem>> values;
  final List<ColorInfo> colors;

  const Idea({
    required this.id,
    required this.title,
    required this.shortDescription,
    this.ideaType,
    required this.colorTitle,
    required this.roomTitle,
    required this.imageUrl,
    required this.values,
    required this.colors,
  });

  factory Idea.fromJson(Map<String, dynamic> json) {
    try {
      return Idea(
        id: json['id'] as int,
        title: _parseTranslations(json['title']),
        shortDescription: _parseTranslations(json['short_description']),
        ideaType: json['idea_type'] as String?,
        colorTitle:
            ColorTitle.fromJson(json['color_title'] as Map<String, dynamic>),
        roomTitle:
            RoomTitle.fromJson(json['room_title'] as Map<String, dynamic>),
        imageUrl: json['image_url'] as String,
        values: (json['values'] as List<dynamic>).map((valueList) {
          return (valueList as List<dynamic>).map((item) {
            return ContentItem.fromJson(item as Map<String, dynamic>);
          }).toList();
        }).toList(),
        colors: (json['colors'] as List<dynamic>)
            .map((color) => ColorInfo.fromJson(color as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, stackTrace) {
      print('Error parsing Idea: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Map<String, String> _parseTranslations(dynamic data) {
    if (data == null) return {};
    if (data is! Map) return {};

    return Map<String, String>.from(data.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? '')));
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
    } catch (e, stackTrace) {
      print('Error parsing ColorTitle: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
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
    } catch (e, stackTrace) {
      print('Error parsing RoomTitle: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
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
    } catch (e, stackTrace) {
      print('Error parsing ContentItem: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
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
    } catch (e, stackTrace) {
      print('Error parsing ColorInfo: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
