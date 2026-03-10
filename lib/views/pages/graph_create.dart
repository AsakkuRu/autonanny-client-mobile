import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/pages/graph_create_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/widgets/schedule_viewer.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class GraphCreate extends StatefulWidget {
  final Schedule? schedule;
  const GraphCreate({super.key, this.schedule});

  @override
  State<GraphCreate> createState() => _GraphCreateState();
}

class _GraphCreateState extends State<GraphCreate> {
  late GraphCreateVM vm;

  @override
  void initState() {
    super.initState();
    vm = GraphCreateVM(
        context: context, update: setState, schedule: widget.schedule);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f7),
      appBar: const NannyAppBar(
          color: Color(0xFFf7f7f7), title: "Новый график поездок"),
      body: FutureLoader(
        future: vm.loadRequest,
        completeView: (context, data) => !data
            ? const ErrorView(
                errorText:
                    "Не удалось загрузить данные для создания графика!\nПовторитк попытку")
            : SingleChildScrollView(
                padding: const EdgeInsets.only(top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NannyTextForm(
                              controller: vm.nameController,
                              labelText: 'Название графика',
                              isExpanded: true,
                              hintText: "Название",
                              onChanged: vm.changeTitle),
                          const SizedBox(height: 24),
                          
                          // FE-MVP-015: Выбор детей
                          const Text(
                            'Дети',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (vm.children.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFE69C)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Color(0xFF856404)),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Сначала добавьте профили детей в разделе "Дети"',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF856404),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...vm.children.map((child) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: vm.selectedChildrenIds.contains(child.id)
                                        ? NannyTheme.primary
                                        : const Color(0xFFE0E0E0),
                                    width: vm.selectedChildrenIds.contains(child.id) ? 2 : 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: vm.selectedChildrenIds.contains(child.id),
                                  onChanged: (value) => vm.toggleChildSelection(child.id!),
                                  title: Text(
                                    '${child.surname} ${child.name}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: child.birthday != null
                                      ? Text(
                                          'Возраст: ${DateTime.now().year - child.birthday!.year} лет',
                                          style: const TextStyle(fontSize: 13),
                                        )
                                      : null,
                                  secondary: child.photoPath != null
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(child.photoPath!),
                                        )
                                      : const CircleAvatar(
                                          child: Icon(Icons.child_care),
                                        ),
                                  activeColor: NannyTheme.primary,
                                ),
                              ),
                            )),
                          const SizedBox(height: 24),
                          DropDownWidget(
                            title: "Тип загруженности графика:",
                            value: vm.editor.type,
                            dropdownTexts:
                                GraphType.values.map((e) => e.name).toList(),
                            dropdownValues:
                                GraphType.values.map((e) => e).toList(),
                            onChanged: (value) => vm.graphTypeChanged(value),
                          ),
                          const SizedBox(height: 24),
                          WeeksSelector(
                              selectedWeekday: vm.selectedWeekday,
                              onChanged: vm.weekdaySelected),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.maxFinite,
                      child: Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 20, bottom: 32, left: 16, right: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScheduleViewer(
                                schedule: vm.editor
                                    .createSchedule(vm.selectedWeekday),
                                selectedWeedkays: vm.selectedWeekday,
                                onDeleteRoad: (road) => vm.deleteRoute(road),
                                onEditRoad: (road) =>
                                    vm.addOrEditRoute(updatingRoad: road),
                              ),
                              // FE-MVP-008: Счётчик поездок в месяц
                              if (vm.editor.roads.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildTripsCounter(vm),
                              ],
                              const SizedBox(height: 16),
                              FloatingActionButton(
                                onPressed: vm.addOrEditRoute,
                                child: const Icon(Icons.add),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Упрощенный UI тарифов (FE-MVP-006)
                          // Если тариф один - показываем информацию, иначе dropdown
                          if (vm.tariffs.length > 1)
                            DropDownWidget(
                              title: "Тариф:",
                              value: vm.editor.tariff,
                              dropdownTexts: vm.tariffs
                                  .map((e) => e.title ?? 'Неизвестный тариф')
                                  .toList(),
                              dropdownValues: vm.tariffs.map((e) => e).toList(),
                              onChanged: (value) => vm.tariffSelected(value),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
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
                                    'Категория:',
                                    style: TextStyle(
                                      color: Color(0xFF757575),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vm.tariffs.first.title ?? 'Заказ маршрута',
                                    style: const TextStyle(
                                      color: Color(0xFF2B2B2B),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Акцент на квалификации и опыте автоняни',
                                    style: TextStyle(
                                      color: Color(0xFF757575),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          AdditionalServiceWidget(vm: vm),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: NannyButtonStyles.main.copyWith(
                              minimumSize: const WidgetStatePropertyAll(
                                Size(double.infinity, 50),
                              ),
                            ),
                            onPressed: vm.confirm,
                            child: const Text("Отправить заявку"),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    )
                  ],
                ),
              ),
        errorView: (context, error) => ErrorView(
          errorText: error.toString(),
        ),
      ),
    );
  }

  // FE-MVP-008: Виджет счётчика поездок в месяц
  Widget _buildTripsCounter(GraphCreateVM vm) {
    // Каждый маршрут = 1 поездка в неделю × 4 недели
    int tripsPerMonth = vm.editor.roads.length * 4;
    bool isValid = tripsPerMonth >= 4;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.error_outline,
            color: isValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Поездок в месяц: $tripsPerMonth',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isValid 
                      ? 'Минимальное требование выполнено' 
                      : 'Минимум 4 поездки в месяц',
                  style: TextStyle(
                    fontSize: 12,
                    color: isValid ? const Color(0xFF558B2F) : const Color(0xFFD32F2F),
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

class AdditionalServiceWidget extends StatefulWidget {
  const AdditionalServiceWidget({
    super.key,
    required this.vm,
  });

  final GraphCreateVM vm;

  @override
  State<AdditionalServiceWidget> createState() =>
      _AdditionalServiceWidgetState();
}

class _AdditionalServiceWidgetState extends State<AdditionalServiceWidget> {
  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NannyTheme.secondary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF021C3B).withOpacity(.06),
              offset: const Offset(0, 4),
              blurRadius: 11),
        ],
      ),
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        collapsedIconColor: Color(0xFF2B2B2B),
        onExpansionChanged: (value) => setState(() => isExpanded = !isExpanded),
        trailing: Icon(
            isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 25),
        childrenPadding: const EdgeInsets.only(left: 16, right: 8),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Без линий
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Без линий
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text(
          "Доп. услуги",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        ),
        children: widget.vm.params
            .map(
              (e) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                shape: NannyTheme.roundBorder,
                title: Text(
                  e.title ?? "Неизвестная услуга",
                  style: const TextStyle(
                      color: Color(0xFF2B2B2B),
                      fontSize: 18,
                      fontWeight: FontWeight.w400),
                ),
                value: widget.vm.editor.params.contains(e),
                activeColor: NannyTheme.primary,
                onChanged: (value) {
                  if (value!) {
                    widget.vm.addParam(e);
                  } else {
                    widget.vm.removeParam(e);
                  }
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class DropDownWidget extends StatelessWidget {
  const DropDownWidget({
    super.key,
    required this.title,
    required this.dropdownValues,
    required this.dropdownTexts,
    this.value,
    required this.onChanged,
  });

  final String title;
  final List<dynamic> dropdownValues;
  final List<String> dropdownTexts;
  final dynamic value;
  final Function(dynamic) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: const TextStyle(
                color: Color(0xFF2B2B2B),
                fontSize: 16,
                fontWeight: FontWeight.w400),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF021C3B).withOpacity(.06),
                  offset: const Offset(0, 4),
                  blurRadius: 11),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 25,
                      color: Color(0xFF2B2B2B),
                    ),
                    isExpanded: true, // Важно для растяжения содержимого
                    borderRadius: BorderRadius.circular(20),
                    alignment: Alignment.center,
                    value: value,
                    items: List.generate(
                      dropdownTexts.length,
                      (index) => DropdownMenuItem(
                        value: dropdownValues[index],
                        child: Text(
                          dropdownTexts[index],
                          style: const TextStyle(
                              color: Color(0xFF2B2B2B),
                              fontSize: 18,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                    onChanged: onChanged),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
