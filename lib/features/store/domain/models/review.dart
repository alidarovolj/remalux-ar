class Review {
  final int id;
  final String authorName;
  final int rating;
  final String comment;
  final bool isVerified;
  final DateTime createdAt;
  final List<String> images;
  final Map<String, int> helpfulData;
  final bool isUserMarked;

  Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.isVerified,
    required this.createdAt,
    required this.images,
    required this.helpfulData,
    required this.isUserMarked,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      authorName: (json['user'] as Map<String, dynamic>)['name'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      isVerified: json['is_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      images: (json['images'] as List<dynamic>).cast<String>(),
      helpfulData: Map<String, int>.from(json['helpful_data'] as Map),
      isUserMarked: json['is_user_marked'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': {'name': authorName},
      'rating': rating,
      'comment': comment,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'images': images,
      'helpful_data': helpfulData,
      'is_user_marked': isUserMarked,
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
