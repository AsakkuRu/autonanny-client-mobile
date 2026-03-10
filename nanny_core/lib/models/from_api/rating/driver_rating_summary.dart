/// D-002: Модели рейтинга водителя (TASK-D2)
class DriverRatingSummary {
  final double overallRating;
  final int totalReviews;
  final Map<String, double> criteria;
  final Map<int, int> ratingDistribution;
  final List<DriverReview> recentReviews;

  DriverRatingSummary({
    required this.overallRating,
    required this.totalReviews,
    required this.criteria,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory DriverRatingSummary.fromJson(Map<String, dynamic> json) {
    final criteriaRaw = json['criteria'] as Map<String, dynamic>? ?? {};
    final distRaw = json['rating_distribution'] as Map<String, dynamic>? ?? {};

    return DriverRatingSummary(
      overallRating: (json['overall_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      criteria: criteriaRaw.map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ratingDistribution: distRaw.map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v ?? 0) as int)),
      recentReviews: (json['recent_reviews'] as List? ?? [])
          .map((e) => DriverReview.fromJson(e))
          .toList(),
    );
  }

  factory DriverRatingSummary.mock() {
    return DriverRatingSummary(
      overallRating: 4.8,
      totalReviews: 87,
      criteria: {
        'punctuality': 4.9,
        'safety': 4.8,
        'communication': 4.7,
        'vehicle_condition': 4.9,
      },
      ratingDistribution: {5: 58, 4: 21, 3: 6, 2: 1, 1: 1},
      recentReviews: [
        DriverReview(
          id: 1,
          clientName: 'Анна М.',
          rating: 5,
          comment: 'Отличный водитель, всегда вовремя!',
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DriverReview(
          id: 2,
          clientName: 'Сергей К.',
          rating: 5,
          comment: 'Очень аккуратная езда.',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        DriverReview(
          id: 3,
          clientName: 'Ирина П.',
          rating: 4,
          comment: null,
          date: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ],
    );
  }

  Map<String, String> get criteriaLabels => const {
        'punctuality': 'Пунктуальность',
        'safety': 'Безопасность',
        'communication': 'Общение',
        'vehicle_condition': 'Состояние авто',
      };
}

class DriverReview {
  final int id;
  final String clientName;
  final int rating;
  final String? comment;
  final DateTime date;

  DriverReview({
    required this.id,
    required this.clientName,
    required this.rating,
    this.comment,
    required this.date,
  });

  factory DriverReview.fromJson(Map<String, dynamic> json) {
    return DriverReview(
      id: json['id'] ?? 0,
      clientName: json['client_name'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }
}
