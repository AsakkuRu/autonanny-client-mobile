import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';

class DriverRatingVM {
  DriverRatingVM({
    required this.context,
    required this.update,
    required this.orderId,
    this.driverName,
    this.driverPhoto,
  });

  final BuildContext context;
  final void Function(void Function()) update;
  final int orderId;
  final String? driverName;
  final String? driverPhoto;

  int rating = 0;
  List<String> selectedCriteria = [];
  TextEditingController reviewController = TextEditingController();
  bool isSubmitting = false;

  final List<String> availableCriteria = [
    'Пунктуальность',
    'Безопасное вождение',
    'Чистый автомобиль',
    'Вежливость',
    'Забота о ребёнке',
    'Хорошая коммуникация',
  ];

  String get ratingText {
    switch (rating) {
      case 1:
        return 'Ужасно';
      case 2:
        return 'Плохо';
      case 3:
        return 'Нормально';
      case 4:
        return 'Хорошо';
      case 5:
        return 'Отлично!';
      default:
        return 'Выберите оценку';
    }
  }

  void setRating(int value) {
    update(() {
      rating = value;
    });
  }

  void toggleCriterion(String criterion) {
    update(() {
      if (selectedCriteria.contains(criterion)) {
        selectedCriteria.remove(criterion);
      } else {
        selectedCriteria.add(criterion);
      }
    });
  }

  Future<void> submitRating() async {
    if (rating == 0) return;

    update(() {
      isSubmitting = true;
    });

    final result = await NannyOrdersApi.rateDriver(
      orderId: orderId,
      rating: rating,
      criteria: selectedCriteria.isNotEmpty ? selectedCriteria : null,
      review: reviewController.text.trim().isNotEmpty
          ? reviewController.text.trim()
          : null,
    );

    update(() {
      isSubmitting = false;
    });

    if (!context.mounted) return;

    if (result.success) {
      NannyDialogs.showMessageBox(
        context,
        'Спасибо!',
        'Ваша оценка отправлена',
      ).then((_) {
        if (context.mounted) Navigator.pop(context, true);
      });
    } else {
      NannyDialogs.showMessageBox(
        context,
        'Ошибка',
        result.errorMessage,
      );
    }
  }
}
