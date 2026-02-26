import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    vm = GraphVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f7),
      appBar: const NannyAppBar(
        color: Color(0xFFf7f7f7),
        hasBackButton: false,
        title: "График поездок",
      ),
      body: Center(
          child: Column(
        children: [
          // ElevatedButton.icon(
          //   onPressed: () {},

          //   style: NannyButtonStyles.whiteButton,
          //   icon: const Text("Cоздать новый контракт"),
          //   label: const Icon(Icons.add),
          // ),
          if (vm.isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 18, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Оффлайн-режим. Отображаются кэшированные данные.',
                      style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureLoader(
                  future: vm.loadRequest,
                  completeView: (context, data) {
                    if (!data) {
                      return const ErrorView(
                          errorText: "Не удалось загрузить данные!"
                              "\nПовторите попытку");
                    }

                    return ContractWidget(vm: vm);

                    return ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: NannyTheme.lightGreen,
                      title: const Text("Графики"),
                    );

                    return ExpansionTile(
                        shape: NannyTheme.roundBorder,
                        collapsedShape: NannyTheme.roundBorder,
                        backgroundColor: NannyTheme.lightGreen,
                        collapsedBackgroundColor: NannyTheme.lightPink,
                        title: const Text("Графики"),
                        expandedAlignment: Alignment.center,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                        childrenPadding: const EdgeInsets.all(20),
                        children: vm.schedules
                            .map((e) => Container(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                    shape: NannyTheme.roundBorder,
                                    child: ListTile(
                                      shape: NannyTheme.roundBorder,
                                      selected: e == vm.selectedSchedule,
                                      title: Text(e.title,
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.normal)),
                                      enableFeedback: true,
                                      onLongPress: () => vm.deleteSchedule(e),
                                      onTap: () => vm.scheduleSelected(e),

                                      // trailing: IconButton(
                                      //   splashRadius: 20,
                                      //   onPressed: () {},
                                      //   icon: const Icon(Icons.edit)
                                      // ),
                                    ))))
                            .toList()
                        //..add(Padding(
                        //    padding: EdgeInsets.zero,
                        //    child: Material(
                        //        shape: NannyTheme.roundBorder,
                        //        elevation: 5,
                        //        child: ListTile(
                        //          shape: NannyTheme.roundBorder,
                        //          tileColor: NannyTheme.surface,
                        //          title: const Center(
                        //              child: Text("Cоздать новый график",
                        //                  style:
                        //                      TextStyle(fontSize: 18))),
                        //          trailing: const Icon(Icons.add),
                        //          onTap: vm.toGraphCreate,
                        //        ),),
                        //        ),
                        //        ),
                        );
                  },
                  errorView: (context, error) =>
                      ErrorView(errorText: error.toString()))),
          const SizedBox(height: 23),
          DateSelector(onDateSelected: vm.weekdaySelected),
          const SizedBox(height: 23),
          Expanded(
            child: NannyBottomSheet(
                child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  FutureLoader(
                    future: vm.loadRequest,
                    completeView: (context, data) {
                      if (!data) {
                        return const ErrorView(
                            errorText: "Не удалось загрузить данные!"
                                "\nПовторите попытку");
                      }

                      if (vm.selectedSchedule == null) {
                        return const Center(
                          child: Text(
                            'Выберите график',
                            style: TextStyle(fontSize: 16, color: Color(0xFF2B2B2B)),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // C-026: Отклики водителей
                          if (vm.responses.where((r) => r.idSchedule == vm.selectedSchedule?.id).isNotEmpty) ...[
                            const Text('Отклики водителей',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...vm.responses
                                .where((r) => r.idSchedule == vm.selectedSchedule?.id)
                                .map((r) => Card(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          child: r.photoPath.isNotEmpty
                                              ? ProfileImage(url: r.photoPath, radius: 40, padding: EdgeInsets.zero)
                                              : const Icon(Icons.person),
                                        ),
                                        title: Text(r.name),
                                        subtitle: Text('${r.data.length} маршрутов'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              onPressed: () => vm.answerResponse(r, true),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => vm.answerResponse(r, false),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                            const SizedBox(height: 16),
                          ],
                          
                          // Карточка контактов водителя (FE-MVP-009)
                          if (vm.driverContact != null) ...[
                            DriverContactCard(
                              driver: vm.driverContact!,
                              onChatPressed: vm.openDriverChat, // FE-MVP-010
                              onShowQR: vm.showDriverQR, // FE-MVP-017
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Расписание маршрутов
                          ScheduleViewer(
                            schedule: vm.selectedSchedule,
                            selectedWeedkays: vm.selectedWeekday,
                            onDeleteRoad: vm.tryDeleteRoad,
                            onEditRoad: (road) =>
                                vm.createOrEditRoute(editingRoad: road),
                          ),
                        ],
                      );
                    },
                    errorView: (context, error) =>
                        ErrorView(errorText: error.toString()),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF3028A8).withOpacity(.59),
                            offset: const Offset(0, 5),
                            blurRadius: 15,
                            spreadRadius: -6)
                      ],
                    ),
                    child: FloatingActionButton(
                      elevation: 0,
                      onPressed: vm.createOrEditRoute,
                      child: const Icon(Icons.add),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: budgetCard(
                            spents: vm.spentsInWeek,
                            title: "в неделю",
                            color: NannyTheme.lightGreen),
                      ),
                      Expanded(
                        child: budgetCard(
                            spents: vm.spentsInMonth,
                            title: "в месяц",
                            color: NannyTheme.lightPink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )),
          ),
        ],
      )),
    );
  }

  Widget budgetCard(
      {required String spents, required String title, required Color color}) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                spents,
                style: const TextStyle(
                    color: Color(0xFF2B2B2B),
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunit'),
              ),
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFF2B2B2B),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Nunito')),
            ],
          ),
        ),
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
            const Text(
              'У вас пока нет графиков',
              style: TextStyle(fontSize: 18, color: Color(0xFF2B2B2B)),
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
            color: NannyTheme.secondary,
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
                                      : const Color(0xFFF7F7F7),
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
                                            : NannyTheme.darkGrey,
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
                  : NannyTheme.secondary),
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
                      : const Color(0xFF2B2B2B),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Nunito'),
            ),
            if (isAddContractButton)
              const Icon(Icons.add, color: NannyTheme.secondary)
            else
              Icon(
                  color: const Color(0xFF2B2B2B),
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded)
          ],
        ),
      ),
    );
  }
}
