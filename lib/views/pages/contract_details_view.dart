import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/views/pages/autopay_settings.dart';
import 'package:nanny_client/views/rating/driver_rating_details_view.dart';
import 'package:nanny_components/base_views/views/pages/wallet.dart';
import 'package:nanny_components/dialogs/nanny_dialogs.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';
import 'package:nanny_core/nanny_core.dart';

typedef PauseContractAction = Future<bool> Function(
  String dateFrom,
  String dateUntil,
  String reason,
);

class ContractDetailsView extends StatelessWidget {
  const ContractDetailsView({
    super.key,
    required this.schedule,
    required this.summaryData,
    required this.dayPanels,
    this.contractChildren = const [],
    this.driverContact,
    this.responsesCount = 0,
    this.onOpenSchedule,
    this.onEditContract,
    this.editLockedMessage,
    this.onPauseContract,
    this.onCancelContract,
    this.onResumeContract,
    this.onCallDriver,
    this.onOpenDriverProfile,
    this.onOpenChat,
    this.onShowQr,
  });

  final Schedule schedule;
  final ContractSummaryCardData summaryData;
  final List<ContractDayPanelData> dayPanels;
  final List<Child> contractChildren;
  final DriverContact? driverContact;
  final int responsesCount;
  final VoidCallback? onOpenSchedule;
  final VoidCallback? onEditContract;
  final String? editLockedMessage;
  final PauseContractAction? onPauseContract;
  final Future<bool> Function()? onCancelContract;
  final Future<bool> Function()? onResumeContract;
  final VoidCallback? onCallDriver;
  final VoidCallback? onOpenDriverProfile;
  final VoidCallback? onOpenChat;
  final VoidCallback? onShowQr;

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: schedule.title.isEmpty ? 'Контракт' : schedule.title,
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AutonannySpacing.xl),
        children: [
          ContractSummaryCard(
            data: summaryData,
          ),
          if (schedule.isPaused == true) ...[
            const SizedBox(height: AutonannySpacing.lg),
            _PausedContractBanner(
              schedule: schedule,
              onResumeContract: onResumeContract,
            ),
          ],
          const SizedBox(height: AutonannySpacing.lg),
          if (driverContact != null)
            Column(
              children: [
                AssignedDriverCard(
                  data: driverContact!.assignedDriverCardData,
                  onPrimaryAction: onOpenChat,
                  onSecondaryAction:
                      schedule.isPaused == true ? null : onShowQr,
                ),
                if (onCallDriver != null) ...[
                  const SizedBox(height: AutonannySpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: AutonannyButton(
                      label: 'Позвонить водителю',
                      variant: AutonannyButtonVariant.secondary,
                      onPressed: onCallDriver,
                    ),
                  ),
                ],
                const SizedBox(height: AutonannySpacing.md),
                Row(
                  children: [
                    if (onOpenDriverProfile != null)
                      Expanded(
                        child: AutonannyButton(
                          label: 'Профиль водителя',
                          variant: AutonannyButtonVariant.secondary,
                          onPressed: onOpenDriverProfile,
                        ),
                      ),
                    if (onOpenDriverProfile != null)
                      const SizedBox(width: AutonannySpacing.md),
                    Expanded(
                      child: AutonannyButton(
                        label: 'Отзывы и рейтинг',
                        variant: AutonannyButtonVariant.secondary,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DriverRatingDetailsView(
                                driverId: driverContact!.id,
                                driverName: driverContact!.fullName,
                                driverPhoto: driverContact!.photo,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            AutonannyInlineBanner(
              title: responsesCount > 0
                  ? 'Есть отклики от водителей'
                  : 'Водитель еще не назначен',
              message: responsesCount > 0
                  ? 'В контракте уже есть отклики. Вы сможете выбрать водителя в расписании.'
                  : 'Контракт сохранен, сейчас система ищет подходящего водителя.',
              tone: responsesCount > 0
                  ? AutonannyBannerTone.info
                  : AutonannyBannerTone.warning,
              leading: AutonannyIcon(
                responsesCount > 0
                    ? AutonannyIcons.people
                    : AutonannyIcons.warning,
              ),
            ),
          const SizedBox(height: AutonannySpacing.lg),
          if (contractChildren.isNotEmpty) ...[
            _ContractChildrenSection(
              schedule: schedule,
              children: contractChildren,
            ),
            const SizedBox(height: AutonannySpacing.lg),
          ],
          if (schedule.otherParametrs.isNotEmpty) ...[
            _ContractServicesSection(schedule: schedule),
            const SizedBox(height: AutonannySpacing.lg),
          ],
          const AutonannyInlineBanner(
            title: 'Маршруты и дни поездок',
            message:
                'Ниже показана детальная структура контракта по дням и маршрутам.',
            tone: AutonannyBannerTone.info,
            leading: AutonannyIcon(AutonannyIcons.calendar),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          if (dayPanels.isEmpty)
            const AutonannyInlineBanner(
              title: 'Маршруты пока не настроены',
              message:
                  'Для этого контракта пока нет маршрутов, поэтому детали появятся после их добавления.',
              tone: AutonannyBannerTone.warning,
              leading: AutonannyIcon(AutonannyIcons.warning),
            )
          else
            ...dayPanels.map(
              (panel) => Padding(
                padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
                child: ContractDayPanel(data: panel),
              ),
            ),
          const SizedBox(height: AutonannySpacing.sm),
          Row(
            children: [
              if (onOpenSchedule != null)
                Expanded(
                  child: AutonannyButton(
                    label: 'Открыть расписание',
                    onPressed: onOpenSchedule,
                  ),
                ),
              if (onOpenSchedule != null && onEditContract != null)
                const SizedBox(width: AutonannySpacing.md),
              if (onEditContract != null)
                Expanded(
                  child: AutonannyButton(
                    label: 'Редактировать',
                    variant: AutonannyButtonVariant.secondary,
                    onPressed: onEditContract,
                  ),
                ),
            ],
          ),
          if (editLockedMessage != null) ...[
            const SizedBox(height: AutonannySpacing.md),
            AutonannyInlineBanner(
              title: 'Редактирование недоступно',
              message: editLockedMessage!,
              tone: AutonannyBannerTone.warning,
              leading: const AutonannyIcon(AutonannyIcons.warning),
            ),
          ],
          if (onPauseContract != null && schedule.isPaused != true) ...[
            const SizedBox(height: AutonannySpacing.md),
            AutonannyButton(
              label: 'Поставить на паузу',
              variant: AutonannyButtonVariant.secondary,
              onPressed: () async {
                final request = await _showPauseContractRequest(context);
                if (request == null || !context.mounted) {
                  return;
                }
                final paused = await onPauseContract!(
                  request.dateFrom,
                  request.dateUntil,
                  request.reason,
                );
                if (paused && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
          if (onCancelContract != null) ...[
            const SizedBox(height: AutonannySpacing.md),
            AutonannyButton(
              label: 'Расторгнуть контракт',
              variant: AutonannyButtonVariant.danger,
              onPressed: () async {
                final cancelled = await onCancelContract!.call();
                if (cancelled && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractChildrenSection extends StatelessWidget {
  const _ContractChildrenSection({
    required this.schedule,
    required this.children,
  });

  final Schedule schedule;
  final List<Child> children;

  @override
  Widget build(BuildContext context) {
    return AutonannySectionContainer(
      title: 'Дети в контракте',
      subtitle: 'Кто привязан к контракту и в какие дни участвует в поездках.',
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            _ContractChildTile(
              child: children[i],
              schedule: schedule,
            ),
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AutonannySpacing.md),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _ContractServicesSection extends StatelessWidget {
  const _ContractServicesSection({
    required this.schedule,
  });

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final servicesTotal = schedule.otherParametrs.fold<double>(
      0,
      (sum, param) => sum + _serviceTotal(param),
    );

    return AutonannySectionContainer(
      title: 'Дополнительные услуги',
      subtitle: 'Услуги, которые включены в этот контракт.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AutonannySpacing.sm,
            runSpacing: AutonannySpacing.sm,
            children: schedule.otherParametrs
                .map(
                  (param) => AutonannyBadge(
                    label: _serviceLabel(param),
                    variant: AutonannyBadgeVariant.info,
                  ),
                )
                .toList(growable: false),
          ),
          if (servicesTotal > 0) ...[
            const SizedBox(height: AutonannySpacing.md),
            Text(
              'Итого по услугам: ${servicesTotal.round()} ₽ в неделю',
              style: AutonannyTypography.bodyS(
                color: context.autonannyColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _serviceLabel(OtherParametr param) {
    final title = (param.title ?? 'Доп. услуга').trim();
    final total = _serviceTotal(param);
    final suffix = <String>[
      if (param.count != null && param.count! > 0) 'x${param.count}',
      if (param.amount != null && param.amount! > 0)
        '${param.amount!.round()} ₽/шт',
      if (total > 0) 'итого ${total.round()} ₽',
    ];
    if (suffix.isEmpty) {
      return title;
    }
    return '$title • ${suffix.join(' • ')}';
  }

  double _serviceTotal(OtherParametr param) {
    return (param.amount ?? 0) * (param.count ?? 0);
  }
}

class _ContractChildTile extends StatelessWidget {
  const _ContractChildTile({
    required this.child,
    required this.schedule,
  });

  final Child child;
  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final imageUrl = (child.photoPath?.isNotEmpty ?? false)
        ? NannyConsts.buildFileUrl(child.photoPath)
        : null;
    final image =
        imageUrl == null || imageUrl.isEmpty ? null : NetworkImage(imageUrl);
    final routeCount = _routesForChild.length;
    final subtitleParts = <String>[
      child.ageDisplay,
      if (child.schoolClass?.isNotEmpty ?? false) child.schoolClass!,
    ];
    final daysLabel = _weekdayLabels.join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutonannyAvatar(
              image: image,
              initials: child.fullName.isNotEmpty ? child.fullName[0] : 'Р',
              size: 56,
            ),
            const SizedBox(width: AutonannySpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: AutonannyTypography.labelL(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AutonannySpacing.xs),
                  Text(
                    subtitleParts.join(' · '),
                    style: AutonannyTypography.bodyS(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AutonannySpacing.sm),
            AutonannyBadge(
              label: '$routeCount ${_routeWord(routeCount)}',
              variant: AutonannyBadgeVariant.info,
            ),
          ],
        ),
        const SizedBox(height: AutonannySpacing.md),
        Wrap(
          spacing: AutonannySpacing.sm,
          runSpacing: AutonannySpacing.sm,
          children: [
            AutonannyBadge(
              label: daysLabel.isEmpty ? 'Дни не выбраны' : daysLabel,
              variant: AutonannyBadgeVariant.neutral,
            ),
          ],
        ),
        if (_routeLabels.isNotEmpty) ...[
          const SizedBox(height: AutonannySpacing.md),
          Text(
            'Маршруты ребенка',
            style: AutonannyTypography.caption(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Wrap(
            spacing: AutonannySpacing.sm,
            runSpacing: AutonannySpacing.sm,
            children: _routeLabels
                .map(
                  (label) => AutonannyBadge(
                    label: label,
                    variant: AutonannyBadgeVariant.info,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (child.characterNotes?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: AutonannySpacing.md),
          AutonannyInlineBanner(
            title: 'Особенности ребенка',
            message: child.characterNotes!.trim(),
            tone: AutonannyBannerTone.info,
            leading: const AutonannyIcon(AutonannyIcons.info),
          ),
        ],
      ],
    );
  }

  List<Road> get _routesForChild {
    final childId = child.id;
    if (childId == null) {
      return const <Road>[];
    }
    return schedule.roads
        .where((road) => (road.children ?? const <int>[]).contains(childId))
        .toList(growable: false);
  }

  List<String> get _weekdayLabels {
    return _routesForChild
        .map((road) => road.weekDay.shortName)
        .toSet()
        .toList(growable: false);
  }

  List<String> get _routeLabels {
    return _routesForChild.map(_formatRouteLabel).toList(growable: false);
  }

  String _formatRouteLabel(Road road) {
    final parts = <String>[
      road.weekDay.shortName,
      road.startTime.formatTime(),
      if (road.title.trim().isNotEmpty) road.title.trim(),
    ];
    return parts.join(' · ');
  }

  String _routeWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'маршрут';
    }
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'маршрута';
    }
    return 'маршрутов';
  }
}

class _PauseContractRequest {
  const _PauseContractRequest({
    required this.dateFrom,
    required this.dateUntil,
    required this.reason,
  });

  final String dateFrom;
  final String dateUntil;
  final String reason;
}

Future<_PauseContractRequest?> _showPauseContractRequest(
  BuildContext context,
) async {
  final now = DateTime.now();
  final dateFrom = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
    helpText: 'Пауза с',
    cancelText: 'Отмена',
    confirmText: 'Далее',
  );
  if (dateFrom == null || !context.mounted) {
    return null;
  }

  final suggestedUntil = dateFrom.add(const Duration(days: 7));
  final dateUntil = await showDatePicker(
    context: context,
    initialDate: suggestedUntil,
    firstDate: dateFrom,
    lastDate: dateFrom.add(const Duration(days: 365)),
    helpText: 'Пауза до',
    cancelText: 'Отмена',
    confirmText: 'Далее',
  );
  if (dateUntil == null || !context.mounted) {
    return null;
  }

  final reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final colors = sheetContext.autonannyColors;
      final reasons = <MapEntry<String, String>>[
        const MapEntry(
          'illness',
          'Болезнь или временная нетрудоспособность',
        ),
        const MapEntry('vacation', 'Отпуск или командировка'),
        const MapEntry('family', 'Семейные обстоятельства'),
        const MapEntry('car_repair', 'Ремонт автомобиля'),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.xl,
            0,
            AutonannySpacing.xl,
            AutonannySpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Причина паузы',
                style: AutonannyTypography.h3(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                'Выберите причину, чтобы мы корректно показали состояние контракта водителю.',
                style: AutonannyTypography.bodyS(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              ...reasons.map(
                (reasonOption) => Padding(
                  padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
                  child: AutonannyButton(
                    label: reasonOption.value,
                    variant: AutonannyButtonVariant.secondary,
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(reasonOption.key),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (reason == null) {
    return null;
  }

  return _PauseContractRequest(
    dateFrom: _formatPauseRequestDate(dateFrom),
    dateUntil: _formatPauseRequestDate(dateUntil),
    reason: reason,
  );
}

String _formatPauseRequestDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

class _PausedContractBanner extends StatelessWidget {
  const _PausedContractBanner({
    required this.schedule,
    this.onResumeContract,
  });

  final Schedule schedule;
  final Future<bool> Function()? onResumeContract;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final pauseFrom = _formatPauseDate(schedule.pauseFrom);
    final pauseUntil = _formatPauseDate(schedule.pauseUntil);
    final pauseReason = _formatPauseReason(schedule.pauseReason);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutonannySectionContainer(
          title: _pauseTitle(schedule),
          subtitle: _pauseSubtitle(schedule),
          trailing: const AutonannyBadge(label: 'На паузе'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutonannyInlineBanner(
                title: 'Причина паузы',
                message: pauseReason,
                tone: AutonannyBannerTone.warning,
                leading: const AutonannyIcon(AutonannyIcons.warning),
              ),
              const SizedBox(height: AutonannySpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PauseMetricCard(
                      label: 'Пауза с',
                      value: pauseFrom,
                    ),
                  ),
                  const SizedBox(width: AutonannySpacing.md),
                  Expanded(
                    child: _PauseMetricCard(
                      label: 'Пауза до',
                      value: pauseUntil,
                    ),
                  ),
                ],
              ),
              if (_isBalancePause(schedule.pauseReason)) ...[
                const SizedBox(height: AutonannySpacing.md),
                AutonannyInlineBanner(
                  title: 'Баланс нужно пополнить',
                  message:
                      'Контракт поставлен на паузу из-за нехватки средств. Откройте кошелёк и внесите деньги, чтобы вернуться к поездкам.',
                  tone: AutonannyBannerTone.warning,
                  leading: const AutonannyIcon(AutonannyIcons.wallet),
                  trailing: AutonannyButton(
                    label: 'Пополнить',
                    size: AutonannyButtonSize.medium,
                    variant: AutonannyButtonVariant.secondary,
                    expand: false,
                    onPressed: () => _openWalletTopUp(context),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyButton(
                  label: 'Настроить автоплатеж',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: () => _openAutopaySettings(context),
                ),
              ] else if (onResumeContract != null) ...[
                const SizedBox(height: AutonannySpacing.md),
                AutonannyButton(
                  label: 'Возобновить досрочно',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: () async {
                    final resumed = await onResumeContract!.call();
                    if (resumed && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AutonannySpacing.md),
        AutonannyInlineBanner(
          title: schedule.pauseUntil != null
              ? 'Автовозобновление $pauseUntil'
              : 'Контракт ожидает ручного возобновления',
          message: schedule.pauseUntil != null
              ? 'Когда пауза закончится, контракт снова станет активным автоматически.'
              : 'Сейчас в расписании не будет новых поездок по этому контракту.',
          tone: AutonannyBannerTone.info,
          leading: const AutonannyIcon(AutonannyIcons.calendar),
        ),
        const SizedBox(height: AutonannySpacing.md),
        Container(
          padding: const EdgeInsets.all(AutonannySpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: AutonannyRadii.brLg,
          ),
          child: Text(
            'После снятия паузы вы снова увидите ближайшую поездку, назначенного водителя и подробную структуру контракта по дням.',
            style: AutonannyTypography.bodyS(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatPauseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  String _formatPauseReason(String? raw) {
    switch (raw) {
      case 'illness':
        return 'Болезнь или временная нетрудоспособность';
      case 'car_repair':
        return 'Ремонт автомобиля';
      case 'family':
        return 'Семейные обстоятельства';
      case 'vacation':
        return 'Отпуск или командировка';
      case 'insufficient_balance':
      case 'low_balance':
      case 'lack_of_funds':
        return 'Недостаточно средств для продолжения контракта';
      default:
        return (raw == null || raw.isEmpty) ? 'Причина не указана' : raw;
    }
  }

  bool _isBalancePause(String? raw) {
    return raw == 'insufficient_balance' ||
        raw == 'low_balance' ||
        raw == 'lack_of_funds';
  }

  String _pauseTitle(Schedule schedule) {
    switch (schedule.pauseInitiatedBy) {
      case 1:
        return 'Контракт приостановлен водителем';
      case 2:
        return 'Контракт поставлен на паузу';
      case 3:
        return 'Контракт приостановлен';
      default:
        return 'Контракт на паузе';
    }
  }

  String _pauseSubtitle(Schedule schedule) {
    switch (schedule.pauseInitiatedBy) {
      case 1:
        return 'Поездки временно остановлены по решению водителя.';
      case 2:
        return 'Вы временно остановили поездки по этому контракту.';
      case 3:
        return 'Поездки временно остановлены до восстановления оплаты.';
      default:
        return 'Поездки временно остановлены, пока пауза не закончится.';
    }
  }

  Future<void> _openWalletTopUp(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WalletView(
          title: 'Пополнение баланса',
          subtitle: 'Выберите способ пополнения',
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    final shouldResume = await NannyDialogs.confirmAction(
      context,
      'Если пополнение прошло успешно, можно сразу попытаться возобновить контракт.',
      title: 'Баланс пополнен?',
      confirmText: 'Да, проверить',
      cancelText: 'Пока нет',
    );
    if (!shouldResume || !context.mounted) {
      return;
    }

    await _attemptResumePaymentSchedule(context);
  }

  Future<void> _openAutopaySettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AutopaySettingsView(
          scheduleId: schedule.id,
          contractTitle:
              schedule.title.trim().isEmpty ? 'Контракт' : schedule.title,
          weeklyAmount: schedule.amountWeek,
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    final shouldResume = await NannyDialogs.confirmAction(
      context,
      'Если карта для автосписания уже настроена и оплата прошла, можно сразу проверить возобновление контракта.',
      title: 'Проверить контракт сейчас?',
      confirmText: 'Да, проверить',
      cancelText: 'Позже',
    );
    if (!shouldResume || !context.mounted) {
      return;
    }

    await _attemptResumePaymentSchedule(context);
  }

  Future<void> _attemptResumePaymentSchedule(BuildContext context) async {
    final scheduleId = schedule.id;
    if (scheduleId == null) {
      await NannyDialogs.showMessageBox(
        context,
        'Ошибка',
        'Не удалось определить контракт для возобновления.',
      );
      return;
    }

    final resumeResult = await NannyUsersApi.resumePaymentSchedule(scheduleId);
    if (!context.mounted) {
      return;
    }

    if (!resumeResult.success) {
      await NannyDialogs.showMessageBox(
        context,
        'Не удалось возобновить контракт',
        resumeResult.errorMessage.isNotEmpty
            ? resumeResult.errorMessage
            : 'Не удалось возобновить контракт после пополнения.',
      );
      return;
    }

    await NannyDialogs.showMessageBox(
      context,
      'Контракт возобновлён',
      resumeResult.response?.isNotEmpty == true
          ? 'Следующее списание: ${resumeResult.response}.'
          : 'Контракт успешно возобновлён.',
    );
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }
}

class _PauseMetricCard extends StatelessWidget {
  const _PauseMetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.lg),
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
