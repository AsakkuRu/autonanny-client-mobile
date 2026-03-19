import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nanny_components/base_views/view_models/route_sheet_vm.dart';
import 'package:nanny_components/widgets/nanny_text_forms.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class RouteSheetResult {
  final Road road;
  final bool applyToAllSelectedDays;
  final List<NannyWeekday>? targetWeekdays;

  RouteSheetResult({
    required this.road,
    required this.applyToAllSelectedDays,
    this.targetWeekdays,
  });
}

class RouteSheetView extends StatefulWidget {
  final NannyWeekday weekday;
  final Road? road;
  final int? tariffId;
  final List<NannyWeekday>? allSelectedWeekdays;
  final bool applyToAllDaysDefault;

  const RouteSheetView({
    super.key,
    required this.weekday,
    this.road,
    this.tariffId,
    this.allSelectedWeekdays,
    this.applyToAllDaysDefault = true,
  });

  @override
  State<RouteSheetView> createState() => _RouteSheetViewState();
}

class _RouteSheetViewState extends State<RouteSheetView> {
  late RouteSheetVM vm;

  @override
  void initState() {
    super.initState();
    vm = RouteSheetVM(
        context: context,
        update: setState,
        weekday: widget.weekday,
        road: widget.road,
        tariffId: widget.tariffId,
        allSelectedWeekdays: widget.allSelectedWeekdays,
        applyToAllDaysDefault: widget.applyToAllDaysDefault);
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      enableDrag: false,
      builder: (context) => SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: vm.cancel,
                    child: const Text("Отменить"),
                  ),
                  const Text(
                    "Новый маршрут",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: vm.confirm,
                    child: const Text("Готово"),
                  ),
                ],
              ),
            ),
            if (vm.allSelectedWeekdays != null &&
                vm.allSelectedWeekdays!.length > 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: vm.applyToAllSelectedDays,
                      onChanged: (value) {
                        vm.applyToAllSelectedDays = value ?? true;
                        vm.update(() {});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor:
                          Theme.of(context).colorScheme.primary,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Использовать маршрут для всех выбранных дней',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Если выключить — маршрут будет создан только для одного дня недели.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                    if (!vm.applyToAllSelectedDays) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<NannyWeekday>(
                          value: vm.selectedWeekdayForRoute,
                          onChanged: (value) {
                            if (value == null) return;
                            vm.selectedWeekdayForRoute = value;
                            vm.update(() {});
                          },
                          items: (vm.allSelectedWeekdays!.toList()
                                ..sort(
                                  (a, b) => a.index.compareTo(b.index),
                                ))
                              .map(
                                (d) => DropdownMenuItem<NannyWeekday>(
                                  value: d,
                                  child: Text(d.fullName),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  NannyTextForm(
                    isExpanded: true,
                    controller: vm.nameController,
                    labelText: "Название маршрута",
                    onChanged: (text) => vm.roadName = text,
                  ),
                  const SizedBox(height: 30),
                  NannyTextForm(
                    isExpanded: true,
                    controller: vm.fromController,
                    readOnly: true,
                    labelText: "Откуда (Адрес)",
                    onTap: () => vm.chooseAddress(from: true),
                  ),
                  const SizedBox(height: 10),
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: vm.addresses
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NannyTextForm(
                              isExpanded: true,
                              controller: e.controller,
                              labelText: "Промежуточный адрес",
                              suffixIcon: IconButton(
                                splashRadius: 20,
                                onPressed: () => vm.removeAddress(e),
                                icon: const Icon(Icons.delete,
                                    color: Colors.black),
                              ),
                              onTap: () => vm.chooseAddtionAddress(e),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: vm.addAddress,
                      icon: const Icon(Icons.add),
                      label: const Text("Добавить промежуточный адрес"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  NannyTextForm(
                    isExpanded: true,
                    controller: vm.toController,
                    readOnly: true,
                    labelText: "Куда (Адрес)",
                    onTap: () => vm.chooseAddress(from: false),
                  ),
                  // NEW-006: блок только когда есть откуда/куда и рассчитана стоимость (или идёт загрузка)
                  if (vm.addressFrom != null &&
                      vm.addressTo != null &&
                      (vm.estimatedLoading || vm.estimatedPrice != null)) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money,
                              color: Color(0xFF2E7D32), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              vm.estimatedLoading
                                  ? "Расчёт стоимости…"
                                  : "Предварительная стоимость маршрута: ${vm.estimatedPrice!.toStringAsFixed(0)} ₽",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Тип и время поездки",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  "Туда и обратно",
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: vm.isRoundTrip,
                                  onChanged: (value) {
                                    vm.isRoundTrip = value;
                                    vm.update(() {});
                                  },
                                  activeColor: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Время от и до",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: vm.chooseTime,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                            child: Text(
                              vm.timeRange == null
                                  ? "Выбрать время"
                                  : vm.timeRange!.toLocalTimeString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
