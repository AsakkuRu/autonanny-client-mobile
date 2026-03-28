import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/autopay_settings_vm.dart';
import 'package:nanny_core/nanny_core.dart';

/// FE-MVP-020: Экран настроек автоматического списания
class AutopaySettingsView extends StatefulWidget {
  const AutopaySettingsView({
    super.key,
    this.scheduleId,
    this.contractTitle,
    this.weeklyAmount,
  });

  final int? scheduleId;
  final String? contractTitle;
  final double? weeklyAmount;

  @override
  State<AutopaySettingsView> createState() => _AutopaySettingsViewState();
}

class _AutopaySettingsViewState extends State<AutopaySettingsView> {
  late final AutopaySettingsVM vm;

  @override
  void initState() {
    super.initState();
    vm = AutopaySettingsVM(
      context: context,
      update: setState,
      scheduleId: widget.scheduleId,
      weeklyAmount: widget.weeklyAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: 'Автоплатежи',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      header: _buildHeader(),
      body: FutureBuilder<bool>(
        future: vm.loadRequest,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(
              label: 'Загружаем настройки автоплатежей.',
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return AutonannyErrorState(
              title: 'Не удалось загрузить данные',
              description: snapshot.error?.toString() ??
                  'Попробуйте открыть настройки ещё раз.',
              actionLabel: 'Повторить',
              onAction: () => vm.reloadPage(),
            );
          }

          return ListView(
            children: [
              const AutonannyInlineBanner(
                title: 'Еженедельное списание',
                message:
                    'Автоматическая оплата будет проходить с выбранной карты раз в неделю.',
                tone: AutonannyBannerTone.info,
                leading: AutonannyIcon(AutonannyIcons.info),
              ),
              if (widget.scheduleId != null) ...[
                const SizedBox(height: AutonannySpacing.lg),
                _buildContractSummary(),
              ],
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Автоматическое списание',
                subtitle:
                    'Включите автоплатежи, чтобы не подтверждать оплату вручную.',
                trailing: AutonannySwitch(
                  value: vm.isAutopayEnabled,
                  onChanged: vm.toggleAutopay,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.autonannyColors.surfaceSecondary,
                        borderRadius: AutonannyRadii.brMd,
                      ),
                      alignment: Alignment.center,
                      child: AutonannyIcon(
                        AutonannyIcons.timer,
                        color: context.autonannyColors.actionPrimary,
                      ),
                    ),
                    const SizedBox(width: AutonannySpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Еженедельная оплата',
                            style: AutonannyTypography.labelL(
                              color: context.autonannyColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AutonannySpacing.xs),
                          Text(
                            vm.isAutopayEnabled
                                ? widget.scheduleId == null
                                    ? 'Списание будет происходить автоматически.'
                                    : 'Списание для этого контракта будет происходить автоматически.'
                                : widget.scheduleId == null
                                    ? 'Сейчас автоплатежи отключены.'
                                    : 'Для этого контракта автоплатежи сейчас отключены.',
                            style: AutonannyTypography.bodyS(
                              color: context.autonannyColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.paymentSchedule?.lastError?.isNotEmpty == true) ...[
                const SizedBox(height: AutonannySpacing.lg),
                AutonannyInlineBanner(
                  title: 'Последняя ошибка списания',
                  message: vm.paymentSchedule!.lastError!,
                  tone: AutonannyBannerTone.warning,
                  leading: const AutonannyIcon(AutonannyIcons.warning),
                ),
              ],
              const SizedBox(height: AutonannySpacing.lg),
              _buildCardsSection(),
              if (widget.scheduleId != null &&
                  vm.paymentSchedule?.paymentHistory.isNotEmpty == true) ...[
                const SizedBox(height: AutonannySpacing.lg),
                _buildPaymentHistorySection(),
              ],
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
                  widget.scheduleId == null
                      ? 'Автоматические списания'
                      : 'Автоплатеж для контракта',
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  widget.scheduleId == null
                      ? 'Настройте карту и дайте приложению оплачивать поездки автоматически.'
                      : 'Выберите карту для автоматических списаний по выбранному контракту.',
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.82),
                  ),
                ),
                if (widget.contractTitle?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AutonannySpacing.sm),
                  Text(
                    widget.contractTitle!.trim(),
                    style: AutonannyTypography.labelM(
                      color: colors.textInverse.withValues(alpha: 0.92),
                    ),
                  ),
                ],
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
              AutonannyIcons.card,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    if (vm.cards.isEmpty) {
      return AutonannyInlineBanner(
        title: 'Нет привязанных карт',
        message: widget.scheduleId == null
            ? 'Добавьте карту, чтобы включить автоплатежи.'
            : 'Добавьте карту, чтобы настроить автоматические списания по этому контракту.',
        tone: AutonannyBannerTone.warning,
        leading: const AutonannyIcon(AutonannyIcons.warning),
        trailing: AutonannyButton(
          label: 'Добавить',
          size: AutonannyButtonSize.medium,
          onPressed: vm.addCard,
          expand: false,
        ),
      );
    }

    return AutonannySectionContainer(
      title: 'Карта для списания',
      subtitle: widget.scheduleId == null
          ? vm.isAutopayEnabled
              ? 'Выберите карту, с которой будет происходить еженедельная оплата.'
              : 'Подготовьте карту заранее, чтобы потом включить автоплатеж без дополнительного шага.'
          : vm.isAutopayEnabled
              ? 'Выберите карту, с которой будут происходить списания по этому контракту.'
              : 'Выберите карту заранее, чтобы быстро включить автоплатеж по этому контракту.',
      trailing: AutonannyButton(
        label: 'Добавить',
        variant: AutonannyButtonVariant.secondary,
        size: AutonannyButtonSize.medium,
        leading: const AutonannyIcon(AutonannyIcons.add),
        onPressed: vm.addCard,
        expand: false,
      ),
      child: Column(
        children: vm.cards
            .asMap()
            .entries
            .map((entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == vm.cards.length - 1
                        ? 0
                        : AutonannySpacing.md,
                  ),
                  child: PaymentMethodCard(
                    data: entry.value.paymentMethodCardData.copyWith(
                      isSelected: vm.selectedCardId == entry.value.id,
                    ),
                    onTap: () => vm.selectCard(entry.value.id),
                  ),
                ))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildContractSummary() {
    final colors = context.autonannyColors;
    final weeklyAmountText = vm.effectiveWeeklyAmount == null
        ? '—'
        : '~ ${vm.effectiveWeeklyAmount!.round()} ₽';

    return AutonannySectionContainer(
      title: 'Состояние автоплатежа',
      subtitle: 'Текущий статус еженедельного автоплатежа по этому контракту.',
      trailing: AutonannyStatusChip(
        label: vm.paymentStatusLabel,
        variant: switch (vm.paymentSchedule?.status) {
          'active' => AutonannyStatusVariant.success,
          'suspended' => AutonannyStatusVariant.warning,
          'failed' => AutonannyStatusVariant.danger,
          'cancelled' => AutonannyStatusVariant.neutral,
          _ => AutonannyStatusVariant.neutral,
        },
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AutopayMetricCard(
                  label: 'В неделю',
                  value: weeklyAmountText,
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: _AutopayMetricCard(
                  label: 'Следующее списание',
                  value: vm.paymentSchedule?.nextPaymentDate ?? '—',
                ),
              ),
            ],
          ),
          if ((vm.paymentSchedule?.failedAttempts ?? 0) > 0) ...[
            const SizedBox(height: AutonannySpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AutonannySpacing.md),
              decoration: BoxDecoration(
                color: colors.statusWarningSurface,
                borderRadius: AutonannyRadii.brLg,
              ),
              child: Text(
                'Неудачных попыток подряд: ${vm.paymentSchedule!.failedAttempts}',
                style: AutonannyTypography.bodyS(
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
          if (vm.paymentSchedule?.lastPaymentDate?.isNotEmpty == true) ...[
            const SizedBox(height: AutonannySpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AutonannySpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AutonannyRadii.brLg,
              ),
              child: Text(
                'Последнее успешное списание: ${vm.paymentSchedule!.lastPaymentDate}',
                style: AutonannyTypography.bodyS(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          if (vm.selectedCardLabel != null) ...[
            const SizedBox(height: AutonannySpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AutonannySpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AutonannyRadii.brLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Карта для списания',
                    style: AutonannyTypography.caption(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AutonannySpacing.xs),
                  Text(
                    vm.selectedCardLabel!,
                    style: AutonannyTypography.labelM(
                      color: colors.textPrimary,
                    ),
                  ),
                  if (vm.selectedCardSubtitle != null) ...[
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      vm.selectedCardSubtitle!,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    final recentHistory = (vm.paymentSchedule?.paymentHistory ??
            const <PaymentScheduleHistoryItem>[])
        .take(5)
        .toList(growable: false);

    return AutonannySectionContainer(
      title: 'Последние автосписания',
      subtitle: 'Недавние попытки списания по этому контракту.',
      child: Column(
        children: recentHistory
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == recentHistory.length - 1
                      ? 0
                      : AutonannySpacing.sm,
                ),
                child: AutonannyListRow(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AutonannySpacing.md,
                    vertical: AutonannySpacing.md,
                  ),
                  title: _historyTitle(entry.value),
                  subtitle: _historySubtitle(entry.value),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _historySurfaceColor(context, entry.value.status),
                      borderRadius: AutonannyRadii.brMd,
                    ),
                    alignment: Alignment.center,
                    child: AutonannyIcon(
                      _historyIcon(entry.value.status),
                      color: _historyIconColor(context, entry.value.status),
                      size: 18,
                    ),
                  ),
                  trailing: AutonannyStatusChip(
                    label: _historyStatusLabel(entry.value.status),
                    variant: _historyStatusVariant(entry.value.status),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String _historyTitle(PaymentScheduleHistoryItem item) {
    final amountLabel = item.amount > 0 ? '${item.amount.round()} ₽' : '—';
    return '${_historyActionLabel(item.status)} · $amountLabel';
  }

  String _historySubtitle(PaymentScheduleHistoryItem item) {
    final parts = <String>[];
    if (item.datetimeCreate?.isNotEmpty == true) {
      parts.add(item.datetimeCreate!);
    }
    if (item.errorMessage?.isNotEmpty == true) {
      parts.add(item.errorMessage!);
    }
    return parts.isEmpty ? 'Без дополнительных деталей' : parts.join('\n');
  }

  String _historyActionLabel(String status) {
    switch (status) {
      case 'success':
      case 'completed':
        return 'Списание прошло';
      case 'failed':
      case 'error':
        return 'Списание не прошло';
      default:
        return 'Попытка списания';
    }
  }

  String _historyStatusLabel(String status) {
    switch (status) {
      case 'success':
      case 'completed':
        return 'Успешно';
      case 'failed':
      case 'error':
        return 'Ошибка';
      default:
        return 'В истории';
    }
  }

  AutonannyStatusVariant _historyStatusVariant(String status) {
    switch (status) {
      case 'success':
      case 'completed':
        return AutonannyStatusVariant.success;
      case 'failed':
      case 'error':
        return AutonannyStatusVariant.danger;
      default:
        return AutonannyStatusVariant.neutral;
    }
  }

  AutonannyIconAsset _historyIcon(String status) {
    switch (status) {
      case 'success':
      case 'completed':
        return AutonannyIcons.checkCircle;
      case 'failed':
      case 'error':
        return AutonannyIcons.warning;
      default:
        return AutonannyIcons.timer;
    }
  }

  Color _historySurfaceColor(BuildContext context, String status) {
    final colors = context.autonannyColors;
    switch (status) {
      case 'success':
      case 'completed':
        return colors.statusSuccessSurface;
      case 'failed':
      case 'error':
        return colors.statusDangerSurface;
      default:
        return colors.surfaceSecondary;
    }
  }

  Color _historyIconColor(BuildContext context, String status) {
    final colors = context.autonannyColors;
    switch (status) {
      case 'success':
      case 'completed':
        return colors.statusSuccess;
      case 'failed':
      case 'error':
        return colors.statusDanger;
      default:
        return colors.actionPrimary;
    }
  }
}

class _AutopayMetricCard extends StatelessWidget {
  const _AutopayMetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AutonannyTypography.labelM(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            value,
            style: AutonannyTypography.h3(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
