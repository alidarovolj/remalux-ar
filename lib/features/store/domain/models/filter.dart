import 'package:flutter/foundation.dart';

@immutable
class Filter {
  final int id;
  final Map<String, String> title;
  final List<FilterValue> values;

  const Filter({
    required this.id,
    required this.title,
    required this.values,
  });

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
      id: json['id'] as int,
      title: Map<String, String>.from(json['title']),
      values: (json['values'] as List<dynamic>)
          .map((value) => FilterValue.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FilterValue {
  final int id;
  final Map<String, String> values;

  const FilterValue({
    required this.id,
    required this.values,
  });

  factory FilterValue.fromJson(Map<String, dynamic> json) {
    return FilterValue(
      id: json['id'] as int,
      values: Map<String, String>.from(json['values']),
    );
  }
}
