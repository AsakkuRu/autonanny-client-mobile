import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/graph_vm.dart';
import 'package:nanny_client/views/pages/contract_details_view.dart';
import 'package:nanny_components/base_views/views/pages/wallet.dart';
import 'package:nanny_components/dialogs/nanny_dialogs.dart';
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
    this.initialScheduleId,
    this.openInitialScheduleDetails = false,
  });

  final bool persistState;
  final int? initialScheduleId;
  final bool openInitialScheduleDetails;

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView>
    with AutomaticKeepAliveClientMixin {
  late final GraphVM vm;
  Timer? _fallbackRefreshTimer;
  StreamSubscription<void>? _tabSelectedSub;
  int _selectedTabIndex = 0;
  int? _selectedContractPreviewId;
  bool _initialDeepLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _selectedContractPreviewId = widget.initialScheduleId;
    vm = GraphVM(
      context: context,
      update: setState,
      initialScheduleId: widget.initialScheduleId,
    );
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
        title: 'Контракты',
        leading: SizedBox(width: 24),
      ),
      body: FutureBuilder<bool>(
        future: vm.loadRequest,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(
              label: 'Загружаем контракты и расписание.',
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return AutonannyErrorState(
              title: 'Не удалось загрузить данные',
              description: snapshot.error?.toString() ??
                  'Попробуйте открыть контракты ещё раз.',
              actionLabel: 'Повторить',
              onAction: vm.reloadPage,
            );
          }

          _maybeHandleInitialDeepLink();
          _maybeHandlePendingDetailsOpen();

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
                      message: 'Показываем кэшированные данные контрактов.',
                      tone: AutonannyBannerTone.warning,
                      leading: AutonannyIcon(AutonannyIcons.warning),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AutonannySpacing.xl,
                          AutonannySpacing.md,
                          AutonannySpacing.xl,
                          0,
                        ),
                        child: AutonannyTopTabs(
                          items: [
                            const AutonannyTopTabItem(label: 'Расписание'),
                            AutonannyTopTabItem(
                              label: 'Контракты',
                              badgeCount: vm.schedules.isEmpty
                                  ? null
                                  : vm.schedules.length,
                            ),
                          ],
                          currentIndex: _selectedTabIndex,
                          onTap: (index) {
                            setState(() {
                              _selectedTabIndex = index;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AutonannySpacing.md),
                      Expanded(
                        child: _selectedTabIndex == 0
                            ? (vm.schedules.isEmpty
                                ? _EmptyGraphState(
                                    onCreateTap: vm.toGraphCreate)
                                : _buildScheduleTab())
                            : (vm.schedules.isEmpty
                                ? _EmptyContractsState(
                                    onCreateTap: vm.toGraphCreate,
                                  )
                                : _buildContractsTab()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.xl,
            0,
            AutonannySpacing.xl,
            0,
          ),
          child: _GraphHeader(
            vm: vm,
            onPickSchedule: _openSchedulePicker,
            onOpenDetails: vm.selectedSchedule == null
                ? null
                : () => _openContractDetails(vm.selectedSchedule!),
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
                  _PausedContractBanner(
                    schedule: vm.selectedSchedule!,
                    onResumed: vm.reloadPage,
                    onManualResume:
                        vm.selectedSchedule?.pauseInitiatedBy == 2 &&
                                !_PausedContractBanner.isBalancePause(
                                  vm.selectedSchedule?.pauseReason,
                                )
                            ? () => vm.resumeSchedulePause(vm.selectedSchedule!)
                            : null,
                  ),
                ],
                if (vm.responses
                    .where((r) => r.idSchedule == vm.selectedSchedule?.id)
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
                  title: 'Маршруты контракта',
                  subtitle: 'Маршруты отображаются для выбранного дня недели.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!vm.hasRoutesForSelectedDay) ...[
                        AutonannyInlineBanner(
                          title: 'На выбранный день маршрутов нет',
                          message: vm.selectedDayEmptyMessage,
                          tone: AutonannyBannerTone.info,
                          leading: const AutonannyIcon(
                            AutonannyIcons.calendar,
                          ),
                        ),
                        const SizedBox(height: AutonannySpacing.md),
                      ],
                      ScheduleViewer(
                        schedule: vm.selectedSchedule,
                        selectedWeedkays: vm.selectedWeekday,
                      ),
                    ],
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
    );
  }

  Widget _buildContractsTab() {
    final previewSchedule = _previewSchedule;
    final previewPanels = previewSchedule?.contractDayPanelsData(
          childNamesById: vm.contractChildNamesById,
        ) ??
        const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.xl,
        0,
        AutonannySpacing.xl,
        AutonannySpacing.xl,
      ),
      children: [
        const AutonannyInlineBanner(
          title: 'Все ваши контракты в одном месте',
          message:
              'Открывайте нужный контракт и быстро переключайтесь в его расписание без входа в create/edit flow.',
          tone: AutonannyBannerTone.info,
          leading: AutonannyIcon(AutonannyIcons.list),
        ),
        const SizedBox(height: AutonannySpacing.lg),
        ...vm.schedules.map(
          (schedule) => Padding(
            padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
            child: ContractSummaryCard(
              data: schedule.contractSummaryCardData(
                isHighlighted: previewSchedule?.id == schedule.id,
                nextTripLabel: _nextTripLabelFor(schedule),
                statusLabelOverride: _contractStatusLabelFor(schedule),
                statusVariantOverride: _contractStatusVariantFor(schedule),
              ),
              onTap: () => _openContractDetails(schedule),
              onAction: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
                vm.scheduleSelected(schedule);
              },
            ),
          ),
        ),
        if (previewSchedule != null) ...[
          const SizedBox(height: AutonannySpacing.sm),
          AutonannyInlineBanner(
            title: 'Маршруты по контракту «${previewSchedule.title}»',
            message:
                'Здесь показана сводка по дням, маршрутам и детям, привязанным к каждой поездке.',
            tone: AutonannyBannerTone.info,
            leading: const AutonannyIcon(AutonannyIcons.calendar),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          if (previewPanels.isEmpty)
            const AutonannyInlineBanner(
              title: 'Маршруты пока не добавлены',
              message:
                  'У этого контракта пока нет маршрутов для предварительного просмотра.',
              tone: AutonannyBannerTone.warning,
              leading: AutonannyIcon(AutonannyIcons.warning),
            )
          else
            ...previewPanels.map(
              (panel) => Padding(
                padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
                child: ContractDayPanel(data: panel),
              ),
            ),
        ],
        const SizedBox(height: AutonannySpacing.sm),
        AutonannyButton(
          label: 'Создать контракт',
          leading: const AutonannyIcon(
            AutonannyIcons.add,
            color: Colors.white,
          ),
          onPressed: vm.toGraphCreate,
        ),
      ],
    );
  }

  Schedule? get _previewSchedule {
    if (vm.schedules.isEmpty) {
      return null;
    }

    final preferredId = _selectedContractPreviewId ??
        vm.selectedSchedule?.id ??
        vm.schedules.first.id;

    for (final schedule in vm.schedules) {
      if (schedule.id == preferredId) {
        return schedule;
      }
    }

    return vm.schedules.first;
  }

  Future<void> _openContractDetails(Schedule schedule) async {
    setState(() {
      _selectedContractPreviewId = schedule.id;
    });

    await vm.scheduleSelected(schedule);
    if (!mounted) {
      return;
    }

    final responsesCount = vm.responses
        .where((response) => response.idSchedule == schedule.id)
        .length;

    final resumed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ContractDetailsView(
          schedule: schedule,
          summaryData: schedule.contractSummaryCardData(
            nextTripLabel: _nextTripLabelFor(schedule),
            statusLabelOverride: _contractStatusLabelFor(schedule),
            statusVariantOverride: _contractStatusVariantFor(schedule),
          ),
          dayPanels: schedule.contractDayPanelsData(
            childNamesById: vm.contractChildNamesById,
          ),
          contractChildren: vm.contractChildrenFor(schedule),
          driverContact:
              vm.selectedSchedule?.id == schedule.id ? vm.driverContact : null,
          responsesCount: responsesCount,
          onOpenSchedule: () {
            Navigator.of(context).maybePop();
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedTabIndex = 0;
            });
          },
          onEditContract: () {
            Navigator.of(context).maybePop();
            if (!mounted) {
              return;
            }
            vm.toGraphEdit(schedule: schedule);
          },
          onPauseContract: (dateFrom, dateUntil, reason) => vm.pauseSchedule(
            schedule: schedule,
            dateFrom: dateFrom,
            dateUntil: dateUntil,
            reason: reason,
          ),
          onCancelContract: () => vm.deleteSchedule(schedule),
          onResumeContract: schedule.pauseInitiatedBy == 2 &&
                  !_PausedContractBanner.isBalancePause(schedule.pauseReason)
              ? () => vm.resumeSchedulePause(schedule)
              : null,
          onCallDriver: vm.driverContact?.phone.trim().isNotEmpty == true
              ? vm.callAssignedDriver
              : null,
          onOpenDriverProfile:
              vm.driverContact != null ? vm.openAssignedDriverProfile : null,
          onOpenChat: vm.driverContact != null ? vm.openDriverChat : null,
          onShowQr: vm.driverContact != null ? vm.showDriverQR : null,
        ),
      ),
    );
    if (resumed == true && mounted) {
      final scheduleId = schedule.id;
      await vm.reloadPage();
      if (!mounted || scheduleId == null) {
        return;
      }
      for (final refreshedSchedule in vm.schedules) {
        if (refreshedSchedule.id == scheduleId) {
          unawaited(_openContractDetails(refreshedSchedule));
          break;
        }
      }
    }
  }

  void _maybeHandleInitialDeepLink() {
    if (_initialDeepLinkHandled) {
      return;
    }

    final targetScheduleId = widget.initialScheduleId;
    if (targetScheduleId == null) {
      _initialDeepLinkHandled = true;
      return;
    }

    Schedule? targetSchedule;
    for (final schedule in vm.schedules) {
      if (schedule.id == targetScheduleId) {
        targetSchedule = schedule;
        break;
      }
    }

    if (targetSchedule == null) {
      _initialDeepLinkHandled = true;
      return;
    }

    if (!widget.openInitialScheduleDetails) {
      _initialDeepLinkHandled = true;
      return;
    }

    _initialDeepLinkHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_openContractDetails(targetSchedule!));
    });
  }

  void _maybeHandlePendingDetailsOpen() {
    if (!vm.consumePendingDetailsOpen()) {
      return;
    }

    final targetSchedule = vm.selectedSchedule;
    if (targetSchedule == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_openContractDetails(targetSchedule));
    });
  }

  String? _nextTripLabelFor(Schedule schedule) {
    if (schedule.roads.isEmpty) {
      return null;
    }

    final roads = schedule.roads.toList(growable: false)
      ..sort((left, right) {
        final byDay = left.weekDay.index.compareTo(right.weekDay.index);
        if (byDay != 0) {
          return byDay;
        }
        final byHour = left.startTime.hour.compareTo(right.startTime.hour);
        if (byHour != 0) {
          return byHour;
        }
        return left.startTime.minute.compareTo(right.startTime.minute);
      });

    final road = roads.first;
    return '${road.weekDay.shortName} · '
        '${road.startTime.formatTime()} – ${road.endTime.formatTime()}';
  }

  String _contractStatusLabelFor(Schedule schedule) {
    if (schedule.isPaused == true) {
      return 'Приостановлен';
    }
    if (vm.selectedSchedule?.id == schedule.id && vm.driverContact != null) {
      return 'Контракт подтверждён';
    }
    if (vm.responses.any((response) => response.idSchedule == schedule.id)) {
      return 'Ожидает выбора водителя';
    }
    if (schedule.isActive == true) {
      return 'Активен';
    }
    return 'Ожидает откликов';
  }

  AutonannyStatusVariant _contractStatusVariantFor(Schedule schedule) {
    if (schedule.isPaused == true) {
      return AutonannyStatusVariant.warning;
    }
    if (vm.selectedSchedule?.id == schedule.id && vm.driverContact != null) {
      return AutonannyStatusVariant.success;
    }
    if (vm.responses.any((response) => response.idSchedule == schedule.id)) {
      return AutonannyStatusVariant.warning;
    }
    if (schedule.isActive == true) {
      return AutonannyStatusVariant.success;
    }
    return AutonannyStatusVariant.neutral;
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
                'Мои контракты',
                style: AutonannyTypography.h3(
                  color: context.autonannyColors.textPrimary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                'Выберите действующий контракт или создайте новый.',
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
                              onPressed: () async {
                                Navigator.of(sheetContext).pop();
                                await vm.deleteSchedule(schedule);
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
                      label: 'Новый контракт',
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
              title: 'У вас пока нет контрактов',
              description:
                  'Создайте первый контракт с регулярными поездками, чтобы получить отклики водителей.',
              icon: AutonannyIcon(AutonannyIcons.calendar, size: 36),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannyButton(
              label: 'Создать контракт',
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

class _EmptyContractsState extends StatelessWidget {
  const _EmptyContractsState({required this.onCreateTap});

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
              title: 'Контракты пока не созданы',
              description:
                  'Создайте первый контракт, чтобы увидеть здесь сводку по детям, маршрутам и стоимости.',
              icon: AutonannyIcon(AutonannyIcons.list, size: 36),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannyButton(
              label: 'Создать контракт',
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
    this.onOpenDetails,
  });

  final GraphVM vm;
  final Future<void> Function() onPickSchedule;
  final VoidCallback? onOpenDetails;

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
                      schedule?.title ?? 'Контракт не выбран',
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
                    tooltip: 'Сменить контракт',
                  ),
                  const SizedBox(height: AutonannySpacing.sm),
                  AutonannyIconButton(
                    icon: const AutonannyIcon(
                      AutonannyIcons.add,
                      color: Colors.white,
                    ),
                    onPressed: vm.toGraphCreate,
                    variant: AutonannyIconButtonVariant.primary,
                    tooltip: 'Новый контракт',
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
                label: _contractsCountLabel(vm.schedules.length),
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
                if (onOpenDetails != null)
                  Expanded(
                    child: AutonannyButton(
                      label: 'Детали контракта',
                      variant: AutonannyButtonVariant.primary,
                      expand: false,
                      leading: const AutonannyIcon(
                        AutonannyIcons.list,
                        color: Colors.white,
                      ),
                      onPressed: onOpenDetails,
                    ),
                  ),
                if (onOpenDetails != null)
                  const SizedBox(width: AutonannySpacing.md),
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
              vm.selectedSchedule == null
                  ? 'Выберите контракт и дождитесь откликов, чтобы продолжить.'
                  : vm.selectedDayEmptyMessage,
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

String _contractsCountLabel(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;

  if (mod10 == 1 && mod100 != 11) {
    return '$count контракт';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return '$count контракта';
  }
  return '$count контрактов';
}

class _PausedContractBanner extends StatelessWidget {
  const _PausedContractBanner({
    required this.schedule,
    this.onResumed,
    this.onManualResume,
  });

  final Schedule schedule;
  final Future<void> Function()? onResumed;
  final Future<bool> Function()? onManualResume;

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
                  title: 'Нужно пополнить баланс',
                  message:
                      'Контракт поставлен на паузу из-за нехватки средств. После пополнения вы сможете вернуться к поездкам.',
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
              ] else if (onManualResume != null) ...[
                const SizedBox(height: AutonannySpacing.md),
                AutonannyButton(
                  label: 'Возобновить досрочно',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: () async {
                    final resumed = await onManualResume!.call();
                    if (!context.mounted || !resumed) {
                      return;
                    }
                    await NannyDialogs.showMessageBox(
                      context,
                      'Контракт возобновлён',
                      'Поездки по контракту снова активны.',
                    );
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
              : 'Ожидаем ручного возобновления',
          message: schedule.pauseUntil != null
              ? 'Когда срок паузы закончится, контракт снова станет активным автоматически.'
              : 'Новые поездки по этому контракту появятся после ручного возобновления.',
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
            'Отклики и детализация маршрутов сохраняются, но ближайшие поездки не будут запланированы, пока пауза активна.',
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

  static bool isBalancePause(String? raw) {
    return raw == 'insufficient_balance' ||
        raw == 'low_balance' ||
        raw == 'lack_of_funds';
  }

  bool _isBalancePause(String? raw) => isBalancePause(raw);

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
        return 'Поездки по этому контракту временно не выполняются по решению водителя.';
      case 2:
        return 'Вы временно остановили поездки по этому контракту.';
      case 3:
        return 'Поездки временно остановлены, пока не будет решён вопрос с оплатой.';
      default:
        return 'Поездки по этому контракту временно не выполняются.';
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

    await onResumed?.call();
    if (!context.mounted) {
      return;
    }

    await NannyDialogs.showMessageBox(
      context,
      'Контракт возобновлён',
      resumeResult.response?.isNotEmpty == true
          ? 'Следующее списание: ${resumeResult.response}.'
          : 'Контракт успешно возобновлён.',
    );
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
