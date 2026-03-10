import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class BalanceVM extends ViewModelBase {
  BalanceVM({
    required super.context,
    required super.update,
  });

  Future<String> get currentBalance async =>
      (await _moneyRequest).response!.balance.toString();

  Future<ApiResponse<UserMoney>> get getMoney => _moneyRequest;
  Future<ApiResponse<UserMoney>> _moneyRequest =
      NannyUsersApi.getMoney(period: 'current_year');
  void updateState() => update(() {
        _moneyRequest = NannyUsersApi.getMoney(period: 'current_year');
      });
  void navigateToWallet() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const WalletView(
                title: "Пополнение баланса",
                subtitle: "Выберите способ пополнения",
              )));

  String formatCurrency(double balance) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    String formatted =
        formatter.format(balance).replaceAll(',', ' ').replaceAll('.', ', ');
    return "$formatted Р";
  }
}
