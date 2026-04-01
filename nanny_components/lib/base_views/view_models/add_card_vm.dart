import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/add_debit_card_request.dart';
import 'package:nanny_core/api/api_models/add_money_request.dart';
import 'package:nanny_core/api/api_models/confirm_payment_request.dart';
import 'package:nanny_core/api/api_models/start_payment_request.dart';
import 'package:nanny_core/api/api_models/start_sbp_payment_request.dart';
import 'package:nanny_core/lifecycle_handler.dart';
import 'package:nanny_core/models/from_api/sbp_init_data.dart';
import 'package:nanny_core/nanny_core.dart';

class AddCardVM extends ViewModelBase {
  AddCardVM({
    required super.context,
    required super.update,
    required this.binding,
    this.existingCardPanDigits = const [],
  });

  final WidgetsBinding binding;

  /// Уже сохранённые PAN (16 цифр) — чтобы не дублировать карту до запроса.
  final List<String> existingCardPanDigits;

  final MaskTextInputFormatter expMask = MaskTextInputFormatter(
    mask: '##/##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final MaskTextInputFormatter cardNumMask = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final GlobalKey<FormState> cardState = GlobalKey();
  final GlobalKey<FormState> fullNameState = GlobalKey();
  final GlobalKey<FormState> expState = GlobalKey();
  final GlobalKey<FormState> emailState = GlobalKey();
  final GlobalKey<FormState> moneyState = GlobalKey();

  String fullname = "";
  String amount = "";
  String email = "";
  // bool rememberCard = false;

  void trySendCardData() async {
    if (!fullNameState.currentState!.validate() ||
        !cardState.currentState!.validate() ||
        !expState.currentState!.validate()) {
      return;
    }

    final pan = cardNumMask.getUnmaskedText();
    if (existingCardPanDigits.contains(pan)) {
      NannyDialogs.showMessageBox(
        context,
        "Внимание",
        "Эта карта уже добавлена.",
      );
      return;
    }

    await LoadScreen.showLoad(context, true);

    bool success = await DioRequest.handleRequest(
      context,
      NannyUsersApi.addDebitCard(
        AddDebitCardRequest(
          cardNumber: pan,
          expDate: expMask.getMaskedText(),
          name: NannyUtils.capitaliseWords(fullname),
        ),
      ),
    );

    if (!context.mounted) return;
    if (!success) {
      await LoadScreen.showLoad(context, false);
      return;
    }

    await LoadScreen.showLoad(context, false);
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }

  void tryPay() async {
    // Валидация формы перед оплатой
    if (!emailState.currentState!.validate() ||
        !moneyState.currentState!.validate()) {
      return;
    }
    
    // Дополнительная проверка минимальной суммы
    final amountValue = int.tryParse(amount);
    if (amountValue == null || amountValue < 100) {
      NannyDialogs.showMessageBox(
          context, "Ошибка", "Минимальная сумма пополнения: 100 ₽");
      return;
    }
    
    LoadScreen.showLoad(context, true);
    var user = NannyUser.userInfo!;
    String? ipv6 = await NetworkInfo().getWifiIPv6();

    String cardData = CardData(
      pan: cardNumMask.getUnmaskedText(),
      expDate: expMask.getUnmaskedText(),
      cardHolder: fullname,
    ).encode(NannyConsts.paymentPublicKey);

    var init = NannyUsersApi.startPayment(
      StartPaymentRequest(
          ip: ipv6 ?? '127.0.0.1',
          amount: int.parse(amount) * 100,
          cardData: cardData,
          email: email,
          phone: user.phone,
          recurrent: "Y"),
    );

    if (!context.mounted) return;

    bool success = await DioRequest.handleRequest(context, init);
    if (!success) return;
    var initRes = (await init).response!;
    int payId = int.tryParse(initRes.paymentId) ?? 0;
    if (!context.mounted) return;
    if (initRes.paymentUrl.isNotEmpty) {
      await _waitForSbpConfirm(
        SbpInitData(
          paymentId: initRes.paymentId,
          paymentUrl: initRes.paymentUrl,
          amount: int.parse(amount),
        ),
      );
    }
    await _addMoney(payId);
  }

  void trySbpPay() async {
    // Валидация формы перед оплатой
    if (!emailState.currentState!.validate() ||
        !moneyState.currentState!.validate()) {
      return;
    }
    
    // Дополнительная проверка минимальной суммы
    final amountValue = int.tryParse(amount);
    if (amountValue == null || amountValue < 100) {
      NannyDialogs.showMessageBox(
          context, "Ошибка", "Минимальная сумма пополнения: 100 ₽");
      return;
    }
    
    LoadScreen.showLoad(context, true);
    var user = NannyUser.userInfo!;

    var init = NannyUsersApi.startSbpPayment(StartSbpPaymentRequest(
        amount: int.parse(amount) * 100, email: email, phone: user.phone));

    bool initSuccess = await DioRequest.handleRequest(context, init);

    if (!initSuccess) return;
    if (!context.mounted) return;
    var initRes = (await init).response!;

    // В демо-режиме paymentUrl пустой, баланс уже пополнен ручкой /demo/balance/topup — не открываем браузер
    if (initRes.paymentUrl.isEmpty) {
      await _addMoney(0);
      return;
    }

    await _waitForSbpConfirm(initRes);
    await _addMoney(int.parse(initRes.paymentId));

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);
  }

  Future<void> _waitForSbpConfirm(SbpInitData data) async {
    Completer<void> completer = Completer();
    var handler = NannyLifecycleHandler(
      resumeCallBack: () async {
        completer.complete();
      },
    );

    binding.addObserver(handler);

    await launchUrl(Uri.parse(data.paymentUrl),
        mode: LaunchMode.inAppBrowserView);

    await completer.future;

    binding.removeObserver(handler);
  }

  Future<void> _addMoney(int payId) async {
    bool addMoneySuccess = await DioRequest.handleRequest(
        context,
        NannyUsersApi.addMoney(
            AddMoneyRequest(amount: int.parse(amount), paymentId: payId)));

    if (!context.mounted) return;
    if (!addMoneySuccess) return;

    LoadScreen.showLoad(context, false);
    await NannyDialogs.showMessageBox(context, "Успех", "Счёт пополнен");
    // ignore: use_build_context_synchronously
    Navigator.pop(context, true);
  }

  bool _checkError(AcquiringResponse request) {
    if (request.success == null ||
        !request.success! ||
        request.errorCode == "101") {
      LoadScreen.showLoad(context, false);
      NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          request.details ??
              request.message ??
              "Произошла неизвестная ошибка!");
      return true;
    }

    return false;
  }
  // void setRememberCard(bool? v) => update(() => rememberCard = v!);
}
