class Review {
  final int id;
  final String comment;
  final int rating;
  final String authorName;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.comment,
    required this.rating,
    required this.authorName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      comment: json['comment'] as String,
      rating: json['rating'] as int,
      authorName: json['author_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment': comment,
      'rating': rating,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ReviewsResponse {
  final List<Review> data;
  final ReviewMeta meta;

  ReviewsResponse({
    required this.data,
    required this.meta,
  });

  factory ReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ReviewsResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: ReviewMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((r) => r.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }
}

class ReviewMeta {
  final int currentPage;
  final int lastPage;
  final int total;

  ReviewMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory ReviewMeta.fromJson(Map<String, dynamic> json) {
    return ReviewMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'total': total,
    };
  }
}
