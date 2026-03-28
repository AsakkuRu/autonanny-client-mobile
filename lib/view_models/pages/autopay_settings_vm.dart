import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/views/add_card.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/nanny_core.dart';

/// FE-MVP-020: ViewModel для настроек автоплатежей
class AutopaySettingsVM extends ViewModelBase {
  AutopaySettingsVM({
    required super.context,
    required super.update,
    this.scheduleId,
    this.weeklyAmount,
  });

  final int? scheduleId;
  final double? weeklyAmount;
  bool isAutopayEnabled = false;
  List<UserCardData> cards = [];
  int? selectedCardId;
  PaymentScheduleData? paymentSchedule;

  String get _storageKey => scheduleId == null
      ? 'autopay_settings'
      : 'autopay_settings_schedule_$scheduleId';

  bool get isContractMode => scheduleId != null;

  bool get canEnableContractAutopay {
    return effectiveWeeklyAmount != null && effectiveWeeklyAmount! > 0;
  }

  double? get effectiveWeeklyAmount {
    if (paymentSchedule != null && paymentSchedule!.amount > 0) {
      return paymentSchedule!.amount;
    }
    if (weeklyAmount != null && weeklyAmount! > 0) {
      return weeklyAmount;
    }
    return null;
  }

  bool get hasRecentPaymentHistory {
    return paymentSchedule?.paymentHistory.isNotEmpty == true;
  }

  UserCardData? get selectedCard {
    final cardId = selectedCardId;
    if (cardId == null) {
      return null;
    }
    for (final card in cards) {
      if (card.id == cardId) {
        return card;
      }
    }
    return null;
  }

  String? get selectedCardLabel {
    final card = selectedCard;
    if (card == null) {
      return null;
    }

    final bank = switch (card.bank.toLowerCase()) {
      'visa' => 'Visa',
      'mir' => 'Мир',
      'mastercard' => 'Mastercard',
      _ => card.bank.isEmpty ? 'Карта' : card.bank,
    };

    if (card.cardNumber.isEmpty) {
      return bank;
    }

    return '$bank · ${card.cardNumber}';
  }

  String? get selectedCardSubtitle {
    final card = selectedCard;
    if (card == null) {
      return null;
    }

    if (card.expDate.isNotEmpty) {
      return 'Срок действия до ${card.expDate}';
    }

    return 'Карта выбрана для автоматических списаний';
  }

  String get paymentStatusLabel {
    final status = paymentSchedule?.status;
    switch (status) {
      case 'active':
        return 'Активен';
      case 'suspended':
        return 'Приостановлен';
      case 'cancelled':
        return 'Отключён';
      case 'failed':
        return 'Ошибка списания';
      default:
        return 'Не настроен';
    }
  }

  @override
  Future<bool> loadPage() async {
    // Загружаем список карт
    final cardsResult = await NannyUsersApi.getUserCards();
    if (cardsResult.success && cardsResult.response != null) {
      cards = cardsResult.response!.cards;

      // Если есть карты, выбираем первую по умолчанию
      if (cards.isNotEmpty && selectedCardId == null) {
        selectedCardId = cards.first.id;
      }
    }

    if (isContractMode) {
      final scheduleResult =
          await NannyUsersApi.getPaymentSchedule(scheduleId!);
      if (!scheduleResult.success) {
        return false;
      }

      paymentSchedule = scheduleResult.response;
      isAutopayEnabled = paymentSchedule?.status == 'active';
      if (paymentSchedule?.cardId != null) {
        selectedCardId = paymentSchedule!.cardId;
      }
    } else {
      // Загружаем настройки автоплатежей из локального хранилища
      final storage = LocalStorage(_storageKey);
      await storage.ready;
      isAutopayEnabled = storage.getItem('enabled') ?? false;
      final savedCardId = storage.getItem('card_id');
      if (savedCardId != null) {
        selectedCardId = savedCardId;
      }
    }

    _normalizeSelectedCard();

    return true;
  }

  void toggleAutopay(bool value) async {
    if (value && cards.isEmpty) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Сначала добавьте карту для автоплатежей",
      );
      return;
    }

    if (isContractMode && value && !canEnableContractAutopay) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Не удалось определить сумму еженедельного списания для этого контракта.",
      );
      return;
    }

    if (value && selectedCardId == null && cards.isNotEmpty) {
      selectedCardId = cards.first.id;
    }

    if (isContractMode) {
      if (value) {
        final result = await NannyUsersApi.createDemoAutopaySchedule(
          scheduleId: scheduleId!,
          amount: effectiveWeeklyAmount!,
          cardId: selectedCardId,
        );
        if (!result.success) {
          if (context.mounted) {
            NannyDialogs.showMessageBox(
              context,
              "Ошибка",
              result.errorMessage,
            );
          }
          return;
        }

        paymentSchedule = result.response;
        isAutopayEnabled = true;
        await _reloadContractPaymentSchedule();
      } else {
        final result = await NannyUsersApi.cancelPaymentSchedule(scheduleId!);
        if (!result.success) {
          if (context.mounted) {
            NannyDialogs.showMessageBox(
              context,
              "Ошибка",
              result.errorMessage,
            );
          }
          return;
        }

        paymentSchedule = paymentSchedule?.copyWith(
          status: 'cancelled',
          nextPaymentDate: null,
          lastError: null,
        );
        isAutopayEnabled = false;
        await _reloadContractPaymentSchedule();
      }
    } else {
      isAutopayEnabled = value;

      final storage = LocalStorage(_storageKey);
      await storage.ready;
      await storage.setItem('enabled', value);
      if (selectedCardId != null) {
        await storage.setItem('card_id', selectedCardId);
      }
    }

    update(() {});

    if (!context.mounted) {
      return;
    }
    NannyDialogs.showMessageBox(
      context,
      "Успех",
      value
          ? paymentSchedule?.nextPaymentDate?.isNotEmpty == true
              ? "Автоплатежи включены. Следующее списание: ${paymentSchedule!.nextPaymentDate}."
              : "Автоплатежи включены. Списание будет происходить еженедельно."
          : "Автоплатежи отключены",
    );
  }

  void selectCard(int cardId) async {
    selectedCardId = cardId;

    if (isContractMode && isAutopayEnabled && canEnableContractAutopay) {
      final result = await NannyUsersApi.createDemoAutopaySchedule(
        scheduleId: scheduleId!,
        amount: effectiveWeeklyAmount!,
        cardId: cardId,
      );
      if (result.success) {
        paymentSchedule = result.response;
        await _reloadContractPaymentSchedule();
      } else if (context.mounted) {
        NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          result.errorMessage,
        );
      }
    } else {
      final storage = LocalStorage(_storageKey);
      await storage.ready;
      await storage.setItem('card_id', cardId);
    }

    update(() {});
  }

  void addCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCardView(),
      ),
    );

    if (result == true) {
      // Перезагружаем список карт
      reloadPage();
    }
  }

  void _normalizeSelectedCard() {
    if (cards.isEmpty) {
      selectedCardId = null;
      return;
    }

    if (selectedCardId == null ||
        !cards.any((card) => card.id == selectedCardId)) {
      selectedCardId = cards.first.id;
    }
  }

  Future<void> _reloadContractPaymentSchedule() async {
    if (!isContractMode) {
      return;
    }

    final scheduleResult = await NannyUsersApi.getPaymentSchedule(scheduleId!);
    if (!scheduleResult.success) {
      return;
    }

    paymentSchedule = scheduleResult.response;
    isAutopayEnabled = paymentSchedule?.status == 'active';
    if (paymentSchedule?.cardId != null) {
      selectedCardId = paymentSchedule!.cardId;
    }
    _normalizeSelectedCard();
  }
}
