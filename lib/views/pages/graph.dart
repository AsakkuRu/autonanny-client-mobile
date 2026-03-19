import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_client/view_models/pages/graph_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/widgets/schedule_viewer.dart';

class GraphView extends StatefulWidget {
  final bool persistState;

  const GraphView({
    super.key,
    this.persistState = false,
  });

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView>
    with AutomaticKeepAliveClientMixin {
  late GraphVM vm;
  Timer? _fallbackRefreshTimer;
  StreamSubscription<void>? _tabSelectedSub;

  @override
  void initState() {
    super.initState();
    vm = GraphVM(context: context, update: setState);
    vm.startScheduleUpdatesListener();
    _fallbackRefreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      vm.loadResponsesOnly();
    });
    _tabSelectedSub = NannyGlobals.scheduleTabSelectedController.stream.listen((_) {
      if (mounted) vm.reloadPage();
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
    if (wantKeepAlive) super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const NannyAppBar.light(
        hasBackButton: false,
        title: "График поездок",
      ),
      body: Column(
        children: [
          if (vm.isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: NannyTheme.warning.withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off,
                      size: 18, color: NannyTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Оффлайн-режим. Отображаются кэшированные данные.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NannyTheme.warningText,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FutureLoader(
              future: vm.loadRequest,
              completeView: (context, data) {
                if (!data) {
                  return const ErrorView(
                    errorText:
                        "Не удалось загрузить данные!\nПовторите попытку",
                  );
                }
                return ContractWidget(vm: vm);
              },
              errorView: (context, error) =>
                  ErrorView(errorText: error.toString()),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DateSelector(onDateSelected: vm.weekdaySelected),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NannyBottomSheet(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    FutureLoader(
                      future: vm.loadRequest,
                      completeView: (context, data) {
                        if (!data) {
                          return const ErrorView(
                            errorText:
                                "Не удалось загрузить данные!\nПовторите попытку",
                          );
                        }

                        if (vm.selectedSchedule == null) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Выберите график поездок, чтобы увидеть расписание.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: NannyTheme.neutral500,
                                    ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Статус программы / контракта
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: NannyTheme.primary.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: NannyTheme.primary.withOpacity(0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vm.contractStatusLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: NannyTheme.primaryDark,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vm.contractStatusDescription,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: NannyTheme.neutral600,
                                        ),
                                  ),
                                  if (vm.nextTripLabel != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ближайшая поездка: ${vm.nextTripLabel}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: NannyTheme.primaryDark,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // FIX-005: баннер паузы контракта
                            if (vm.selectedSchedule?.isPaused == true) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: NannyTheme.warning.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: NannyTheme.warning.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.pause_circle_outline,
                                        color: NannyTheme.warning, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Контракт приостановлен водителем',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: NannyTheme.warningText,
                                                ),
                                          ),
                                          if (vm.selectedSchedule?.pauseFrom != null ||
                                              vm.selectedSchedule?.pauseUntil != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (vm.selectedSchedule?.pauseFrom != null)
                                                  'с ${vm.selectedSchedule!.pauseFrom!.substring(0, 10)}',
                                                if (vm.selectedSchedule?.pauseUntil != null)
                                                  'по ${vm.selectedSchedule!.pauseUntil!.substring(0, 10)}',
                                              ].join(' '),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(color: NannyTheme.warningText),
                                            ),
                                          ],
                                          if (vm.selectedSchedule?.pauseReason != null &&
                                              vm.selectedSchedule!.pauseReason!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Причина: ${vm.selectedSchedule!.pauseReason}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(color: NannyTheme.warningText),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Отклики водителей
                            if (vm.responses
                                .where((r) =>
                                    r.idSchedule ==
                                    vm.selectedSchedule?.id)
                                .isNotEmpty) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Отклики водителей',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...vm.responses
                                  .where((r) =>
                                      r.idSchedule ==
                                      vm.selectedSchedule?.id)
                                  .map(
                                    (r) => Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: ListTile(
                                        onTap: () =>
                                            vm.openDriverFromResponse(r),
                                        leading: ProfileImage(
                                          url: r.photoPath,
                                          radius: 40,
                                          padding: EdgeInsets.zero,
                                        ),
                                        title: Text(
                                          r.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        subtitle: Text(
                                          '${r.data.length} маршрутов',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: NannyTheme.neutral500,
                                              ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check,
                                                  color: NannyTheme.success),
                                              onPressed: () =>
                                                  vm.answerResponse(r, true),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: NannyTheme.danger),
                                              onPressed: () =>
                                                  vm.answerResponse(r, false),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: 16),
                            ],

                            // Контакт водителя
                            if (vm.driverContact != null) ...[
                              DriverContactCard(
                                driver: vm.driverContact!,
                                onChatPressed: vm.openDriverChat,
                                onShowQR: vm.showDriverQR,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Расписание маршрутов
                            ScheduleViewer(
                              schedule: vm.selectedSchedule,
                              selectedWeedkays: vm.selectedWeekday,
                            ),
                          ],
                        );
                      },
                      errorView: (context, error) =>
                          ErrorView(errorText: error.toString()),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: budgetCard(
                            spents: vm.spentsInWeek,
                            title: "в неделю",
                            color: NannyTheme.primary.withOpacity(0.06),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: budgetCard(
                            spents: vm.spentsInMonth,
                            title: "в месяц",
                            color: NannyTheme.neutral50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget budgetCard(
      {required String spents, required String title, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Расходы $title',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: NannyTheme.neutral500,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            spents,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: NannyTheme.neutral900,
                ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}

class ContractWidget extends StatefulWidget {
  const ContractWidget({super.key, required this.vm});

  final GraphVM vm;

  @override
  State<ContractWidget> createState() => _ContractWidgetState();
}

class _ContractWidgetState extends State<ContractWidget> {
  bool isExpandedContracts = false;

  @override
  Widget build(BuildContext context) {
    // Если нет графиков, показываем сообщение
    if (widget.vm.schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'У вас пока нет графиков',
              style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.vm.toGraphCreate,
              icon: const Icon(Icons.add),
              label: const Text('Создать график'),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(NannyTheme.primary),
                foregroundColor: WidgetStatePropertyAll(NannyTheme.secondary),
              ),
            ),
          ],
        ),
      );
    }

    int countShowContract =
        widget.vm.schedules.length > 3 ? 3 : widget.vm.schedules.length;

    return Stack(
      children: [
        if (isExpandedContracts)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 52 / 2),
            padding: const EdgeInsets.symmetric(vertical: 52 / 2),
            color: Theme.of(context).colorScheme.surface,
            height: (76 * (countShowContract + 1)).toDouble(),
            child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final schedule = widget.vm.schedules[index];
                  return Card(
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    child: InkWell(
                      splashColor: Colors.grey.withOpacity(0.2),
                      highlightColor: Colors.grey.withOpacity(0.1),
                      onTap: () => setState(
                        () {
                          isExpandedContracts = !isExpandedContracts;
                          widget.vm.scheduleSelected(schedule);
                        },
                      ),
                      onLongPress: () => widget.vm.deleteSchedule(schedule),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 36 / 2,
                              child: ProfileImage(
                                  padding: EdgeInsets.zero,
                                  url: '',
                                  radius: 36),
                            ),
                            const SizedBox(width: 19),
                            Text(schedule.title),
                            const Spacer(),
                            Theme(
                              data: Theme.of(context)
                                  .copyWith(highlightColor: NannyTheme.primary),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: widget.vm.selectedSchedule == schedule
                                      ? NannyTheme.primary
                                      : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Theme.of(context)
                                              .colorScheme
                                              .surface
                                          : const Color(0xFFF7F7F7)),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                    style: const ButtonStyle(
                                      padding: WidgetStatePropertyAll(
                                          EdgeInsets.zero),
                                    ),
                                    onPressed: () => widget.vm
                                        .toGraphEdit(schedule: schedule),
                                    icon: Icon(Icons.arrow_forward_ios_rounded,
                                        color: widget.vm.selectedSchedule ==
                                                schedule
                                            ? NannyTheme.secondary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                        size: 15),
                                    splashRadius: 15),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1),
                      child: Divider(
                          color: NannyTheme.grey, height: 1, thickness: 1),
                    ),
                itemCount: widget.vm.schedules.length),
          ),
        SizedBox(
          height: isExpandedContracts
              ? (76 * (countShowContract + 1)).toDouble() + 52
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ContractButton(
                isExpanded: isExpandedContracts,
                text: widget.vm.selectedSchedule!.title,
                onPressed: () =>
                    setState(() => isExpandedContracts = !isExpandedContracts),
              ),
              if (isExpandedContracts)
                ContractButton(
                    isAddContractButton: true,
                    isRounderTopBorder: false,
                    onPressed: widget.vm.toGraphCreate),
            ],
          ),
        ),
      ],
    );
  }
}

class ContractButton extends StatelessWidget {
  const ContractButton(
      {super.key,
      this.text,
      this.isAddContractButton = false,
      this.isRounderTopBorder = true,
      required this.onPressed,
      this.isExpanded = false});

  final String? text;
  final bool isAddContractButton;
  final bool isRounderTopBorder;
  final Function() onPressed;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          if (isAddContractButton)
            BoxShadow(
                color: const Color(0xFF3028A8).withOpacity(.34),
                offset: const Offset(0, 5),
                blurRadius: 11)
          else if (isExpanded)
            BoxShadow(
                color: const Color(0xFF0D5118).withOpacity(.16),
                offset: const Offset(0, 5),
                blurRadius: 13,
                spreadRadius: -4)
          else
            BoxShadow(
                color: const Color(0xFF021C3B).withOpacity(.12),
                offset: const Offset(0, 4),
                blurRadius: 11)
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(10),
                bottomRight: const Radius.circular(10),
                topLeft: isRounderTopBorder
                    ? const Radius.circular(10)
                    : Radius.zero,
                topRight: isRounderTopBorder
                    ? const Radius.circular(10)
                    : Radius.zero,
              ),
            ),
          ),
          backgroundColor: WidgetStatePropertyAll(isAddContractButton
              ? NannyTheme.primary
              : isExpanded
                  ? NannyTheme.lightGreen
                  : Theme.of(context).colorScheme.surface),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.all(16),
          ),
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, 52),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAddContractButton ? 'Cоздать новый контракт' : text ?? '',
              style: TextStyle(
                  color: isAddContractButton
                      ? NannyTheme.secondary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Nunito'),
            ),
            if (isAddContractButton)
              const Icon(Icons.add, color: NannyTheme.secondary)
            else
              Icon(
                  color: Theme.of(context).colorScheme.onSurface,
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded)
          ],
        ),
      ),
    );
  }
}
