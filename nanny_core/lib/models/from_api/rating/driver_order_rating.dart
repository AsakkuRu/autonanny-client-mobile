class DriverOrderRatingData {
  const DriverOrderRatingData({
    required this.orderId,
    required this.driverId,
    required this.rating,
    required this.criteria,
    this.review,
    this.createdAt,
  });

  final int orderId;
  final int driverId;
  final int rating;
  final List<String> criteria;
  final String? review;
  final DateTime? createdAt;

  factory DriverOrderRatingData.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'] as List? ?? const [];
    final rawCreatedAt = json['datetime_create']?.toString();

    return DriverOrderRatingData(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      driverId: (json['driver_id'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      criteria: rawCriteria
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      review: json['review']?.toString(),
      createdAt:
          rawCreatedAt != null && rawCreatedAt.isNotEmpty
              ? DateTime.tryParse(rawCreatedAt)
              : null,
    );
  }
}
