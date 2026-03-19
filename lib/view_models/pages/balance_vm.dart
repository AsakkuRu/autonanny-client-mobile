import 'package:flutter/material.dart';
import 'package:nanny_client/views/pages/transactions/transactions_history_view.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:intl/intl.dart';

class BalanceStats {
  final double totalSpent;
  final int tripsCount;
  final double avgPrice;

  BalanceStats({
    required this.totalSpent,
    required this.tripsCount,
    required this.avgPrice,
  });
}

class BalanceVM extends ViewModelBase {
  BalanceVM({
    required super.context,
    required super.update,
  });

  Future<ApiResponse<UserMoney>> _moneyRequest =
      NannyUsersApi.getMoney(period: 'current_year');
  Future<ApiResponse<UserMoney>> get getMoney => _moneyRequest;

  Future<ApiResponse<UserCards>> _cardsRequest = NannyUsersApi.getUserCards();
  Future<ApiResponse<UserCards>> get cardsRequest => _cardsRequest;

  void updateState() => update(() {
        _moneyRequest = NannyUsersApi.getMoney(period: 'current_year');
        _cardsRequest = NannyUsersApi.getUserCards();
      });

  void navigateToWallet() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const WalletView(
                title: "Пополнение баланса",
                subtitle: "Выберите способ пополнения",
              )));

  void navigateToHistory() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const TransactionsHistoryView()));

  void showAutofillDialog() => NannyDialogs.showMessageBox(
        context,
        "Автопополнение",
        "Функция автоматического пополнения баланса находится в разработке. "
            "Скоро она станет доступна.",
      );

  String formatCurrency(double balance) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    String formatted =
        formatter.format(balance).replaceAll(',', ' ').replaceAll('.', ', ');
    return "$formatted ₽";
  }

  BalanceStats computeStats(List<History> history) {
    double total = 0;
    int trips = 0;

    for (final item in history) {
      final clean = item.amount.replaceAll(RegExp(r'[^\d.\-]'), '');
      final amount = double.tryParse(clean) ?? 0;
      if (amount < 0) {
        total += amount.abs();
        if (item.title.toLowerCase().contains('поезд')) {
          trips++;
        }
      }
    }

    final avg = trips > 0 ? total / trips : 0.0;
    return BalanceStats(totalSpent: total, tripsCount: trips, avgPrice: avg);
  }
}
