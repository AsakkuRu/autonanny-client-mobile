import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nanny_components/base_views/view_models/route_sheet_vm.dart';
import 'package:nanny_components/widgets/nanny_text_forms.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class RouteSheetView extends StatefulWidget {
  final NannyWeekday weekday;
  final Road? road;
  final int? tariffId;

  const RouteSheetView({
    super.key,
    required this.weekday,
    this.road,
    this.tariffId,
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
        tariffId: widget.tariffId);
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
                  const Text("Новый маршрут",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: vm.confirm,
                    child: const Text("Готово"),
                  ),
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
                  IconButton(
                      onPressed: vm.addAddress, icon: const Icon(Icons.add)),
                  const SizedBox(height: 20),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: NannyTextForm(
                  //         controller: vm.timeFromController,
                  //         readOnly: true,
                  //         labelText: "Время от",
                  //         onTap: () => vm.chooseTime(isFrom: true),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 10),
                  //     Expanded(
                  //       child: NannyTextForm(
                  //         controller: vm.timeToController,
                  //         readOnly: true,
                  //         labelText: "Время до",
                  //         onTap: () =>  vm.chooseTime(isFrom: false),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  CheckboxListTile(
                    value: vm.isRoundTrip,
                    onChanged: (value) {
                      vm.isRoundTrip = value ?? false;
                      setState(() {});
                    },
                    title: const Text('Туда и обратно'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Theme.of(context).colorScheme.primary,
                    checkColor: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text("Время от и до:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: vm.chooseTime,
                      child: Text(vm.timeRange == null
                          ? "Выберите временной промежуток"
                          : vm.timeRange!.toLocalTimeString()))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
