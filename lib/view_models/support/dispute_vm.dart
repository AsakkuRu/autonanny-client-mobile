import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_core/api/nanny_chats_api.dart';

class DisputeVM {
  DisputeVM({
    required this.context,
    required this.update,
    required this.orderId,
    required this.amount,
    required this.route,
  });

  final BuildContext context;
  final void Function(void Function()) update;
  final int orderId;
  final double amount;
  final String route;

  final TextEditingController descriptionController = TextEditingController();

  String? selectedReason;
  bool isSubmitting = false;

  final List<String> reasons = const [
    'Неверная сумма списания',
    'Двойное списание',
    'Заказ был отменён',
    'Качество услуги не соответствует',
    'Другое',
  ];

  void selectReason(String reason) {
    update(() {
      selectedReason = reason;
    });
  }

  Future<void> submitDispute() async {
    if (selectedReason == null) {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Выберите причину',
        message: 'Укажите причину оспаривания, чтобы отправить обращение.',
        tone: AutonannyBannerTone.warning,
        leading: const AutonannyIcon(AutonannyIcons.warning),
      );
      return;
    }

    update(() {
      isSubmitting = true;
    });

    final result = await NannyChatsApi.submitComplaint(
      reason: 'Платежный спор: $selectedReason',
      description: _buildDescription(),
      orderId: orderId,
    );

    update(() {
      isSubmitting = false;
    });

    if (!context.mounted) return;

    if (result.success) {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Обращение отправлено',
        message:
            'Мы передали спор в поддержку. Обычно финансовые обращения рассматриваются в течение 3 рабочих дней.',
        tone: AutonannyBannerTone.success,
        leading: const AutonannyIcon(AutonannyIcons.checkCircle),
      );
      if (context.mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    await NannyDialogs.showResultSheet(
      context,
      title: 'Не удалось отправить обращение',
      message: result.errorMessage,
      tone: AutonannyBannerTone.danger,
      leading: const AutonannyIcon(AutonannyIcons.warning),
    );
  }

  String _buildDescription() {
    final extraComment = descriptionController.text.trim();
    final lines = <String>[
      'Тип обращения: финансовый спор',
      'Причина: $selectedReason',
      'Заказ: #$orderId',
      'Сумма операции: ${_formatAmount(amount)} ₽',
      'Описание операции: $route',
    ];

    if (extraComment.isNotEmpty) {
      lines.add('Комментарий клиента: $extraComment');
    }

    return lines.join('\n');
  }

  String _formatAmount(double value) {
    final normalized = value.abs();
    if (normalized == normalized.roundToDouble()) {
      return normalized.toStringAsFixed(0);
    }
    return normalized.toStringAsFixed(2);
  }

  void dispose() {
    descriptionController.dispose();
  }
}
