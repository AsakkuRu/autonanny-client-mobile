import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/rating/driver_order_rating.dart';

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
  bool isInitializing = true;
  bool hasExistingRating = false;
  String? error;

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

  Future<void> loadExistingRating() async {
    update(() {
      isInitializing = true;
      error = null;
    });

    final result = await NannyOrdersApi.getMyDriverRating(orderId);
    if (!result.success) {
      update(() {
        error = result.errorMessage.isNotEmpty
            ? result.errorMessage
            : 'Не удалось загрузить сохраненную оценку.';
        isInitializing = false;
      });
      return;
    }

    final existingRating = result.response;
    if (existingRating != null) {
      _applyExistingRating(existingRating);
    }

    update(() {
      isInitializing = false;
    });
  }

  void _applyExistingRating(DriverOrderRatingData existingRating) {
    hasExistingRating = true;
    rating = existingRating.rating;
    selectedCriteria = List<String>.from(existingRating.criteria);
    reviewController.text = existingRating.review ?? '';
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
    final wasExistingRating = hasExistingRating;

    update(() {
      isSubmitting = true;
      error = null;
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
      hasExistingRating = true;
      NannyDialogs.showMessageBox(
        context,
        'Спасибо!',
        wasExistingRating ? 'Ваша оценка обновлена' : 'Ваша оценка отправлена',
      ).then((_) {
        if (context.mounted) Navigator.pop(context, true);
      });
    } else {
      final errorMessage = result.errorMessage.isNotEmpty
          ? result.errorMessage
          : 'Не удалось сохранить оценку';
      update(() {
        error = errorMessage;
      });
      NannyDialogs.showMessageBox(
        context,
        'Ошибка',
        errorMessage,
      );
    }
  }

  void dispose() {
    reviewController.dispose();
  }
}
