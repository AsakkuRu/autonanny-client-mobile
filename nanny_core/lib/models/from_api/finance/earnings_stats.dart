/// D-003: Модели статистики заработков водителя (TASK-D3)
class EarningsStats {
  final double totalEarned;
  final double periodEarned;
  final int totalRides;
  final int periodRides;
  final double averageCheck;
  final List<EarningsChartPoint> chartData;
  final List<TopRoute> topRoutes;

  EarningsStats({
    required this.totalEarned,
    required this.periodEarned,
    required this.totalRides,
    required this.periodRides,
    required this.averageCheck,
    required this.chartData,
    required this.topRoutes,
  });

  factory EarningsStats.fromJson(Map<String, dynamic> json) {
    return EarningsStats(
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
      periodEarned: (json['period_earned'] ?? 0).toDouble(),
      totalRides: json['total_rides'] ?? 0,
      periodRides: json['period_rides'] ?? 0,
      averageCheck: (json['average_check'] ?? 0).toDouble(),
      chartData: (json['chart_data'] as List? ?? [])
          .map((e) => EarningsChartPoint.fromJson(e))
          .toList(),
      topRoutes: (json['top_routes'] as List? ?? [])
          .map((e) => TopRoute.fromJson(e))
          .toList(),
    );
  }

  factory EarningsStats.mock() {
    final now = DateTime.now();
    return EarningsStats(
      totalEarned: 145000.0,
      periodEarned: 28500.0,
      totalRides: 320,
      periodRides: 62,
      averageCheck: 460.0,
      chartData: List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return EarningsChartPoint(
          date: date,
          amount: 3000.0 + (i * 300),
          rides: 6 + i,
        );
      }),
      topRoutes: [
        TopRoute(from: 'ул. Ленина, 15', to: 'Школа №42', rides: 28, earned: 9800.0),
        TopRoute(from: 'пр. Мира, 7', to: 'Детсад Солнышко', rides: 21, earned: 7350.0),
        TopRoute(from: 'ул. Садовая, 3', to: 'Школа №1', rides: 15, earned: 5250.0),
      ],
    );
  }
}

class EarningsChartPoint {
  final DateTime date;
  final double amount;
  final int rides;

  EarningsChartPoint({
    required this.date,
    required this.amount,
    required this.rides,
  });

  factory EarningsChartPoint.fromJson(Map<String, dynamic> json) {
    return EarningsChartPoint(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      rides: json['rides'] ?? 0,
    );
  }
}

class TopRoute {
  final String from;
  final String to;
  final int rides;
  final double earned;

  TopRoute({
    required this.from,
    required this.to,
    required this.rides,
    required this.earned,
  });

  factory TopRoute.fromJson(Map<String, dynamic> json) {
    return TopRoute(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      rides: json['rides'] ?? 0,
      earned: (json['earned'] ?? 0).toDouble(),
    );
  }
}
