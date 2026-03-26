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
  });

  bool isAutopayEnabled = false;
  List<UserCardData> cards = [];
  int? selectedCardId;

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

    // Загружаем настройки автоплатежей из локального хранилища
    // TODO: Когда будет готов API, загружать с сервера
    final storage = LocalStorage('autopay_settings');
    await storage.ready;
    isAutopayEnabled = storage.getItem('enabled') ?? false;
    final savedCardId = storage.getItem('card_id');
    if (savedCardId != null) {
      selectedCardId = savedCardId;
    }

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

    if (value && selectedCardId == null && cards.isNotEmpty) {
      selectedCardId = cards.first.id;
    }

    isAutopayEnabled = value;

    // Сохраняем в локальное хранилище
    // TODO: Когда будет готов API, сохранять на сервере
    final storage = LocalStorage('autopay_settings');
    await storage.ready;
    await storage.setItem('enabled', value);
    if (selectedCardId != null) {
      await storage.setItem('card_id', selectedCardId);
    }

    update(() {});

    if (!context.mounted) {
      return;
    }
    NannyDialogs.showMessageBox(
      context,
      "Успех",
      value
          ? "Автоплатежи включены. Списание будет происходить еженедельно."
          : "Автоплатежи отключены",
    );
  }

  void selectCard(int cardId) async {
    selectedCardId = cardId;

    // Сохраняем выбор
    final storage = LocalStorage('autopay_settings');
    await storage.ready;
    await storage.setItem('card_id', cardId);

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
}
