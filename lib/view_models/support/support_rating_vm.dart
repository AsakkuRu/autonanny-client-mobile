import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/api/nanny_chats_api.dart';

class SupportRatingVM extends ViewModelBase {
  SupportRatingVM({
    required super.context,
    required super.update,
    required this.ticketId,
    this.onSubmitted,
  });

  final int ticketId;
  final VoidCallback? onSubmitted;

  int rating = 0;
  final TextEditingController commentController = TextEditingController();
  bool isSubmitting = false;

  bool get canSubmit => rating > 0 && !isSubmitting;

  void selectRating(int value) {
    update(() => rating = value + 1);
  }

  Future<void> submitRating() async {
    if (rating == 0) {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Выберите оценку',
        message: 'Пожалуйста, отметьте от 1 до 5 звёзд.',
        tone: AutonannyBannerTone.warning,
        leading: const AutonannyIcon(AutonannyIcons.warning),
      );
      return;
    }

    update(() => isSubmitting = true);

    final result = await NannyChatsApi.rateSupportChat(
      ticketId: ticketId,
      rating: rating,
      comment: commentController.text.trim().isEmpty
          ? null
          : commentController.text.trim(),
    );

    update(() => isSubmitting = false);

    if (!context.mounted) return;

    if (result.success) {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Спасибо за вашу оценку',
        message: 'Ваш отзыв отправлен и поможет нам улучшить поддержку.',
        tone: AutonannyBannerTone.success,
        leading: const AutonannyIcon(AutonannyIcons.checkCircle),
      );
      if (!context.mounted) return;
      onSubmitted?.call();
      Navigator.pop(context, true);
      return;
    }

    await NannyDialogs.showResultSheet(
      context,
      title: 'Не удалось отправить оценку',
      message: result.errorMessage,
      tone: AutonannyBannerTone.danger,
      leading: const AutonannyIcon(AutonannyIcons.warning),
    );
  }

  void skip() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
