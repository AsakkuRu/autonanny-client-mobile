import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';

class ScheduleViewer extends StatelessWidget {
  final List<NannyWeekday> selectedWeedkays;
  final Schedule? schedule;
  final bool hasCheckBox;
  final List<int> selectedRoads;
  final void Function(Road road)? onDeleteRoad;
  final void Function(Road road)? onEditRoad;
  final void Function(int id, bool selected)? roadSelected;

  const ScheduleViewer({
    super.key,
    required this.schedule,
    required this.selectedWeedkays,
    this.hasCheckBox = false,
    this.selectedRoads = const [],
    this.roadSelected,
    this.onDeleteRoad,
    this.onEditRoad,
  });

  @override
  Widget build(BuildContext context) {
    return schedule == null
        ? const SizedBox()
        : Builder(builder: (context) {
            // Фильтруем маршруты по выбранным дням
            List<Road> roads = schedule!.roads
                .where((road) => selectedWeedkays.contains(road.weekDay))
                .toList();

            // Группируем маршруты по "шаблонам" (одинаковые по времени, адресам, типу и названию),
            // чтобы пользователь видел один маршрут с несколькими днями, а не дубликаты.
            final List<Road> uniqueRoads = [];
            final Map<Road, List<NannyWeekday>> roadDays = {};

            for (var road in roads) {
              final existing = uniqueRoads.cast<Road?>().firstWhere(
                    (u) => u != null && u.isIdenticalTo(road),
                    orElse: () => null,
                  );

              if (existing == null) {
                uniqueRoads.add(road);
                roadDays[road] = [road.weekDay];
              } else {
                roadDays[existing]!.add(road.weekDay);
              }
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final road = uniqueRoads[index];
                      final templateDays = roadDays[road] ?? [road.weekDay];

                      return ScheduleWidget(
                          onDeleteRoad: onDeleteRoad,
                          onEditRoad: onEditRoad,
                          road: road,
                          templateWeekdays: templateDays.toSet().toList(),
                          hasCheckBox: hasCheckBox,
                          selectedRoads: selectedRoads,
                          roadSelected: roadSelected);
                    },
                    separatorBuilder: (context, index) => const Divider(
                        color: NannyTheme.grey, height: 1, thickness: 1),
                    itemCount: uniqueRoads.length)
              ],
            );
          });
  }
}

class ScheduleWidget extends StatefulWidget {
  const ScheduleWidget({
    super.key,
    required this.road,
    required this.templateWeekdays,
    required this.hasCheckBox,
    required this.selectedRoads,
    required this.roadSelected,
    this.onDeleteRoad,
    this.onEditRoad,
  });

  final Road road;
  final List<NannyWeekday> templateWeekdays;
  final void Function(Road road)? onDeleteRoad;
  final void Function(Road road)? onEditRoad;
  final bool hasCheckBox;
  final List<int> selectedRoads;
  final void Function(int id, bool selected)? roadSelected;

  @override
  State<ScheduleWidget> createState() => _ScheduleWidgetState();
}

class _ScheduleWidgetState extends State<ScheduleWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final daysLabel = widget.templateWeekdays
        .map((d) => d.shortName)
        .toList()
        .join(", ");
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        onExpansionChanged: (value) => setState(() => isExpanded = value),
        shape: NannyTheme.roundBorder,
        title: Text(
          "${widget.road.startTime.formatTime()} - ${widget.road.endTime.formatTime()}",
          style: TextStyle(
              color: isExpanded ? NannyTheme.primary : const Color(0xFF2B2B2B),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: 'Nunito'),
        ),
        trailing: widget.hasCheckBox
            ? Checkbox(
                activeColor: NannyTheme.primary,
                value: widget.selectedRoads.contains(widget.road.id),
                onChanged: (value) =>
                    widget.roadSelected?.call(widget.road.id!, value!),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.road.title,
                    style: TextStyle(
                        color: isExpanded
                            ? NannyTheme.primary
                            : const Color(0xFF2B2B2B),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysLabel,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
        children: [
          ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                DriveAddress addresses = widget.road.addresses[index];
                String startAddress = addresses.fromAddress.address;
                String endAddress = addresses.toAddress.address;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (index == 0) Text(startAddress),
                      Container(
                        width: 2,
                        height: 15,
                        decoration: BoxDecoration(
                          color: NannyTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Text(endAddress),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(),
              itemCount: widget.road.addresses.length),
          // Кнопки редактирования/удаления показываем только там, где
          // реально переданы коллбеки (экран создания/редактирования графика).
          if (widget.onEditRoad != null || widget.onDeleteRoad != null) ...[
            const SizedBox(height: 10),
            if (widget.onEditRoad != null)
              ElevatedButton(
                style: NannyButtonStyles.main.copyWith(
                  minimumSize: const WidgetStatePropertyAll(
                    Size(double.infinity, 50),
                  ),
                ),
                onPressed: () => widget.onEditRoad?.call(widget.road),
                child: const Text("Изменить маршрут"),
              ),
            if (widget.onDeleteRoad != null) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                style: NannyButtonStyles.secondary.copyWith(
                  elevation: const WidgetStatePropertyAll(0),
                  minimumSize: const WidgetStatePropertyAll(
                    Size(double.infinity, 50),
                  ),
                ),
                onPressed: () => widget.onDeleteRoad?.call(widget.road),
                child: const Text("Удалить маршрут"),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
