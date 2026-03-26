import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/graph_vm.dart';
import 'package:nanny_components/widgets/date_selector.dart';
import 'package:nanny_components/widgets/driver_contact_card.dart';
import 'package:nanny_components/widgets/schedule_viewer.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/nanny_core.dart';

class GraphView extends StatefulWidget {
  const GraphView({
    super.key,
    this.persistState = false,
  });

  final bool persistState;

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView>
    with AutomaticKeepAliveClientMixin {
  late final GraphVM vm;
  Timer? _fallbackRefreshTimer;
  StreamSubscription<void>? _tabSelectedSub;

  @override
  void initState() {
    super.initState();
    vm = GraphVM(context: context, update: setState);
    vm.startScheduleUpdatesListener();
    _fallbackRefreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) {
        return;
      }
      vm.loadResponsesOnly();
    });
    _tabSelectedSub =
        NannyGlobals.scheduleTabSelectedController.stream.listen((_) {
      if (mounted) {
        vm.reloadPage();
      }
    });
  }

  @override
  void dispose() {
    _tabSelectedSub?.cancel();
    _fallbackRefreshTimer?.cancel();
    vm.stopScheduleUpdatesListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) {
      super.build(context);
    }

    return AutonannyAppScaffold(
      appBar: const AutonannyAppBar(
        title: 'График поездок',
        leading: SizedBox(width: 24),
      ),
      body: FutureBuilder<bool>(
        future: vm.loadRequest,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(
              label: 'Загружаем графики поездок.',
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return AutonannyErrorState(
              title: 'Не удалось загрузить данные',
              description: snapshot.error?.toString() ??
                  'Попробуйте открыть график поездок ещё раз.',
              actionLabel: 'Повторить',
              onAction: vm.reloadPage,
            );
          }

          if (vm.schedules.isEmpty) {
            return _EmptyGraphState(onCreateTap: vm.toGraphCreate);
          }

          return SafeArea(
            child: Column(
              children: [
                if (vm.isOffline)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AutonannySpacing.xl,
                      AutonannySpacing.md,
                      AutonannySpacing.xl,
                      0,
                    ),
                    child: AutonannyInlineBanner(
                      title: 'Оффлайн-режим',
                      message: 'Показываем кэшированные данные графиков.',
                      tone: AutonannyBannerTone.warning,
                      leading: AutonannyIcon(AutonannyIcons.warning),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AutonannySpacing.xl,
                    AutonannySpacing.md,
                    AutonannySpacing.xl,
                    0,
                  ),
                  child: _GraphHeader(
                    vm: vm,
                    onPickSchedule: _openSchedulePicker,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AutonannySpacing.xl,
                    AutonannySpacing.lg,
                    AutonannySpacing.xl,
                    AutonannySpacing.md,
                  ),
                  child: AutonannySectionContainer(
                    title: 'Выбранный день',
                    subtitle:
                        'Переключайте дни недели, чтобы посмотреть расписание маршрутов.',
                    child: DateSelector(onDateSelected: vm.weekdaySelected),
                  ),
                ),
                Expanded(
                  child: AutonannyBottomSheetShell(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _ContractStatusSection(vm: vm),
                        if (vm.selectedSchedule?.isPaused == true) ...[
                          const SizedBox(height: AutonannySpacing.lg),
                          _PausedContractBanner(schedule: vm.selectedSchedule!),
                        ],
                        if (vm.responses
                            .where(
                                (r) => r.idSchedule == vm.selectedSchedule?.id)
                            .isNotEmpty) ...[
                          const SizedBox(height: AutonannySpacing.lg),
                          _ResponsesSection(vm: vm),
                        ],
                        if (vm.driverContact != null) ...[
                          const SizedBox(height: AutonannySpacing.lg),
                          DriverContactCard(
                            driver: vm.driverContact!,
                            onChatPressed: vm.openDriverChat,
                            onShowQR: vm.showDriverQR,
                          ),
                        ],
                        const SizedBox(height: AutonannySpacing.lg),
                        AutonannySectionContainer(
                          title: 'Маршруты графика',
                          subtitle:
                              'Маршруты отображаются для выбранного дня недели.',
                          child: ScheduleViewer(
                            schedule: vm.selectedSchedule,
                            selectedWeedkays: vm.selectedWeekday,
                          ),
                        ),
                        const SizedBox(height: AutonannySpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _BudgetCard(
                                title: 'Расходы в неделю',
                                amount: vm.spentsInWeek,
                                tone: _BudgetCardTone.primary,
                              ),
                            ),
                            const SizedBox(width: AutonannySpacing.md),
                            Expanded(
                              child: _BudgetCard(
                                title: 'Расходы в месяц',
                                amount: vm.spentsInMonth,
                                tone: _BudgetCardTone.neutral,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSchedulePicker() async {
    final pickedId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => AutonannyBottomSheetShell(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Мои графики',
                style: AutonannyTypography.h3(
                  color: context.autonannyColors.textPrimary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                'Выберите действующий график или создайте новый.',
                style: AutonannyTypography.bodyS(
                  color: context.autonannyColors.textSecondary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: vm.schedules.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AutonannySpacing.xs),
                  itemBuilder: (_, index) {
                    final schedule = vm.schedules[index];
                    return AutonannyCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AutonannySpacing.md,
                        vertical: AutonannySpacing.sm,
                      ),
                      child: AutonannyListRow(
                        title: schedule.title,
                        subtitle: _scheduleSubtitle(schedule),
                        leading: const AutonannyIcon(AutonannyIcons.calendar),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (vm.selectedSchedule?.id == schedule.id)
                              const Padding(
                                padding: EdgeInsets.only(
                                  right: AutonannySpacing.sm,
                                ),
                                child: AutonannyIcon(
                                  AutonannyIcons.checkCircle,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            AutonannyIconButton(
                              icon: const AutonannyIcon(AutonannyIcons.close),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                vm.deleteSchedule(schedule);
                              },
                              variant: AutonannyIconButtonVariant.ghost,
                              size: 36,
                            ),
                          ],
                        ),
                        onTap: () =>
                            Navigator.of(sheetContext).pop(schedule.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AutonannyButton(
                      label: 'Новый график',
                      leading: const AutonannyIcon(
                        AutonannyIcons.add,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(sheetContext).pop(-1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || pickedId == null) {
      return;
    }

    if (pickedId == -1) {
      vm.toGraphCreate();
      return;
    }

    final schedule =
        vm.schedules.where((item) => item.id == pickedId).firstOrNull;
    if (schedule != null) {
      vm.scheduleSelected(schedule);
    }
  }

  String _scheduleSubtitle(Schedule schedule) {
    final days = schedule.weekdays.map((day) => day.shortName).join(', ');
    return days.isEmpty ? 'Без указанных дней' : days;
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}

class _EmptyGraphState extends StatelessWidget {
  const _EmptyGraphState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AutonannySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AutonannyEmptyState(
              title: 'У вас пока нет графиков',
              description:
                  'Создайте первый график регулярных поездок, чтобы получить отклики водителей.',
              icon: AutonannyIcon(AutonannyIcons.calendar, size: 36),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannyButton(
              label: 'Создать график',
              leading: const AutonannyIcon(
                AutonannyIcons.add,
                color: Colors.white,
              ),
              onPressed: onCreateTap,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphHeader extends StatelessWidget {
  const _GraphHeader({
    required this.vm,
    required this.onPickSchedule,
  });

  final GraphVM vm;
  final Future<void> Function() onPickSchedule;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final schedule = vm.selectedSchedule;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule?.title ?? 'График не выбран',
                      style: AutonannyTypography.h2(
                        color: colors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      vm.contractStatusDescription,
                      style: AutonannyTypography.bodyS(
                        color: colors.textInverse.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Column(
                children: [
                  AutonannyIconButton(
                    icon: const AutonannyIcon(
                      AutonannyIcons.list,
                      color: Colors.white,
                    ),
                    onPressed: onPickSchedule,
                    variant: AutonannyIconButtonVariant.primary,
                    tooltip: 'Сменить график',
                  ),
                  const SizedBox(height: AutonannySpacing.sm),
                  AutonannyIconButton(
                    icon: const AutonannyIcon(
                      AutonannyIcons.add,
                      color: Colors.white,
                    ),
                    onPressed: vm.toGraphCreate,
                    variant: AutonannyIconButtonVariant.primary,
                    tooltip: 'Новый график',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Wrap(
            spacing: AutonannySpacing.sm,
            runSpacing: AutonannySpacing.sm,
            children: [
              _InvertedChip(
                icon: AutonannyIcons.calendar,
                label: '${vm.schedules.length} графиков',
              ),
              _InvertedChip(
                icon: AutonannyIcons.group,
                label: vm.contractStatusLabel,
              ),
              if (vm.nextTripLabel != null)
                _InvertedChip(
                  icon: AutonannyIcons.clock,
                  label: 'Ближайшая: ${vm.nextTripLabel}',
                ),
            ],
          ),
          if (schedule != null) ...[
            const SizedBox(height: AutonannySpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AutonannyButton(
                    label: 'Редактировать',
                    variant: AutonannyButtonVariant.secondary,
                    expand: false,
                    leading: AutonannyIcon(
                      AutonannyIcons.edit,
                      color: colors.actionPrimary,
                    ),
                    onPressed: () => vm.toGraphEdit(schedule: schedule),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InvertedChip extends StatelessWidget {
  const _InvertedChip({
    required this.icon,
    required this.label,
  });

  final AutonannyIconAsset icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutonannySpacing.md,
        vertical: AutonannySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.textInverse.withValues(alpha: 0.14),
        borderRadius: AutonannyRadii.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutonannyIcon(icon, color: colors.textInverse, size: 14),
          const SizedBox(width: AutonannySpacing.xs),
          Text(
            label,
            style: AutonannyTypography.labelM(color: colors.textInverse),
          ),
        ],
      ),
    );
  }
}

class _ContractStatusSection extends StatelessWidget {
  const _ContractStatusSection({required this.vm});

  final GraphVM vm;

  @override
  Widget build(BuildContext context) {
    final variant = vm.driverContact != null
        ? AutonannyStatusVariant.success
        : vm.responses
                .where((r) => r.idSchedule == vm.selectedSchedule?.id)
                .isNotEmpty
            ? AutonannyStatusVariant.warning
            : AutonannyStatusVariant.neutral;

    return AutonannySectionContainer(
      title: 'Статус контракта',
      subtitle: vm.contractStatusDescription,
      trailing: AutonannyStatusChip(
        label: vm.contractStatusLabel,
        variant: variant,
      ),
      child: vm.nextTripLabel == null
          ? Text(
              'Выберите график и дождитесь откликов, чтобы продолжить.',
              style: AutonannyTypography.bodyS(
                color: context.autonannyColors.textSecondary,
              ),
            )
          : Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.autonannyColors.surfaceSecondary,
                    borderRadius: AutonannyRadii.brMd,
                  ),
                  alignment: Alignment.center,
                  child: AutonannyIcon(
                    AutonannyIcons.clock,
                    color: context.autonannyColors.actionPrimary,
                  ),
                ),
                const SizedBox(width: AutonannySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ближайшая поездка',
                        style: AutonannyTypography.labelL(
                          color: context.autonannyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AutonannySpacing.xs),
                      Text(
                        vm.nextTripLabel!,
                        style: AutonannyTypography.bodyS(
                          color: context.autonannyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PausedContractBanner extends StatelessWidget {
  const _PausedContractBanner({required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final pieces = <String>[
      if (schedule.pauseFrom != null)
        'с ${schedule.pauseFrom!.substring(0, 10)}',
      if (schedule.pauseUntil != null)
        'по ${schedule.pauseUntil!.substring(0, 10)}',
    ];

    return AutonannyInlineBanner(
      title: 'Контракт приостановлен водителем',
      message: [
        if (pieces.isNotEmpty) pieces.join(' '),
        if ((schedule.pauseReason ?? '').isNotEmpty)
          'Причина: ${schedule.pauseReason}',
      ].join('\n'),
      tone: AutonannyBannerTone.warning,
      leading: const AutonannyIcon(AutonannyIcons.warning),
    );
  }
}

class _ResponsesSection extends StatelessWidget {
  const _ResponsesSection({required this.vm});

  final GraphVM vm;

  @override
  Widget build(BuildContext context) {
    final responses = vm.responses
        .where((r) => r.idSchedule == vm.selectedSchedule?.id)
        .toList(growable: false);

    return AutonannySectionContainer(
      title: 'Отклики водителей',
      subtitle: 'Выберите подходящего водителя, чтобы подтвердить контракт.',
      child: Column(
        children: responses
            .map(
              (response) => Padding(
                padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
                child: _ResponseCard(
                  response: response,
                  onOpen: () => vm.openDriverFromResponse(response),
                  onAccept: () => vm.answerResponse(response, true),
                  onReject: () => vm.answerResponse(response, false),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.response,
    required this.onOpen,
    required this.onAccept,
    required this.onReject,
  });

  final ScheduleResponsesData response;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = response.photoPath.trim().isNotEmpty;

    return AutonannyCard(
      child: AutonannyListRow(
        title: response.name,
        subtitle: '${response.data.length} маршрутов',
        leading: AutonannyAvatar(
          image: hasPhoto ? NetworkImage(response.photoPath) : null,
          initials: _initials(response.name),
          size: 48,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AutonannyIconButton(
              icon: const AutonannyIcon(
                AutonannyIcons.checkCircle,
                color: Color(0xFF16A34A),
              ),
              onPressed: onAccept,
              variant: AutonannyIconButtonVariant.ghost,
              size: 36,
            ),
            const SizedBox(width: AutonannySpacing.xs),
            AutonannyIconButton(
              icon: const AutonannyIcon(
                AutonannyIcons.close,
                color: Color(0xFFDC2626),
              ),
              onPressed: onReject,
              variant: AutonannyIconButtonVariant.ghost,
              size: 36,
            ),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((element) => element.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'A';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1);
    }
    return '${parts[0][0]}${parts[1][0]}';
  }
}

enum _BudgetCardTone { primary, neutral }

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.title,
    required this.amount,
    required this.tone,
  });

  final String title;
  final String amount;
  final _BudgetCardTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    final background = switch (tone) {
      _BudgetCardTone.primary => colors.statusInfoSurface,
      _BudgetCardTone.neutral => colors.surfaceSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AutonannyTypography.caption(color: colors.textSecondary),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Text(
            amount,
            style: AutonannyTypography.h3(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
