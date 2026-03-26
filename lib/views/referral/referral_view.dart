import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanny_client/view_models/referral/referral_vm.dart';

class ReferralView extends StatefulWidget {
  const ReferralView({super.key});

  @override
  State<ReferralView> createState() => _ReferralViewState();
}

class _ReferralViewState extends State<ReferralView> {
  late ReferralVM vm;

  @override
  void initState() {
    super.initState();
    vm = ReferralVM(context: context, update: setState);
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'Реферальная программа',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.chevronLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          variant: AutonannyIconButtonVariant.ghost,
          size: 36,
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AutonannySpacing.lg,
                  AutonannySpacing.sm,
                  AutonannySpacing.lg,
                  AutonannySpacing.xxl,
                ),
                children: [
                  _PromoCard(vm: vm),
                  const SizedBox(height: AutonannySpacing.xl),
                  _PeriodFilter(
                    selected: vm.selectedPeriod,
                    onChanged: vm.changePeriod,
                  ),
                  const SizedBox(height: AutonannySpacing.xl),
                  _StatsGrid(stats: vm.stats),
                  if ((vm.stats?.referrals ?? []).isNotEmpty) ...[
                    const SizedBox(height: AutonannySpacing.xl),
                    _ReferralsSection(vm: vm),
                  ],
                  if ((vm.stats?.bonusHistory ?? []).isNotEmpty) ...[
                    const SizedBox(height: AutonannySpacing.xl),
                    _BonusHistorySection(vm: vm),
                  ],
                  const SizedBox(height: AutonannySpacing.xl),
                  _RulesSection(vm: vm),
                  const SizedBox(height: AutonannySpacing.xl),
                  _ApplyPromoSection(vm: vm),
                ],
              ),
            ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.vm,
  });

  final ReferralVM vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xxl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B4FCF), Color(0xFF4337B8)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(AutonannyRadii.xl)),
      ),
      child: Column(
        children: [
          const AutonannyIcon(
            AutonannyIcons.ticket,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: AutonannySpacing.md),
          Text(
            'Ваш промокод',
            style: AutonannyTypography.bodyS(
              color: const Color(0xB3FFFFFF),
            ),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AutonannySpacing.xxl,
              vertical: AutonannySpacing.md,
            ),
            decoration: BoxDecoration(
              color: const Color(0x21FFFFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              vm.promoCode,
              style: AutonannyTypography.h1(color: Colors.white).copyWith(
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PromoActionButton(
                icon: AutonannyIcons.copy,
                label: 'Копировать',
                onTap: vm.copyCode,
              ),
              const SizedBox(width: AutonannySpacing.xl),
              _PromoActionButton(
                icon: AutonannyIcons.arrowRight,
                label: 'Поделиться',
                onTap: vm.shareCode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoActionButton extends StatelessWidget {
  const _PromoActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AutonannyIconAsset icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0x26FFFFFF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AutonannyIcon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            label,
            style: AutonannyTypography.caption(
              color: const Color(0xCCFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AutonannySegmentedControl<String>(
      value: selected,
      onChanged: onChanged,
      options: const [
        AutonannySegmentedOption(value: 'week', label: 'Неделя'),
        AutonannySegmentedOption(value: 'month', label: 'Месяц'),
        AutonannySegmentedOption(value: 'all', label: 'Всё время'),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stats,
  });

  final ClientReferralStats? stats;

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Приглашено',
                value: '${stats.totalInvited}',
                icon: AutonannyIcons.group,
                iconColor: const Color(0xFF2563EB),
                iconBackground: const Color(0x142563EB),
              ),
            ),
            const SizedBox(width: AutonannySpacing.md),
            Expanded(
              child: _StatCard(
                label: 'Зарегистрировано',
                value: '${stats.registered}',
                icon: AutonannyIcons.verified,
                iconColor: const Color(0xFF4F46E5),
                iconBackground: const Color(0x144F46E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AutonannySpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Активных',
                value: '${stats.active}',
                icon: AutonannyIcons.checkCircle,
                iconColor: const Color(0xFF16A34A),
                iconBackground: const Color(0x1416A34A),
              ),
            ),
            const SizedBox(width: AutonannySpacing.md),
            Expanded(
              child: _StatCard(
                label: 'Бонус за период',
                value: '${stats.periodBonus.toStringAsFixed(0)} ₽',
                icon: AutonannyIcons.wallet,
                iconColor: const Color(0xFF5B4FCF),
                iconBackground: const Color(0x145B4FCF),
              ),
            ),
          ],
        ),
        const SizedBox(height: AutonannySpacing.md),
        AutonannySectionContainer(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0x145B4FCF),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                alignment: Alignment.center,
                child: const AutonannyIcon(
                  AutonannyIcons.wallet,
                  color: Color(0xFF5B4FCF),
                  size: 20,
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.totalBonus.toStringAsFixed(0)} ₽',
                    style: AutonannyTypography.h2(
                      color: context.autonannyColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Всего заработано',
                    style: AutonannyTypography.bodyS(
                      color: context.autonannyColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final String value;
  final AutonannyIconAsset icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return AutonannyCard(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: AutonannyIcon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AutonannyTypography.h3(
              color: context.autonannyColors.textPrimary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AutonannyTypography.caption(
              color: context.autonannyColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralsSection extends StatelessWidget {
  const _ReferralsSection({
    required this.vm,
  });

  final ReferralVM vm;

  @override
  Widget build(BuildContext context) {
    final referrals = vm.stats?.referrals ?? const <ReferralUser>[];
    final format = DateFormat('dd.MM.yyyy');

    return AutonannySectionContainer(
      title: 'Мои рефералы',
      child: Column(
        children: [
          for (var index = 0; index < referrals.length; index++) ...[
            _ReferralTile(
              referral: referrals[index],
              dateText:
                  'Зарегистрирован ${format.format(referrals[index].registeredAt)}',
              statusLabel: vm.statusLabel(referrals[index].status),
              badgeVariant: _statusVariant(referrals[index].status),
            ),
            if (index != referrals.length - 1)
              Divider(
                height: 1,
                color: context.autonannyColors.borderSubtle,
              ),
          ],
        ],
      ),
    );
  }

  AutonannyBadgeVariant _statusVariant(String status) {
    return switch (status) {
      'active' => AutonannyBadgeVariant.success,
      'first_ride' => AutonannyBadgeVariant.info,
      'registered' => AutonannyBadgeVariant.warning,
      _ => AutonannyBadgeVariant.neutral,
    };
  }
}

class _ReferralTile extends StatelessWidget {
  const _ReferralTile({
    required this.referral,
    required this.dateText,
    required this.statusLabel,
    required this.badgeVariant,
  });

  final ReferralUser referral;
  final String dateText;
  final String statusLabel;
  final AutonannyBadgeVariant badgeVariant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AutonannySpacing.md),
      child: Row(
        children: [
          AutonannyAvatar(
            size: 40,
            initials: referral.name.isNotEmpty ? referral.name[0] : '?',
          ),
          const SizedBox(width: AutonannySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.name,
                  style: AutonannyTypography.bodyM(
                    color: context.autonannyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xxs),
                Text(
                  dateText,
                  style: AutonannyTypography.bodyS(
                    color: context.autonannyColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AutonannyBadge(
                label: statusLabel,
                variant: badgeVariant,
              ),
              if (referral.bonusEarned > 0) ...[
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  '+${referral.bonusEarned.toStringAsFixed(0)} ₽',
                  style: AutonannyTypography.labelM(
                    color: context.autonannyColors.statusSuccess,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BonusHistorySection extends StatelessWidget {
  const _BonusHistorySection({
    required this.vm,
  });

  final ReferralVM vm;

  @override
  Widget build(BuildContext context) {
    final history = vm.stats?.bonusHistory ?? const <BonusHistoryItem>[];
    final format = DateFormat('dd.MM.yyyy');

    return AutonannySectionContainer(
      title: 'История начислений',
      trailing: InkWell(
        onTap: vm.toggleBonusHistory,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(AutonannySpacing.xs),
          child: AutonannyIcon(
            vm.showBonusHistory
                ? AutonannyIcons.chevronLeft
                : AutonannyIcons.chevronRight,
            color: context.autonannyColors.textTertiary,
            size: 18,
          ),
        ),
      ),
      child: vm.showBonusHistory
          ? Column(
              children: [
                for (var index = 0; index < history.length; index++) ...[
                  _BonusHistoryTile(
                    item: history[index],
                    dateText: format.format(history[index].date),
                  ),
                  if (index != history.length - 1)
                    Divider(
                      height: 1,
                      color: context.autonannyColors.borderSubtle,
                    ),
                ],
              ],
            )
          : Text(
              'Нажмите, чтобы посмотреть историю начислений по рефералам.',
              style: AutonannyTypography.bodyS(
                color: context.autonannyColors.textTertiary,
              ),
            ),
    );
  }
}

class _BonusHistoryTile extends StatelessWidget {
  const _BonusHistoryTile({
    required this.item,
    required this.dateText,
  });

  final BonusHistoryItem item;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AutonannySpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.autonannyColors.statusSuccessSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AutonannyIcon(
              AutonannyIcons.add,
              color: context.autonannyColors.statusSuccess,
              size: 18,
            ),
          ),
          const SizedBox(width: AutonannySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: AutonannyTypography.bodyS(
                    color: context.autonannyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xxs),
                Text(
                  dateText,
                  style: AutonannyTypography.caption(
                    color: context.autonannyColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.sm),
          Text(
            '+${item.amount.toStringAsFixed(0)} ₽',
            style: AutonannyTypography.labelL(
              color: context.autonannyColors.statusSuccess,
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({
    required this.vm,
  });

  final ReferralVM vm;

  @override
  Widget build(BuildContext context) {
    return AutonannySectionContainer(
      title: 'Как это работает',
      trailing: InkWell(
        onTap: vm.toggleRules,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(AutonannySpacing.xs),
          child: AutonannyIcon(
            vm.showRules
                ? AutonannyIcons.chevronLeft
                : AutonannyIcons.chevronRight,
            color: context.autonannyColors.textTertiary,
            size: 18,
          ),
        ),
      ),
      child: vm.showRules
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _RuleStep(
                  step: '1',
                  text: 'Поделитесь промокодом с друзьями.',
                ),
                const _RuleStep(
                  step: '2',
                  text: 'Друг регистрируется и вводит ваш промокод.',
                ),
                const _RuleStep(
                  step: '3',
                  text: 'Друг получает скидку 15% на первый заказ.',
                ),
                const _RuleStep(
                  step: '4',
                  text: 'Вы получаете 500 ₽ бонуса после его первой поездки.',
                ),
                Divider(
                  height: AutonannySpacing.xl,
                  color: context.autonannyColors.borderSubtle,
                ),
                Text(
                  'Бонусы начисляются автоматически после завершения первой поездки приглашённого пользователя. Их можно использовать для оплаты следующих поездок.',
                  style: AutonannyTypography.bodyS(
                    color: context.autonannyColors.textTertiary,
                  ),
                ),
              ],
            )
          : Text(
              'Покажем правила начисления и условия программы.',
              style: AutonannyTypography.bodyS(
                color: context.autonannyColors.textTertiary,
              ),
            ),
    );
  }
}

class _RuleStep extends StatelessWidget {
  const _RuleStep({
    required this.step,
    required this.text,
  });

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  context.autonannyColors.actionPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: AutonannyTypography.labelM(
                color: context.autonannyColors.actionPrimary,
              ),
            ),
          ),
          const SizedBox(width: AutonannySpacing.md),
          Expanded(
            child: Text(
              text,
              style: AutonannyTypography.bodyM(
                color: context.autonannyColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyPromoSection extends StatelessWidget {
  const _ApplyPromoSection({
    required this.vm,
  });

  final ReferralVM vm;

  @override
  Widget build(BuildContext context) {
    return AutonannySectionContainer(
      title: 'У вас есть промокод?',
      subtitle: 'Введите код, если вам его прислали друзья или партнёры.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AutonannyTextField(
              controller: vm.promoInputController,
              hintText: 'Введите промокод',
              keyboardType: TextInputType.text,
            ),
          ),
          const SizedBox(width: AutonannySpacing.md),
          SizedBox(
            width: 120,
            child: AutonannyButton(
              label: 'Применить',
              onPressed: vm.isApplying ? null : vm.applyPromo,
              isLoading: vm.isApplying,
              size: AutonannyButtonSize.medium,
            ),
          ),
        ],
      ),
    );
  }
}
