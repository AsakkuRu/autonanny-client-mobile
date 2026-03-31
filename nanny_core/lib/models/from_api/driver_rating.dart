class DriverRating {
  final int driverId;
  final double averageRating;
  final int totalReviews;
  final List<DriverReview> reviews;

  DriverRating({
    required this.driverId,
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  factory DriverRating.fromJson(Map<String, dynamic> json) {
    return DriverRating(
      driverId: json['driver_id'] ?? json['id_driver'] ?? 0,
      averageRating: (json['average_rating'] ?? json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? json['reviews_count'] ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => DriverReview.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class DriverReview {
  final int id;
  final int rating;
  final String? text;
  final List<String>? criteria;
  final DateTime date;
  final String? authorName;

  DriverReview({
    required this.id,
    required this.rating,
    this.text,
    this.criteria,
    required this.date,
    this.authorName,
  });

  factory DriverReview.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'];
    List<String>? criteria;
    if (rawCriteria is List) {
      criteria = rawCriteria.map((item) => item.toString()).toList();
    } else if (rawCriteria is Map) {
      criteria = rawCriteria.entries
          .where((entry) => entry.value == true || entry.value == 1)
          .map((entry) => entry.key.toString())
          .toList();
    }

    return DriverReview(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      text: json['text'] ?? json['review'],
      criteria: criteria,
      date: DateTime.tryParse(json['date'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      authorName: json['author_name'] ?? json['author'] ?? json['user_name'],
    );
  }
}
