class TripHistory {
  final int id;
  final DateTime date;
  final String addressFrom;
  final String addressTo;
  final String? driverName;
  final String? driverPhoto;
  final int? driverId;
  final double? price;
  final String status;
  final int? rating;
  final int? durationMinutes;
  final double? distanceKm;

  TripHistory({
    required this.id,
    required this.date,
    required this.addressFrom,
    required this.addressTo,
    this.driverName,
    this.driverPhoto,
    this.driverId,
    this.price,
    required this.status,
    this.rating,
    this.durationMinutes,
    this.distanceKm,
  });

  factory TripHistory.fromJson(Map<String, dynamic> json) {
    return TripHistory(
      id: json['id'] ?? json['id_order'] ?? 0,
      date: DateTime.tryParse(json['date'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      addressFrom: json['address_from'] ?? json['from'] ?? '',
      addressTo: json['address_to'] ?? json['to'] ?? '',
      driverName: json['driver_name'] ?? json['driver']?['name'],
      driverPhoto: json['driver_photo'] ?? json['driver']?['photo'],
      driverId: json['driver_id'] ?? json['id_driver'],
      price: (json['price'] ?? json['amount'])?.toDouble(),
      status: json['status'] ?? 'completed',
      rating: json['rating'],
      durationMinutes: json['duration_minutes'] ?? json['duration'],
      distanceKm: json['distance_km']?.toDouble() ?? json['distance']?.toDouble(),
    );
  }

  String get statusText {
    switch (status) {
      case 'completed':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      case 'cancelled_by_driver':
        return 'Отменена водителем';
      case 'cancelled_by_client':
        return 'Отменена вами';
      case 'active':
        return 'Активна';
      case 'in_progress':
        return 'В процессе';
      case 'created':
        return 'Создана';
      case 'scheduled':
        return 'Запланирована';
      case 'driver_assigned':
        return 'Назначен водитель';
      default:
        return status;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status.contains('cancelled');
}
