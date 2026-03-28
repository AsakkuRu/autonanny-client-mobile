import 'dart:io';

import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_core/api/nanny_chats_api.dart';
import 'package:nanny_core/nanny_core.dart'
    show ImagePicker, ImageSource, XFile;
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';

class ComplaintVM {
  ComplaintVM({
    required this.context,
    required this.update,
    this.orderId,
    this.driverId,
    this.driverName,
  });

  final BuildContext context;
  final void Function(void Function()) update;
  final int? orderId;
  final int? driverId;
  final String? driverName;

  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? selectedReason;
  List<File> attachments = [];
  bool isSubmitting = false;

  final List<String> complaintReasons = [
    'Опасное вождение',
    'Грубое поведение',
    'Опоздание без предупреждения',
    'Несоответствие автомобиля',
    'Ненадлежащее обращение с ребёнком',
    'Отмена поездки без причины',
    'Другое',
  ];

  bool get canSubmit =>
      selectedReason != null && descriptionController.text.trim().isNotEmpty;

  void selectReason(String reason) {
    update(() {
      selectedReason = reason;
    });
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image != null) {
      update(() {
        attachments.add(File(image.path));
      });
    }
  }

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null) {
      update(() {
        attachments.add(File(video.path));
      });
    }
  }

  void removeAttachment(int index) {
    update(() {
      attachments.removeAt(index);
    });
  }

  Future<void> submitComplaint() async {
    if (!canSubmit) return;

    update(() {
      isSubmitting = true;
    });

    final result = await NannyChatsApi.submitComplaint(
      reason: selectedReason!,
      description: descriptionController.text.trim(),
      orderId: orderId,
      driverId: driverId,
      attachmentPaths: attachments.map((f) => f.path).toList(),
    );

    update(() {
      isSubmitting = false;
    });

    if (!context.mounted) return;

    if (result.success) {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Жалоба отправлена',
        message:
            'Мы рассмотрим вашу жалобу в ближайшее время и свяжемся с вами.',
        tone: AutonannyBannerTone.success,
        leading: const AutonannyIcon(AutonannyIcons.checkCircle),
      );
      if (context.mounted) Navigator.pop(context, true);
    } else {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Не удалось отправить жалобу',
        message: result.errorMessage,
        tone: AutonannyBannerTone.danger,
        leading: const AutonannyIcon(AutonannyIcons.warning),
      );
    }
  }

  void dispose() {
    descriptionController.dispose();
  }
}
