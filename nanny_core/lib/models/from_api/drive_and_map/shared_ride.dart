class SharedRideOption {
  final int id;
  final String parentName;
  final String? parentPhoto;
  final double driverRating;
  final String addressFrom;
  final String addressTo;
  final String childName;
  final int childAge;
  final String time;
  final double originalPrice;
  final double sharedPrice;
  final double savings;
  final int matchPercent;
  final int seatsAvailable;

  const SharedRideOption({
    required this.id,
    required this.parentName,
    this.parentPhoto,
    this.driverRating = 0,
    required this.addressFrom,
    required this.addressTo,
    required this.childName,
    required this.childAge,
    required this.time,
    required this.originalPrice,
    required this.sharedPrice,
    required this.savings,
    required this.matchPercent,
    this.seatsAvailable = 1,
  });

  factory SharedRideOption.fromJson(Map<String, dynamic> json) {
    final original = (json['original_price'] as num?)?.toDouble() ?? 0;
    final shared = (json['price'] as num?)?.toDouble() ?? (json['shared_price'] as num?)?.toDouble() ?? 0;
    return SharedRideOption(
      id: json['id'] as int? ?? 0,
      parentName: json['parent_name'] as String? ?? json['driver_name'] as String? ?? '',
      parentPhoto: json['parent_photo'] as String? ?? json['driver_photo'] as String?,
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 0,
      addressFrom: json['pickup_address'] as String? ?? json['address_from'] as String? ?? '',
      addressTo: json['dropoff_address'] as String? ?? json['address_to'] as String? ?? '',
      childName: json['child_name'] as String? ?? '',
      childAge: json['child_age'] as int? ?? 0,
      time: json['pickup_time'] as String? ?? json['time'] as String? ?? '',
      originalPrice: original,
      sharedPrice: shared,
      savings: original > 0 && shared > 0 ? original - shared : (json['savings'] as num?)?.toDouble() ?? 0,
      matchPercent: json['route_match_percent'] as int? ?? json['match_percent'] as int? ?? 0,
      seatsAvailable: json['seats_available'] as int? ?? 1,
    );
  }
}

class SharedRidesResponse {
  final List<SharedRideOption> rides;
  final int total;

  SharedRidesResponse({required this.rides, required this.total});

  factory SharedRidesResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? json['rides'] as List<dynamic>? ?? [];
    return SharedRidesResponse(
      rides: items.map((e) => SharedRideOption.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? items.length,
    );
  }
}
