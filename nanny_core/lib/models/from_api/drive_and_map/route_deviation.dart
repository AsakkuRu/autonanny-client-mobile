class RouteDeviation {
  final int id;
  final int orderId;
  final int driverId;
  final double deviationMeters;
  final DateTime timestamp;
  final double driverLat;
  final double driverLon;
  final double expectedLat;
  final double expectedLon;
  final String? description;

  RouteDeviation({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.deviationMeters,
    required this.timestamp,
    required this.driverLat,
    required this.driverLon,
    required this.expectedLat,
    required this.expectedLon,
    this.description,
  });

  factory RouteDeviation.fromJson(Map<String, dynamic> json) {
    return RouteDeviation(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as int? ?? 0,
      driverId: json['driver_id'] as int? ?? 0,
      deviationMeters: (json['deviation_meters'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      driverLat: (json['driver_lat'] as num?)?.toDouble() ?? 0,
      driverLon: (json['driver_lon'] as num?)?.toDouble() ?? 0,
      expectedLat: (json['expected_lat'] as num?)?.toDouble() ?? 0,
      expectedLon: (json['expected_lon'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'driver_id': driverId,
        'deviation_meters': deviationMeters,
        'timestamp': timestamp.toIso8601String(),
        'driver_lat': driverLat,
        'driver_lon': driverLon,
        'expected_lat': expectedLat,
        'expected_lon': expectedLon,
        if (description != null) 'description': description,
      };
}

class RouteDeviationsResponse {
  final List<RouteDeviation> deviations;
  final int total;

  RouteDeviationsResponse({required this.deviations, required this.total});

  factory RouteDeviationsResponse.fromJson(Map<String, dynamic> json) {
    final items = json['deviations'] as List<dynamic>? ?? [];
    return RouteDeviationsResponse(
      deviations: items
          .map((e) => RouteDeviation.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? items.length,
    );
  }
}
