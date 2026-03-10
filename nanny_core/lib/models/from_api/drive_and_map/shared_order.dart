/// D-005: Модели совместного заказа (TASK-D5)
class SharedOrder {
  final int id;
  final List<SharedOrderPassenger> passengers;
  final double totalAmount;
  final int estimatedDurationMinutes;
  final String status;

  SharedOrder({
    required this.id,
    required this.passengers,
    required this.totalAmount,
    required this.estimatedDurationMinutes,
    required this.status,
  });

  factory SharedOrder.fromJson(Map<String, dynamic> json) {
    return SharedOrder(
      id: json['id_order'] ?? json['id'] ?? 0,
      passengers: (json['passengers'] as List? ?? [])
          .map((e) => SharedOrderPassenger.fromJson(e))
          .toList(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      estimatedDurationMinutes: json['estimated_duration'] ?? 0,
      status: json['status'] ?? 'pending',
    );
  }

  factory SharedOrder.mock(int id) {
    return SharedOrder(
      id: id,
      passengers: [
        SharedOrderPassenger(
          clientName: 'Анна К.',
          childName: 'Маша',
          pickupAddress: 'ул. Ленина, 1',
          pickupLat: 55.75,
          pickupLon: 37.61,
          dropoffAddress: 'Школа №5',
          dropoffLat: 55.76,
          dropoffLon: 37.62,
          pickupOrder: 1,
          dropoffOrder: 3,
        ),
        SharedOrderPassenger(
          clientName: 'Сергей П.',
          childName: 'Петя',
          pickupAddress: 'пр. Мира, 5',
          pickupLat: 55.753,
          pickupLon: 37.615,
          dropoffAddress: 'Школа №12',
          dropoffLat: 55.763,
          dropoffLon: 37.625,
          pickupOrder: 2,
          dropoffOrder: 4,
        ),
      ],
      totalAmount: 900.0,
      estimatedDurationMinutes: 45,
      status: 'pending',
    );
  }
}

class SharedOrderPassenger {
  final String clientName;
  final String childName;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLon;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLon;
  final int pickupOrder;
  final int dropoffOrder;

  SharedOrderPassenger({
    required this.clientName,
    required this.childName,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLon,
    required this.pickupOrder,
    required this.dropoffOrder,
  });

  factory SharedOrderPassenger.fromJson(Map<String, dynamic> json) {
    return SharedOrderPassenger(
      clientName: json['client_name'] ?? '',
      childName: json['child_name'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      pickupLat: (json['pickup_lat'] ?? 0).toDouble(),
      pickupLon: (json['pickup_lon'] ?? 0).toDouble(),
      dropoffAddress: json['dropoff_address'] ?? '',
      dropoffLat: (json['dropoff_lat'] ?? 0).toDouble(),
      dropoffLon: (json['dropoff_lon'] ?? 0).toDouble(),
      pickupOrder: json['pickup_order'] ?? 0,
      dropoffOrder: json['dropoff_order'] ?? 0,
    );
  }
}
