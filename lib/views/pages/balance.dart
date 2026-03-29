import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/balance_vm.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/nanny_core.dart';

class BalanceView extends StatefulWidget {
  final bool persistState;

  const BalanceView({
    super.key,
    this.persistState = false,
  });

  @override
  State<BalanceView> createState() => _BalanceViewState();
}

class _BalanceViewState extends State<BalanceView>
    with AutomaticKeepAliveClientMixin {
  late BalanceVM vm;
  final Set<int> _expandedOps = {};

  @override
  void initState() {
    super.initState();
    vm = BalanceVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    return AutonannyAppScaffold(
      body: AutonannyGradientHeaderShell(
        headerPadding: const EdgeInsets.fromLTRB(
          AutonannySpacing.lg,
          AutonannySpacing.md,
          AutonannySpacing.lg,
          AutonannySpacing.xl,
        ),
        header: _buildHeader(),
        body: RefreshIndicator(
          onRefresh: () async => vm.updateState(),
          child: _ApiResponseLoader<UserMoney>(
            request: vm.getMoney,
            completeView: (context, data) {
              final money = data!;
              final stats = vm.computeStats(money.history);
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  _buildWalletSection(context, money),
                  const SizedBox(height: NDT.sp16),
                  _buildStatsRow(context, stats),
                  const SizedBox(height: NDT.sp16),
                  _buildPaymentMethods(context),
                  const SizedBox(height: NDT.sp16),
                  _buildRecentOperations(context, money.history),
                  const SizedBox(height: 32),
                ],
              );
            },
            errorView: (context, error) => Padding(
              padding: const EdgeInsets.all(AutonannySpacing.xl),
              child: AutonannyErrorState(
                title: 'Не удалось загрузить баланс',
                description: error.toString(),
                actionLabel: 'Повторить',
                onAction: vm.updateState,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Баланс',
          style: AutonannyTypography.h2(color: Colors.white),
        ),
        _HeroActionChip(
          icon: AutonannyIcons.calendar,
          label: 'История',
          onTap: vm.navigateToHistory,
        ),
      ],
    );
  }

  // ─── Balance card ──────────────────────────────────────────────────────────

  Widget _buildWalletSection(BuildContext context, UserMoney money) {
    final colors = context.autonannyColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(NDT.sp16, NDT.sp16, NDT.sp16, 0),
      child: Column(
        children: [
          WalletSummary(
            data: vm.walletSummaryData(money),
            onAction: vm.navigateToWallet,
          ),
          const SizedBox(height: NDT.sp12),
          AutonannyButton(
            label: 'Автоплатежи',
            variant: AutonannyButtonVariant.secondary,
            leading: AutonannyIcon(
              AutonannyIcons.timer,
              size: 18,
              color: colors.actionPrimary,
            ),
            onPressed: vm.navigateToAutopaySettings,
          ),
        ],
      ),
    );
  }

  // ─── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, BalanceStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NDT.sp16),
      child: AutonannyCard(
        padding: const EdgeInsets.symmetric(vertical: NDT.sp16),
        child: Row(
          children: [
            _statItem(
              context: context,
              label: "СПИСАНО",
              value: "${_compact(stats.totalSpent)} ₽",
              sub: "за загруженный период",
            ),
            _statDivider(context),
            _statItem(
              context: context,
              label: "ПОЕЗДКИ",
              value: "${stats.tripsCount}",
              sub: "в загруженной истории",
            ),
            _statDivider(context),
            _statItem(
              context: context,
              label: "СРЕДНЯЯ",
              value: "${_compact(stats.avgPrice)} ₽",
              sub: "по списаниям",
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem({
    required BuildContext context,
    required String label,
    required String value,
    required String sub,
  }) {
    final colors = context.autonannyColors;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AutonannyTypography.caption(
              color: colors.textTertiary,
            ).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: NDT.sp4),
          Text(
            value,
            style: AutonannyTypography.h3(color: colors.textPrimary),
          ),
          const SizedBox(height: NDT.sp2),
          Text(
            sub,
            style: AutonannyTypography.caption(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statDivider(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: context.autonannyColors.borderSubtle,
      );

  String _compact(double v) {
    if (v == 0) return "0";
    if (v >= 1000) {
      return "${(v / 1000).toStringAsFixed(1).replaceAll('.0', '')}к";
    }
    return v.toStringAsFixed(0);
  }

  // ─── Payment methods ───────────────────────────────────────────────────────

  Widget _buildPaymentMethods(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NDT.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: "СПОСОБЫ ОПЛАТЫ",
            action: "Добавить",
            actionIcon: Icons.add_rounded,
            onAction: vm.navigateToWallet,
          ),
          const SizedBox(height: NDT.sp8),
          _ApiResponseLoader<UserCards>(
            request: vm.cardsRequest,
            completeView: (context, data) {
              final cards = data?.cards ?? [];
              if (cards.isEmpty) {
                return _emptyPaymentTile();
              }
              return Column(
                children: cards
                    .map((card) => Padding(
                          padding: const EdgeInsets.only(bottom: NDT.sp8),
                          child: _cardTile(card),
                        ))
                    .toList(),
              );
            },
            errorView: (context, error) => _emptyPaymentTile(),
          ),
        ],
      ),
    );
  }

  Widget _emptyPaymentTile() {
    return AutonannyCard(
      onTap: vm.navigateToWallet,
      child: Row(
        children: [
          AutonannyIcon(AutonannyIcons.card,
              color: context.autonannyColors.textTertiary),
          const SizedBox(width: NDT.sp12),
          Expanded(
            child: Text(
              "Добавьте карту для оплаты",
              style: AutonannyTypography.bodyS(
                color: context.autonannyColors.textSecondary,
              ),
            ),
          ),
          AutonannyIcon(
            AutonannyIcons.chevronRight,
            color: context.autonannyColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _cardTile(UserCardData card) {
    return PaymentMethodCard(
      data: card.paymentMethodCardData,
      onTap: vm.navigateToWallet,
    );
  }

  // ─── Recent operations ─────────────────────────────────────────────────────

  Widget _buildRecentOperations(BuildContext context, List<History> history) {
    if (history.isEmpty) return const SizedBox.shrink();
    final colors = context.autonannyColors;

    final recent = history.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NDT.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: "ПОСЛЕДНИЕ ОПЕРАЦИИ",
            action: "Все",
            onAction: vm.navigateToHistory,
          ),
          const SizedBox(height: NDT.sp8),
          AutonannyCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recent.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colors.borderSubtle),
              itemBuilder: (context, index) =>
                  _operationTile(recent[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationTile(History item, int index) {
    final colors = context.autonannyColors;
    final isDebit = item.amount.contains('-');
    final isExpanded = _expandedOps.contains(index);

    return InkWell(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedOps.remove(index);
        } else {
          _expandedOps.add(index);
        }
      }),
      borderRadius: BorderRadius.vertical(
        top: index == 0 ? const Radius.circular(NDT.radiusLg) : Radius.zero,
      ),
      child: Column(
        children: [
          // ── Collapsed row ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NDT.sp16,
              vertical: NDT.sp12,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDebit
                        ? colors.statusInfoSurface
                        : colors.statusSuccessSurface,
                    borderRadius: AutonannyRadii.brMd,
                  ),
                  child: Icon(
                    isDebit
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 18,
                    color: isDebit
                        ? colors.actionPrimary
                        : colors.statusSuccess,
                  ),
                ),
                const SizedBox(width: NDT.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AutonannyTypography.bodyM(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          style: AutonannyTypography.bodyS(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: NDT.sp8),
                Text(
                  "${item.amount} ₽",
                  style: AutonannyTypography.labelL(
                    color: isDebit
                        ? colors.textPrimary
                        : colors.statusSuccess,
                  ),
                ),
                const SizedBox(width: NDT.sp4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded details ──
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: isExpanded
                ? _operationDetails(item, isDebit)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _operationDetails(History item, bool isDebit) {
    final colors = context.autonannyColors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(NDT.sp16, 0, NDT.sp16, NDT.sp12),
      padding: const EdgeInsets.all(NDT.sp12),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: AutonannyRadii.brMd,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _detailRow(
            context,
            Icons.receipt_long_rounded,
            "Описание",
            item.description.isNotEmpty ? item.description : item.title,
          ),
          _detailDivider(),
          _detailRow(
            context,
            Icons.payments_rounded,
            "Сумма",
            "${item.amount} ₽",
            valueColor:
                isDebit ? colors.textPrimary : colors.statusSuccess,
          ),
          _detailDivider(),
          _detailRow(
            context,
            Icons.info_outline_rounded,
            "Тип операции",
            isDebit ? "Списание" : "Пополнение",
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colors = context.autonannyColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NDT.sp6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textTertiary),
          const SizedBox(width: NDT.sp8),
          Text(
            label,
            style: AutonannyTypography.bodyS(
              color: colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AutonannyTypography.labelL(
              color: valueColor ?? colors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() => Divider(
        height: 1,
        color: context.autonannyColors.borderSubtle,
      );

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader({
    required String title,
    required String action,
    IconData? actionIcon,
    required VoidCallback onAction,
  }) {
    final colors = context.autonannyColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AutonannyTypography.caption(color: colors.textTertiary),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AutonannyRadii.brFull,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AutonannySpacing.sm,
                vertical: AutonannySpacing.xs,
              ),
              child: Row(
                children: [
                  if (actionIcon != null) ...[
                    Icon(actionIcon, size: 14, color: colors.actionPrimary),
                    const SizedBox(width: 2),
                  ],
                  Text(
                    action,
                    style: AutonannyTypography.labelM(
                      color: colors.actionPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}

class _ApiResponseLoader<T> extends StatelessWidget {
  const _ApiResponseLoader({
    required this.request,
    required this.completeView,
    required this.errorView,
  });

  final Future<ApiResponse<T>> request;
  final Widget Function(BuildContext context, T? data) completeView;
  final Widget Function(BuildContext context, Object? error) errorView;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiResponse<T>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AutonannySpacing.xl),
              child: AutonannyLoadingState(label: 'Загружаем данные'),
            ),
          );
        }

        if (snapshot.hasError) {
          return errorView(context, snapshot.error);
        }

        final response = snapshot.data;
        if (response == null || !response.success) {
          return errorView(
            context,
            response?.errorMessage ?? 'Не удалось загрузить данные',
          );
        }

        return completeView(context, response.response);
      },
    );
  }
}

class _HeroActionChip extends StatelessWidget {
  const _HeroActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AutonannyIconAsset icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brFull,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.md,
            vertical: AutonannySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: AutonannyRadii.brFull,
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutonannyIcon(
                icon,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: AutonannySpacing.xs),
              Text(
                label,
                style: AutonannyTypography.labelM(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
