import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/graph_vm.dart';
import 'package:nanny_client/views/pages/contract_details_view.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
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
  late final ScrollController _scheduleScrollController;
  late final ScrollController _contractsScrollController;
  Timer? _fallbackRefreshTimer;
  StreamSubscription<void>? _tabSelectedSub;
  int _selectedTabIndex = 0;
  int? _selectedContractPreviewId;
  bool _initialDeepLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _selectedContractPreviewId = widget.initialScheduleId;
    _scheduleScrollController = ScrollController();
    _contractsScrollController = ScrollController();
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
    _scheduleScrollController.dispose();
    _contractsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) {
      super.build(context);
    }

    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'Контракты',
        leading: widget.persistState
            ? const SizedBox(width: 24)
            : IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: 'Назад',
              ),
        actions: const <Widget>[],
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
          _scheduleScrollOffsetNormalization();

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
                                    onCreateTap: _handleCreateContract)
                                : _buildScheduleTab())
                            : (vm.schedules.isEmpty
                                ? _EmptyContractsState(
                                    onCreateTap: _handleCreateContract,
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
    final dayTrips = _selectedDayTrips;
    final contractsCount = dayTrips
        .map((trip) => trip.schedule.id ?? trip.schedule.title.hashCode)
        .toSet()
        .length;

    return ListView(
      controller: _scheduleScrollController,
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.xl,
        0,
        AutonannySpacing.xl,
        AutonannySpacing.xl,
      ),
      children: [
        _GraphHeader(vm: vm),
        const SizedBox(height: AutonannySpacing.lg),
        AutonannySectionContainer(
          title: 'Календарь поездок',
          subtitle:
              'Переключайте дни недели, чтобы посмотреть все маршруты по вашим контрактам.',
          child: _ContractWeekPicker(
            selectedWeekday:
                vm.selectedWeekday.isEmpty ? null : vm.selectedWeekday.first,
            onDateSelected: vm.weekdaySelected,
          ),
        ),
        const SizedBox(height: AutonannySpacing.lg),
        _ContractStatusSection(
          selectedDay: vm.selectedDay,
          tripsCount: dayTrips.length,
          contractsCount: contractsCount,
        ),
        const SizedBox(height: AutonannySpacing.lg),
        AutonannySectionContainer(
          title: 'Маршруты дня',
          subtitle: dayTrips.isEmpty
              ? 'Когда на выбранный день появятся поездки, они будут показаны здесь.'
              : 'Каждая карточка ведёт в детали контракта, где можно управлять водителем и самим контрактом.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dayTrips.isEmpty)
                const AutonannyInlineBanner(
                  title: 'На выбранный день поездок нет',
                  message:
                      'Переключите день или откройте вкладку контрактов, чтобы посмотреть детали нужного договора.',
                  tone: AutonannyBannerTone.info,
                  leading: AutonannyIcon(AutonannyIcons.calendar),
                )
              else
                Column(
                  children: dayTrips
                      .map(
                        (trip) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AutonannySpacing.md,
                          ),
                          child: _SelectedDayTripCard(
                            schedule: trip.schedule,
                            road: trip.road,
                            childLabels: _childLabelsForTrip(trip),
                            statusLabel: _contractStatusLabelFor(trip.schedule),
                            statusVariant: _contractStatusVariantFor(
                              trip.schedule,
                            ),
                            onOpenContract: () =>
                                _openContractDetails(trip.schedule),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContractsTab() {
    final previewSchedule = _previewSchedule;

    return ListView(
      controller: _contractsScrollController,
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.xl,
        0,
        AutonannySpacing.xl,
        AutonannySpacing.xl,
      ),
      children: [
        ContractsOverviewCard(
          data: vm.contractsOverviewCardData,
          onAction: _handleCreateContract,
        ),
        const SizedBox(height: AutonannySpacing.lg),
        ...vm.schedules.map((schedule) {
          final responsesForSchedule = vm.responses
              .where((r) => r.idSchedule == schedule.id)
              .length;
          return Padding(
            padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
            child: ContractSummaryCard(
              data: schedule.contractSummaryCardData(
                isHighlighted: previewSchedule?.id == schedule.id,
                nextTripLabel: _nextTripLabelFor(schedule),
                statusLabelOverride: _contractStatusLabelFor(schedule),
                statusVariantOverride: _contractStatusVariantFor(schedule),
                pendingDriverResponsesCount: responsesForSchedule,
              ),
              onTap: () => _openContractDetails(schedule),
            ),
          );
        }),
      ],
    );
  }

  List<_ScheduledDayTrip> get _selectedDayTrips {
    final day = vm.selectedDay;
    if (day == null) {
      return const <_ScheduledDayTrip>[];
    }

    final trips = <_ScheduledDayTrip>[];
    for (final schedule in vm.schedules) {
      for (final road in schedule.roads) {
        if (road.weekDay != day) {
          continue;
        }
        trips.add(_ScheduledDayTrip(schedule: schedule, road: road));
      }
    }

    trips.sort((left, right) {
      final hourCompare =
          left.road.startTime.hour.compareTo(right.road.startTime.hour);
      if (hourCompare != 0) {
        return hourCompare;
      }

      final minuteCompare =
          left.road.startTime.minute.compareTo(right.road.startTime.minute);
      if (minuteCompare != 0) {
        return minuteCompare;
      }

      return left.schedule.title.compareTo(right.schedule.title);
    });

    return trips;
  }

  List<String> _childLabelsForTrip(_ScheduledDayTrip trip) {
    final childNamesById = vm.contractChildNamesById;
    final explicitRouteChildren = (trip.road.children ?? const <int>[])
        .map((childId) => childNamesById[childId]?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    if (explicitRouteChildren.isNotEmpty) {
      return explicitRouteChildren;
    }

    return vm
        .contractChildrenFor(trip.schedule)
        .map((child) => child.fullName.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
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
    final canEditContract = vm.canEditSchedule(
      schedule,
      responsesCount: responsesCount,
      hasAssignedDriver:
          vm.selectedSchedule?.id == schedule.id && vm.driverContact != null,
    );
    final editLockedMessage = canEditContract
        ? null
        : vm.scheduleEditLockedMessage(
            schedule,
            responsesCount: responsesCount,
            hasAssignedDriver: vm.selectedSchedule?.id == schedule.id &&
                vm.driverContact != null,
          );

    final resumed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ContractDetailsView(
          schedule: schedule,
          summaryData: schedule.contractSummaryCardData(
            nextTripLabel: _nextTripLabelFor(schedule),
            statusLabelOverride: _contractStatusLabelFor(schedule),
            statusVariantOverride: _contractStatusVariantFor(schedule),
            pendingDriverResponsesCount: responsesCount,
          ),
          dayPanels: schedule.contractDayPanelsData(
            childNamesById: vm.contractChildNamesById,
          ),
          contractChildren: vm.contractChildrenFor(schedule),
          driverContact:
              vm.selectedSchedule?.id == schedule.id ? vm.driverContact : null,
          responsesCount: responsesCount,
          responses: vm.responses
              .where((response) => response.idSchedule == schedule.id)
              .toList(growable: false),
          onOpenSchedule: () {
            Navigator.of(context).maybePop();
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedTabIndex = 0;
            });
          },
          onEditContract: canEditContract
              ? () {
                  Navigator.of(context).maybePop();
                  if (!mounted) {
                    return;
                  }
                  vm.toGraphEdit(schedule: schedule);
                }
              : null,
          editLockedMessage: editLockedMessage,
          onPauseContract: (dateFrom, dateUntil, reason) => vm.pauseSchedule(
            schedule: schedule,
            dateFrom: dateFrom,
            dateUntil: dateUntil,
            reason: reason,
          ),
          onRequestCancelContract: () => vm.requestDeleteSchedule(schedule),
          onConfirmCancelContractDebit: (debitAmount) =>
              vm.confirmDeleteScheduleWithDebit(
            schedule,
            debitAmount: debitAmount,
          ),
          onCancelContract: () => vm.deleteSchedule(schedule),
          onResumeContract: schedule.pauseInitiatedBy == 2 &&
                  !_isBalancePause(schedule.pauseReason)
              ? () => vm.resumeSchedulePause(
                    schedule,
                    requireConfirmation: false,
                    showErrorDialogs: false,
                  )
              : null,
          onCallDriver: vm.driverContact?.phone.trim().isNotEmpty == true
              ? vm.callAssignedDriver
              : null,
          onOpenDriverProfile:
              vm.driverContact != null ? vm.openAssignedDriverProfile : null,
          onOpenChat: vm.driverContact != null ? vm.openDriverChat : null,
          // PIN/QR только на экране старта поездки, не в карточке контракта (QA 03.04.26).
          onShowQr: null,
          onOpenResponseDriver: (response) async {
            final navigator = Navigator.of(context);
            final changed = await vm.openDriverFromResponse(response);
            if (!mounted || !changed) {
              return;
            }
            navigator.pop(true);
          },
          onAcceptResponse: (response) async {
            final navigator = Navigator.of(context);
            final handled = await vm.answerResponse(response, true);
            if (!mounted || !handled) {
              return;
            }
            navigator.pop(true);
          },
          onRejectResponse: (response) async {
            final navigator = Navigator.of(context);
            final handled = await vm.answerResponse(response, false);
            if (!mounted || !handled) {
              return;
            }
            navigator.pop(true);
          },
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

  void _handleCreateContract() async {
    final createdScheduleId = await vm.toGraphCreate();
    if (!mounted || createdScheduleId == null) {
      return;
    }

    setState(() {
      _selectedTabIndex = 1;
      _selectedContractPreviewId = createdScheduleId;
    });

    NannyGlobals.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Контракт сохранён'),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollContractsToTop();
    });
  }

  void _scrollContractsToTop() {
    if (!mounted || !_contractsScrollController.hasClients) {
      return;
    }

    final position = _contractsScrollController.position;
    if (position.pixels <= 0) {
      return;
    }

    _contractsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleScrollOffsetNormalization() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _clampControllerOffset(_scheduleScrollController);
      _clampControllerOffset(_contractsScrollController);
    });
  }

  void _clampControllerOffset(ScrollController controller) {
    if (!controller.hasClients) {
      return;
    }

    final position = controller.position;
    final clampedOffset = position.pixels.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((clampedOffset - position.pixels).abs() < 0.5) {
      return;
    }

    controller.jumpTo(clampedOffset.toDouble());
  }

  String? _nextTripLabelFor(Schedule schedule) {
    final road = _nearestUpcomingRoad(schedule);
    if (road == null) {
      return null;
    }

    return '${road.weekDay.shortName} · '
        '${road.startTime.formatTime()} – ${road.endTime.formatTime()}';
  }

  Road? _nearestUpcomingRoad(Schedule schedule) {
    Road? nearestRoad;
    DateTime? nearestDateTime;

    for (final road in schedule.roads) {
      final occurrence = _nextOccurrenceFor(road.weekDay, road.startTime);
      if (nearestDateTime == null || occurrence.isBefore(nearestDateTime)) {
        nearestDateTime = occurrence;
        nearestRoad = road;
      }
    }

    return nearestRoad;
  }

  DateTime _nextOccurrenceFor(NannyWeekday weekday, TimeOfDay startTime) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final targetIndex = weekday.index;
    final daysDifference = (targetIndex - todayIndex) % 7;

    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    ).add(Duration(days: daysDifference));

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }

    return candidate;
  }

  String _contractStatusLabelFor(Schedule schedule) {
    if (_isBalancePause(schedule.pauseReason)) {
      return 'Нужна оплата';
    }
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
    if (_isBalancePause(schedule.pauseReason)) {
      return AutonannyStatusVariant.danger;
    }
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

  bool _isBalancePause(String? raw) {
    return raw == 'insufficient_balance' ||
        raw == 'low_balance' ||
        raw == 'lack_of_funds';
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

class _ContractWeekPicker extends StatefulWidget {
  const _ContractWeekPicker({
    required this.onDateSelected,
    this.selectedWeekday,
  });

  final ValueChanged<DateTime> onDateSelected;
  final NannyWeekday? selectedWeekday;

  @override
  State<_ContractWeekPicker> createState() => _ContractWeekPickerState();
}

class _ContractWeekPickerState extends State<_ContractWeekPicker> {
  late DateTime _selectedDate;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _ContractWeekPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeekday != widget.selectedWeekday) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    final referenceDate = _dateForWeekday(widget.selectedWeekday);
    _selectedDate = referenceDate;
    _currentDate = referenceDate;
  }

  DateTime _dateForWeekday(NannyWeekday? weekday) {
    final now = DateTime.now();
    if (weekday == null) {
      return DateUtils.dateOnly(now);
    }

    final todayIndex = now.weekday - 1;
    final targetIndex = weekday.index;
    final daysDifference = (targetIndex - todayIndex) % 7;

    return DateUtils.dateOnly(now.add(Duration(days: daysDifference)));
  }

  DateTime get _weekStart {
    final daysAfterMonday = _currentDate.weekday - 1;
    return DateUtils.dateOnly(
      _currentDate.subtract(Duration(days: daysAfterMonday)),
    );
  }

  List<DateTime> get _visibleWeek {
    final start = _weekStart;
    return List<DateTime>.generate(
      7,
      (index) => DateUtils.dateOnly(start.add(Duration(days: index))),
      growable: false,
    );
  }

  void _shiftWeek(bool forward) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: forward ? 7 : -7));
      final visibleWeek = _visibleWeek;
      final matchesSelectedWeek = visibleWeek.any(
        (date) => DateUtils.isSameDay(date, _selectedDate),
      );
      if (!matchesSelectedWeek) {
        _selectedDate = visibleWeek.first;
      }
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _currentDate = _selectedDate;
    });
    widget.onDateSelected(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final monthLabel = DateFormat('LLLL', 'ru_RU').format(_currentDate);

    return Column(
      children: [
        Row(
          children: [
            AutonannyIconButton(
              size: 40,
              variant: AutonannyIconButtonVariant.ghost,
              icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
              onPressed: () => _shiftWeek(false),
              tooltip: 'Предыдущая неделя',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    monthLabel[0].toUpperCase() + monthLabel.substring(1),
                    style: AutonannyTypography.h3(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AutonannySpacing.xs),
                  Text(
                    '${_currentDate.year}',
                    style: AutonannyTypography.bodyS(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AutonannyIconButton(
              size: 40,
              variant: AutonannyIconButtonVariant.ghost,
              icon: const AutonannyIcon(AutonannyIcons.arrowRight),
              onPressed: () => _shiftWeek(true),
              tooltip: 'Следующая неделя',
            ),
          ],
        ),
        const SizedBox(height: AutonannySpacing.lg),
        Row(
          children: [
            for (var index = 0; index < _visibleWeek.length; index++) ...[
              Expanded(
                child: _ContractWeekdayTile(
                  date: _visibleWeek[index],
                  isSelected: DateUtils.isSameDay(
                    _visibleWeek[index],
                    _selectedDate,
                  ),
                  onTap: () => _selectDate(_visibleWeek[index]),
                ),
              ),
              if (index != _visibleWeek.length - 1)
                const SizedBox(width: AutonannySpacing.xs),
            ],
          ],
        ),
      ],
    );
  }
}

class _ContractWeekdayTile extends StatelessWidget {
  const _ContractWeekdayTile({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final weekdayLabel = DateFormat('EE', 'ru_RU').format(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.xs,
            vertical: AutonannySpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colors.actionPrimary : colors.surfaceSecondary,
            borderRadius: AutonannyRadii.brMd,
            boxShadow: isSelected ? AutonannyShadows.card : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekdayLabel[0].toUpperCase() + weekdayLabel.substring(1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AutonannyTypography.labelM(
                  color: isSelected ? colors.textInverse : colors.textSecondary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                '${date.day}',
                style: AutonannyTypography.labelL(
                  color: isSelected ? colors.textInverse : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraphHeader extends StatelessWidget {
  const _GraphHeader({
    required this.vm,
  });

  final GraphVM vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final selectedDayLabel = vm.selectedDay?.fullName ?? 'Выберите день';

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.lg),
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
                      'Расписание поездок',
                      style: AutonannyTypography.caption(
                        color: colors.textInverse.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      'Выбранный день',
                      style: AutonannyTypography.bodyS(
                        color: colors.textInverse.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      selectedDayLabel,
                      style: AutonannyTypography.h2(
                        color: colors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      'Смотрите все маршруты по вашим контрактам на выбранный день и переходите в детали нужного договора.',
                      style: AutonannyTypography.bodyS(
                        color: colors.textInverse.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.md),
          Wrap(
            spacing: AutonannySpacing.sm,
            runSpacing: AutonannySpacing.sm,
            children: [
              _InvertedChip(
                icon: AutonannyIcons.calendar,
                label: selectedDayLabel,
              ),
              _InvertedChip(
                icon: AutonannyIcons.list,
                label: _contractsCountLabel(vm.schedules.length),
              ),
              if (vm.schedules.isNotEmpty)
                _InvertedChip(
                  icon: AutonannyIcons.clock,
                  label: 'Всего: ${vm.schedules.length}',
                ),
            ],
          ),
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
  const _ContractStatusSection({
    required this.selectedDay,
    required this.tripsCount,
    required this.contractsCount,
  });

  final NannyWeekday? selectedDay;
  final int tripsCount;
  final int contractsCount;

  @override
  Widget build(BuildContext context) {
    final dayLabel = selectedDay?.fullName.toLowerCase() ?? 'выбранный день';

    return AutonannySectionContainer(
      title: tripsCount > 0
          ? 'Поездки на $dayLabel'
          : 'На $dayLabel поездок пока нет',
      subtitle: tripsCount > 0
          ? 'На выбранный день запланированы маршруты по ${_contractsCountLabel(contractsCount).toLowerCase()}.'
          : 'Переключите день или откройте вкладку контрактов, чтобы посмотреть нужный договор.',
      trailing: AutonannyBadge(
        label: _tripsCountLabel(tripsCount),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BudgetCard(
              title: 'Контрактов',
              amount: '$contractsCount',
              tone: _BudgetCardTone.primary,
            ),
          ),
          const SizedBox(width: AutonannySpacing.md),
          Expanded(
            child: _BudgetCard(
              title: 'Маршрутов',
              amount: '$tripsCount',
              tone: _BudgetCardTone.neutral,
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

String _tripsCountLabel(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;

  if (mod10 == 1 && mod100 != 11) {
    return '$count поездка';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return '$count поездки';
  }
  return '$count поездок';
}

class _ScheduledDayTrip {
  const _ScheduledDayTrip({
    required this.schedule,
    required this.road,
  });

  final Schedule schedule;
  final Road road;
}

class _SelectedDayTripCard extends StatelessWidget {
  const _SelectedDayTripCard({
    required this.schedule,
    required this.road,
    required this.childLabels,
    required this.statusLabel,
    required this.statusVariant,
    required this.onOpenContract,
  });

  final Schedule schedule;
  final Road road;
  final List<String> childLabels;
  final String statusLabel;
  final AutonannyStatusVariant statusVariant;
  final VoidCallback onOpenContract;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final fromAddress = road.addresses.isEmpty
        ? 'Точка отправления не указана'
        : road.addresses.first.fromAddress.address;
    final toAddress = road.addresses.isEmpty
        ? 'Точка прибытия не указана'
        : road.addresses.last.toAddress.address;
    final tripTypeLabel = road.typeDrive.contains(DriveType.roundTrip)
        ? 'Туда и обратно'
        : 'В одну сторону';
    final timeLabel = road.startTime == road.endTime
        ? 'Прибытие к первой точке: ${road.startTime.formatTime()}'
        : '${road.startTime.formatTime()} - ${road.endTime.formatTime()}';

    return AutonannyCard(
      onTap: onOpenContract,
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
                      schedule.title.isEmpty ? 'Контракт' : schedule.title,
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      timeLabel,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              AutonannyStatusChip(
                label: statusLabel,
                variant: statusVariant,
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.md),
          Text(
            road.title.isEmpty ? tripTypeLabel : road.title,
            style: AutonannyTypography.bodyM(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            tripTypeLabel,
            style: AutonannyTypography.caption(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          _TripAddressLine(
            label: 'Откуда',
            value: fromAddress,
            color: colors.actionPrimary,
            showConnector: true,
          ),
          _TripAddressLine(
            label: 'Куда',
            value: toAddress,
            color: colors.statusDanger,
          ),
          if (childLabels.isNotEmpty) ...[
            const SizedBox(height: AutonannySpacing.md),
            Text(
              'Дети в поездке',
              style: AutonannyTypography.caption(
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: AutonannySpacing.xs),
            Wrap(
              spacing: AutonannySpacing.sm,
              runSpacing: AutonannySpacing.sm,
              children: childLabels
                  .map((label) => _TripChip(label: label))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: AutonannySpacing.md),
          SizedBox(
            width: double.infinity,
            child: AutonannyButton(
              label: 'Открыть детали контракта',
              variant: AutonannyButtonVariant.secondary,
              onPressed: onOpenContract,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripAddressLine extends StatelessWidget {
  const _TripAddressLine({
    required this.label,
    required this.value,
    required this.color,
    this.showConnector = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: 22,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.autonannyColors.borderSubtle,
                    borderRadius: AutonannyRadii.brFull,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AutonannySpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AutonannyTypography.caption(
                    color: context.autonannyColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xxs),
                Text(
                  value,
                  style: AutonannyTypography.bodyM(
                    color: context.autonannyColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TripChip extends StatelessWidget {
  const _TripChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutonannySpacing.md,
        vertical: AutonannySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.autonannyColors.surfaceSecondary,
        borderRadius: AutonannyRadii.brFull,
      ),
      child: Text(
        label,
        style: AutonannyTypography.labelM(
          color: context.autonannyColors.textPrimary,
        ),
      ),
    );
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
