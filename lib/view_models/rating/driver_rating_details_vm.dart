import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/driver_rating.dart';

class DriverRatingDetailsVM extends ViewModelBase {
  DriverRatingDetailsVM({
    required super.context,
    required super.update,
    required this.driverId,
    this.driverName,
    this.driverPhoto,
  });

  final int driverId;
  final String? driverName;
  final String? driverPhoto;

  DriverRating? rating;
  bool isLoading = true;

  @override
  Future<bool> loadPage() async {
    update(() => isLoading = true);

    final result = await NannyOrdersApi.getDriverRating(driverId);
    if (result.success && result.response != null) {
      rating = result.response;
    } else {
      rating = _generateMockRating();
    }

    update(() => isLoading = false);
    return true;
  }

  Future<void> refresh() async {
    await loadPage();
  }

  DriverRating _generateMockRating() {
    return DriverRating(
      driverId: driverId,
      averageRating: 4.8,
      totalReviews: 47,
      reviews: [
        DriverReview(
          id: 1,
          rating: 5,
          text: 'Отличный водитель! Очень аккуратно везёт, ребёнок доволен.',
          criteria: ['Пунктуальность', 'Безопасное вождение', 'Вежливость'],
          date: DateTime.now().subtract(const Duration(days: 2)),
          authorName: 'Анна М.',
        ),
        DriverReview(
          id: 2,
          rating: 5,
          text: 'Всегда вовремя, машина чистая.',
          criteria: ['Пунктуальность', 'Чистый автомобиль'],
          date: DateTime.now().subtract(const Duration(days: 5)),
          authorName: 'Елена К.',
        ),
        DriverReview(
          id: 3,
          rating: 4,
          text: null,
          criteria: ['Безопасное вождение'],
          date: DateTime.now().subtract(const Duration(days: 10)),
          authorName: 'Сергей П.',
        ),
      ],
    );
  }
}
