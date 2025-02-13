class News {
  final int id;
  final Map<String, String> title;
  final Map<String, String> description;
  final Map<String, String>? content;
  final String imageUrl;
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    required this.imageUrl,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as int,
      title: Map<String, String>.from(json['title'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      content: json['content'] != null
          ? Map<String, String>.from(json['content'] as Map)
          : null,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
