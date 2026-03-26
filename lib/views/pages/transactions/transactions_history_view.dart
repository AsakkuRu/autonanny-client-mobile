import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/transactions/transactions_history_vm.dart';
import 'package:nanny_core/models/from_api/transaction.dart';

/// FE-MVP-023: Экран истории финансовых операций
class TransactionsHistoryView extends StatefulWidget {
  const TransactionsHistoryView({
    super.key,
    this.initialTransactionType,
    this.initialSearchQuery,
  });

  final String? initialTransactionType;
  final String? initialSearchQuery;

  @override
  State<TransactionsHistoryView> createState() =>
      _TransactionsHistoryViewState();
}

class _TransactionsHistoryViewState extends State<TransactionsHistoryView> {
  late final TransactionsHistoryVM vm;

  @override
  void initState() {
    super.initState();
    vm = TransactionsHistoryVM(
      context: context,
      update: setState,
      initialTransactionType: widget.initialTransactionType,
      initialSearchQuery: widget.initialSearchQuery,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: 'История операций',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          AutonannyIconButton(
            icon: const AutonannyIcon(AutonannyIcons.settings),
            onPressed: vm.showFilterDialog,
            tooltip: 'Фильтры',
            variant: AutonannyIconButtonVariant.ghost,
            size: 40,
          ),
          const SizedBox(width: AutonannySpacing.xs),
          AutonannyIconButton(
            icon: const AutonannyIcon(AutonannyIcons.document),
            onPressed: vm.exportTransactions,
            tooltip: 'Экспорт',
            variant: AutonannyIconButtonVariant.ghost,
            size: 40,
          ),
        ],
      ),
      header: _buildHeader(),
      body: FutureBuilder<bool>(
        future: vm.loadRequest,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(
              label: 'Загружаем историю финансовых операций.',
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return AutonannyErrorState(
              title: 'Не удалось загрузить историю операций',
              description: snapshot.error?.toString() ??
                  'Попробуйте обновить экран немного позже.',
              actionLabel: 'Повторить',
              onAction: () => vm.reloadPage(),
            );
          }

          if (vm.filteredTransactions.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSearchBar(),
              if (vm.hasActiveFilters) ...[
                const SizedBox(height: AutonannySpacing.md),
                _buildActiveFiltersBanner(),
              ],
              const SizedBox(height: AutonannySpacing.lg),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: vm.filteredTransactions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AutonannySpacing.md),
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
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Финансовая история',
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Все пополнения, оплаты и возвраты в одном месте.',
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.textInverse.withValues(alpha: 0.16),
              borderRadius: AutonannyRadii.brMd,
            ),
            alignment: Alignment.center,
            child: const AutonannyIcon(
              AutonannyIcons.wallet,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AutonannySearchField(
      controller: vm.searchController,
      hintText: 'Поиск по описанию или типу операции',
      leading: Padding(
        padding: const EdgeInsets.only(left: AutonannySpacing.md),
        child: AutonannyIcon(
          AutonannyIcons.search,
          color: context.autonannyColors.textTertiary,
        ),
      ),
      trailing: vm.searchController.text.isNotEmpty
          ? IconButton(
              icon: const AutonannyIcon(AutonannyIcons.close),
              onPressed: vm.clearSearch,
            )
          : null,
      onChanged: vm.onSearchChanged,
    );
  }

  Widget _buildEmptyState() {
    return AutonannyEmptyState(
      title: vm.hasActiveFilters
          ? 'Нет операций по текущему фильтру'
          : 'История операций пока пуста',
      description: vm.hasActiveFilters
          ? 'Сбросьте фильтры или измените параметры поиска.'
          : 'Как только появятся пополнения, оплаты или возвраты, они отобразятся здесь.',
      actionLabel: vm.hasActiveFilters ? 'Сбросить фильтры' : null,
      onAction: vm.hasActiveFilters ? vm.clearFilters : null,
      icon: AutonannyIcon(
        AutonannyIcons.document,
        size: 44,
        color: context.autonannyColors.textTertiary,
      ),
    );
  }

  Widget _buildActiveFiltersBanner() {
    return AutonannyInlineBanner(
      title: 'Активны фильтры истории',
      message: vm.activeFiltersSummary,
      tone: AutonannyBannerTone.info,
      leading: const AutonannyIcon(AutonannyIcons.settings),
      trailing: AutonannyButton(
        label: 'Сбросить',
        variant: AutonannyButtonVariant.secondary,
        size: AutonannyButtonSize.medium,
        expand: false,
        onPressed: vm.clearFilters,
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final colors = context.autonannyColors;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? colors.statusSuccess : colors.statusDanger;

    return AutonannyCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isIncome
                  ? colors.statusSuccessSurface
                  : colors.statusDangerSurface,
              borderRadius: AutonannyRadii.brMd,
            ),
            alignment: Alignment.center,
            child: AutonannyIcon(
              isIncome ? AutonannyIcons.wallet : AutonannyIcons.card,
              color: amountColor,
            ),
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeText,
                  style: AutonannyTypography.labelL(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  transaction.description,
                  style: AutonannyTypography.bodyS(
                    color: colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(transaction.createdAt),
                  style: AutonannyTypography.caption(
                    color: colors.textTertiary,
                  ),
                ),
                if (transaction.status != null &&
                    transaction.status != 'completed') ...[
                  const SizedBox(height: AutonannySpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AutonannyStatusChip(
                      label: transaction.statusText,
                      variant: switch (transaction.status) {
                        'failed' => AutonannyStatusVariant.danger,
                        'pending' => AutonannyStatusVariant.warning,
                        _ => AutonannyStatusVariant.neutral,
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.md),
          Text(
            '${isIncome ? '+' : ''}${NumberFormat('#,##0.00', 'ru_RU').format(transaction.amount)} ₽',
            style: AutonannyTypography.h3(color: amountColor),
          ),
        ],
      ),
    );
  }
}
