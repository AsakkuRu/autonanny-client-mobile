import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/pages/transactions/transactions_history_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/transaction.dart';
import 'package:intl/intl.dart';

/// FE-MVP-023: Экран истории финансовых операций
class TransactionsHistoryView extends StatefulWidget {
  const TransactionsHistoryView({super.key});

  @override
  State<TransactionsHistoryView> createState() => _TransactionsHistoryViewState();
}

class _TransactionsHistoryViewState extends State<TransactionsHistoryView> {
  late TransactionsHistoryVM vm;

  @override
  void initState() {
    super.initState();
    vm = TransactionsHistoryVM(context: context, update: setState);
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f7),
      appBar: NannyAppBar(
        title: 'История операций',
        color: const Color(0xFFf7f7f7),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: vm.showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: vm.exportTransactions,
          ),
        ],
      ),
      body: FutureLoader(
        future: vm.loadRequest,
        completeView: (context, data) {
          if (!data) {
            return const ErrorView(
              errorText: 'Не удалось загрузить историю операций',
            );
          }

          if (vm.filteredTransactions.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Поиск
              _buildSearchBar(),
              
              // Список транзакций
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = vm.filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
                ),
              ),
            ],
          );
        },
        errorView: (context, error) => ErrorView(errorText: error.toString()),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: vm.searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по описанию...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: vm.searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: vm.clearSearch,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: vm.onSearchChanged,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            vm.hasActiveFilters
                ? 'Нет операций по фильтру'
                : 'История операций пуста',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          if (vm.hasActiveFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: vm.clearFilters,
              child: const Text('Сбросить фильтры'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Иконка
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                if (transaction.status != null && transaction.status != 'completed') ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: transaction.status == 'failed'
                          ? const Color(0xFFF44336)
                          : const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Сумма
          Text(
            '${isIncome ? '+' : ''}${NumberFormat('#,##0.00', 'ru_RU').format(transaction.amount)} ₽',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
