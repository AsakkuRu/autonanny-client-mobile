import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';

class DriverSpending {
  final String name;
  final double total;
  final int tripCount;
  final Color color;

  const DriverSpending({
    required this.name,
    required this.total,
    required this.tripCount,
    required this.color,
  });
}

class MonthlySpending {
  final String label;
  final double amount;

  const MonthlySpending({required this.label, required this.amount});
}

class SpendingAnalyticsVM extends ViewModelBase {
  SpendingAnalyticsVM({
    required super.context,
    required super.update,
  });

  List<TripHistory> trips = [];
  List<DriverSpending> driverSpendings = [];
  List<MonthlySpending> monthlySpendings = [];
  double totalSpent = 0;
  int totalTrips = 0;
  double averageTrip = 0;
  bool isLoading = true;

  String selectedPeriod = '3 месяца';
  final List<String> periods = ['1 месяц', '3 месяца', '6 месяцев', '1 год'];

  static const _chartColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF43AA8B),
    Color(0xFFFFB347),
    Color(0xFF4FC3F7),
    Color(0xFFE57373),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
  ];

  @override
  Future<bool> loadPage() async {
    update(() => isLoading = true);

    final months = _periodToMonths(selectedPeriod);
    final startDate = DateTime.now().subtract(Duration(days: months * 30));

    final result = await NannyOrdersApi.getTripHistory(
      startDate: startDate,
      endDate: DateTime.now(),
    );

    if (result.success && result.response != null) {
      trips = result.response!.where((t) => t.isCompleted).toList();
    } else {
      trips = [];
    }

    _calculateAnalytics();
    update(() => isLoading = false);
    return true;
  }

  void changePeriod(String period) {
    selectedPeriod = period;
    reloadPage();
  }

  void _calculateAnalytics() {
    totalSpent = trips.fold(0, (sum, t) => sum + (t.price ?? 0));
    totalTrips = trips.length;
    averageTrip = totalTrips > 0 ? totalSpent / totalTrips : 0;

    // Group by driver
    final driverMap = <String, _DriverAcc>{};
    for (final trip in trips) {
      final name = trip.driverName ?? 'Неизвестный';
      driverMap.putIfAbsent(name, () => _DriverAcc());
      driverMap[name]!.total += trip.price ?? 0;
      driverMap[name]!.count++;
    }

    var colorIdx = 0;
    driverSpendings = driverMap.entries
        .map((e) => DriverSpending(
              name: e.key,
              total: e.value.total,
              tripCount: e.value.count,
              color: _chartColors[colorIdx++ % _chartColors.length],
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // Group by month
    final monthMap = <String, double>{};
    for (final trip in trips) {
      final key = '${trip.date.month.toString().padLeft(2, '0')}.${trip.date.year}';
      monthMap.putIfAbsent(key, () => 0);
      monthMap[key] = monthMap[key]! + (trip.price ?? 0);
    }

    final sortedKeys = monthMap.keys.toList()..sort();
    monthlySpendings = sortedKeys
        .map((k) => MonthlySpending(label: k, amount: monthMap[k]!))
        .toList();
  }

  int _periodToMonths(String period) {
    switch (period) {
      case '1 месяц':
        return 1;
      case '3 месяца':
        return 3;
      case '6 месяцев':
        return 6;
      case '1 год':
        return 12;
      default:
        return 3;
    }
  }

  // Исторические мок-данные оставлены только для локальной отладки и не используются в production-логике.
  List<TripHistory> _generateMockData() => [];
}

class _DriverAcc {
  double total = 0;
  int count = 0;
}
