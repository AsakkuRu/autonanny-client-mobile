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
      NannyDialogs.showMessageBox(
          context, 'Выберите оценку', 'Пожалуйста, отметьте от 1 до 5 звёзд');
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
      Navigator.pop(context);
      onSubmitted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Спасибо за вашу оценку!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    NannyDialogs.showMessageBox(
      context,
      'Не удалось отправить оценку',
      result.errorMessage,
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
