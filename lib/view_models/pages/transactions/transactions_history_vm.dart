import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/transaction.dart';
import 'package:nanny_core/nanny_core.dart';

/// FE-MVP-023: ViewModel для истории транзакций
class TransactionsHistoryVM extends ViewModelBase {
  TransactionsHistoryVM({
    required super.context,
    required super.update,
  });

  final TextEditingController searchController = TextEditingController();

  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];
  TransactionFilter filter = TransactionFilter();

  bool isLoadError = false;

  bool get hasActiveFilters {
    return filter.startDate != null ||
        filter.endDate != null ||
        (filter.types != null && filter.types!.isNotEmpty) ||
        filter.minAmount != null ||
        filter.maxAmount != null ||
        (filter.searchQuery != null && filter.searchQuery!.isNotEmpty);
  }

  @override
  Future<bool> loadPage() async {
    isLoadError = false;
    final result = await NannyUsersApi.getTransactions(perPage: 100);
    if (!result.success || result.response == null) {
      isLoadError = true;
      return false;
    }
    allTransactions = result.response!.transactions;
    applyFilters();
    return true;
  }

  void applyFilters() {
    filteredTransactions =
        allTransactions.where((t) => filter.matches(t)).toList();
    filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    update(() {});
  }

  void onSearchChanged(String query) {
    filter = TransactionFilter(
      startDate: filter.startDate,
      endDate: filter.endDate,
      types: filter.types,
      minAmount: filter.minAmount,
      maxAmount: filter.maxAmount,
      searchQuery: query.isEmpty ? null : query,
    );
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  void clearFilters() {
    filter = TransactionFilter();
    searchController.clear();
    applyFilters();
  }

  Future<void> refresh() async {
    await reloadPage();
  }

  void showFilterDialog() {
    NannyDialogs.showMessageBox(
      context,
      "Фильтры",
      "Диалог фильтров будет добавлен в следующей версии",
    );
  }

  void exportTransactions() {
    NannyDialogs.showMessageBox(
      context,
      "Экспорт",
      "Экспорт в PDF/Excel будет добавлен в следующей версии",
    );
  }

  void dispose() {
    searchController.dispose();
  }
}
