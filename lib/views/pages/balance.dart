import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/balance_vm.dart';
import 'package:nanny_components/nanny_components.dart';
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
          child: RequestLoader(
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: NDT.sp16),
        decoration: NDT.cardDecoration,
        child: Row(
          children: [
            _statItem(
              label: "СПИСАНО",
              value: "${_compact(stats.totalSpent)} ₽",
              sub: "за загруженный период",
            ),
            _statDivider(),
            _statItem(
              label: "ПОЕЗДКИ",
              value: "${stats.tripsCount}",
              sub: "в загруженной истории",
            ),
            _statDivider(),
            _statItem(
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
    required String label,
    required String value,
    required String sub,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: NDT.sectionCaption),
          const SizedBox(height: NDT.sp4),
          Text(value, style: NDT.h3),
          const SizedBox(height: NDT.sp2),
          Text(sub, style: NDT.caption),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 40,
        color: NDT.neutral200,
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
          RequestLoader(
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
            child: Text("Добавьте карту для оплаты", style: NDT.bodyS),
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
          Container(
            decoration: NDT.cardDecoration,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recent.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: NDT.neutral100),
              itemBuilder: (context, index) =>
                  _operationTile(recent[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationTile(History item, int index) {
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
                        ? NDT.primary100
                        : NDT.success.withValues(alpha: 0.1),
                    borderRadius: NDT.brSm,
                  ),
                  child: Icon(
                    isDebit
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 18,
                    color: isDebit ? NDT.primary : NDT.success,
                  ),
                ),
                const SizedBox(width: NDT.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: NDT.bodyM),
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          style: NDT.bodyS,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: NDT.sp8),
                Text(
                  "${item.amount} ₽",
                  style: NDT.labelL.copyWith(
                    color: isDebit ? NDT.neutral700 : NDT.success,
                  ),
                ),
                const SizedBox(width: NDT.sp4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: NDT.neutral400,
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(NDT.sp16, 0, NDT.sp16, NDT.sp12),
      padding: const EdgeInsets.all(NDT.sp12),
      decoration: BoxDecoration(
        color: NDT.neutral50,
        borderRadius: NDT.brMd,
        border: Border.all(color: NDT.neutral200),
      ),
      child: Column(
        children: [
          _detailRow(
            Icons.receipt_long_rounded,
            "Описание",
            item.description.isNotEmpty ? item.description : item.title,
          ),
          _detailDivider(),
          _detailRow(
            Icons.payments_rounded,
            "Сумма",
            "${item.amount} ₽",
            valueColor: isDebit ? NDT.neutral700 : NDT.success,
          ),
          _detailDivider(),
          _detailRow(
            Icons.info_outline_rounded,
            "Тип операции",
            isDebit ? "Списание" : "Пополнение",
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NDT.sp6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: NDT.neutral400),
          const SizedBox(width: NDT.sp8),
          Text(label, style: NDT.bodyS),
          const Spacer(),
          Text(
            value,
            style: NDT.labelL.copyWith(color: valueColor ?? NDT.neutral700),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() => const Divider(height: 1, color: NDT.neutral200);

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader({
    required String title,
    required String action,
    IconData? actionIcon,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: NDT.sectionCaption),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              if (actionIcon != null) ...[
                Icon(actionIcon, size: 14, color: NDT.primary),
                const SizedBox(width: 2),
              ],
              Text(
                action,
                style: NDT.bodyS.copyWith(
                  color: NDT.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
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
