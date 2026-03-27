import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/route_sheet_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class RouteSheetResult {
  final Road road;
  final bool applyToAllSelectedDays;
  final List<NannyWeekday>? targetWeekdays;
  final List<int>? childIds;

  RouteSheetResult({
    required this.road,
    required this.applyToAllSelectedDays,
    this.targetWeekdays,
    this.childIds,
  });
}

class RouteSheetView extends StatefulWidget {
  final NannyWeekday weekday;
  final Road? road;
  final int? tariffId;
  final List<NannyWeekday>? allSelectedWeekdays;
  final bool applyToAllDaysDefault;
  final List<Child>? availableChildren;
  final List<int>? initialSelectedChildIds;

  const RouteSheetView({
    super.key,
    required this.weekday,
    this.road,
    this.tariffId,
    this.allSelectedWeekdays,
    this.applyToAllDaysDefault = true,
    this.availableChildren,
    this.initialSelectedChildIds,
  });

  @override
  State<RouteSheetView> createState() => _RouteSheetViewState();
}

class _RouteSheetViewState extends State<RouteSheetView> {
  late RouteSheetVM vm;
  late final Set<int> _selectedChildIds;

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
    _selectedChildIds = (widget.initialSelectedChildIds ??
            widget.availableChildren
                ?.map((child) => child.id)
                .whereType<int>()
                .toList(growable: false) ??
            const <int>[])
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final sheetTitle =
        widget.road == null ? "Новый маршрут" : "Редактирование маршрута";

    return BottomSheet(
      onClosing: () {},
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      enableDrag: false,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
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
                    Text(
                      sheetTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _confirm,
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
                        activeColor: Theme.of(context).colorScheme.primary,
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
                              key: ValueKey(e.controller),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: NannyTextForm(
                                isExpanded: true,
                                controller: e.controller,
                                readOnly: true,
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
                                    activeThumbColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Окно начала поездки",
                            style: NDT.bodyS.copyWith(color: NDT.neutral500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Укажите время начала и окончания окна, в которое водитель должен приехать к первой точке.",
                            style: NDT.caption.copyWith(color: NDT.neutral500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _TimePreviewCard(
                                  label: 'От',
                                  value: vm.timeRange?.startTime.formatTime() ??
                                      '—:—',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TimePreviewCard(
                                  label: 'До',
                                  value: vm.timeRange?.endTime.formatTime() ??
                                      '—:—',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: NdPrimaryButton(
                              label: vm.timeRange == null
                                  ? "Выбрать время"
                                  : "Изменить время",
                              onTap: vm.chooseTime,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.availableChildren != null) ...[
                      const SizedBox(height: 20),
                      _RouteChildrenSelectorSection(
                        children: widget.availableChildren!,
                        selectedChildIds: _selectedChildIds,
                        onToggle: _toggleChild,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleChild(int childId) {
    setState(() {
      if (_selectedChildIds.contains(childId)) {
        _selectedChildIds.remove(childId);
      } else {
        _selectedChildIds.add(childId);
      }
    });
  }

  void _confirm() {
    if (widget.availableChildren != null && _selectedChildIds.isEmpty) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Выберите хотя бы одного ребёнка для маршрута",
      );
      return;
    }

    vm.confirm(selectedChildIds: _selectedChildIds.toList(growable: false));
  }
}

class _TimePreviewCard extends StatelessWidget {
  const _TimePreviewCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: NDT.neutral0,
        borderRadius: NDT.brMd,
        border: Border.all(color: NDT.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: NDT.caption.copyWith(color: NDT.neutral500)),
          const SizedBox(height: 4),
          Text(value, style: NDT.h3.copyWith(color: NDT.primary)),
        ],
      ),
    );
  }
}

class _RouteChildrenSelectorSection extends StatelessWidget {
  const _RouteChildrenSelectorSection({
    required this.children,
    required this.selectedChildIds,
    required this.onToggle,
  });

  final List<Child> children;
  final Set<int> selectedChildIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            "Дети маршрута",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Выберите, кто поедет именно по этому маршруту. Доступны только дети, уже добавленные в контракт.",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            const Text(
              "Сначала добавьте детей в контракт.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
              ),
            )
          else
            ...children.map(
              (child) {
                final childId = child.id;
                final fullName = '${child.surname} ${child.name}'.trim();
                final subtitle = child.birthday == null
                    ? null
                    : 'Возраст: ${DateTime.now().year - child.birthday!.year} лет';

                return CheckboxListTile(
                  value: childId != null && selectedChildIds.contains(childId),
                  onChanged: childId == null ? null : (_) => onToggle(childId),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.primary,
                  title: Text(
                    fullName.isEmpty ? 'Ребёнок без имени' : fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: subtitle == null
                      ? null
                      : Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}
