import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_loading_overlay.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/schedule_editor.dart';

class GraphCreateVM extends ViewModelBase {
  final Schedule? schedule;

  GraphCreateVM({
    this.schedule,
    required super.context,
    required super.update,
  });

  String? errorText;
  List<DriveTariff> tariffs = [];
  List<OtherParametr> params = [];
  late ScheduleEditor editor;

  TextEditingController nameController = TextEditingController();
  TextEditingController childController = TextEditingController();
  List<NannyWeekday> selectedWeekday = [NannyWeekday.monday];

  // FE-MVP-015: Список детей и выбранные дети
  List<Child> children = [];
  List<int> selectedChildrenIds = [];

  @override
  Future<bool> loadPage() async {
    // Получаем тарифы
    var tariffResult = await NannyStaticDataApi.getTariffs();
    if (!tariffResult.success) return false;
    tariffs = tariffResult.response!;

    // Получаем другие параметры
    var paramsResult = await NannyStaticDataApi.getOtherParams();
    if (!paramsResult.success) return false;
    params = paramsResult.response!;

    // FE-MVP-015: Загружаем список детей
    var childrenResult = await NannyChildrenApi.getChildren();
    if (childrenResult.success && childrenResult.response != null) {
      children = childrenResult.response!;
    }

    editor = ScheduleEditor(initTariff: tariffs.first);

    // Если schedule есть, то заполняем поля
    if (schedule != null) {
      nameController.text = schedule?.title ?? '';

      // Заполняем редактор с данными из schedule
      if (tariffs.isNotEmpty) {
        editor.tariff = tariffs.firstWhere(
          (e) => e.id == schedule!.tariff.id,
          orElse: () => tariffs.first,
        );
      }
      editor.title = schedule!.title; // Заполнение названия
      editor.type = GraphType.values.firstWhere(
        (e) => e.duration == schedule!.duration,
        orElse: () => GraphType.week,
      );

      // NEW-005: при редактировании восстанавливаем детей контракта как
      // объединение детей из всех маршрутов.
      final restoredChildrenIds = schedule!.roads
          .expand((road) => road.children ?? const <int>[])
          .toSet()
          .toList(growable: false);
      if (restoredChildrenIds.isNotEmpty) {
        selectedChildrenIds = restoredChildrenIds;
      }
      editor.childCount = selectedChildrenIds.isNotEmpty
          ? selectedChildrenIds.length
          : schedule!.childrenCount;

      // Заполнение дней недели
      selectedWeekday = schedule!.weekdays;

      // Заполнение других параметров, если они есть в schedule
      for (var param in schedule!.otherParametrs) {
        editor.addParam(param);
      }
      // Заполнение маршрутов
      for (var road in schedule!.roads) {
        editor.addRoad(road);
      }
    } else {
      // Если schedule нет, то создаем новый редактор
      editor = ScheduleEditor(initTariff: tariffs.first);
    }
    update(() {});

    return true;
  }

  void changeTitle(String? text) {
    editor.title = text!;
  }

  void deleteRoute(Road road) async {
    editor.deleteRoad(road);

    update(() {});
  }

  void childCountChanged(String text) {
    if (text.isEmpty) {
      childController.text = "";
      editor.childCount = 0;
      update(() {});
      return;
    }

    int? count = int.tryParse(text);

    if (count == null) {
      childController.text = editor.childCount.toString();
      update(() {});
      return;
    }

    // FE-MVP-007: Валидация максимум 4 детей
    if (count > 4) {
      NannyDialogs.showMessageBox(
        context,
        "Ограничение",
        "Максимум 4 ребенка на одного водителя для обеспечения безопасности",
      );
      count = 4;
    }

    editor.childCount = count;
    childController.text = editor.childCount.toString();
    update(() {});
  }

  void graphTypeChanged(GraphType? type) {
    editor.type = type!;
    update(() {});
  }

  void tariffSelected(DriveTariff? tariff) {
    editor.tariff = tariff!;
    update(() {});
  }

  void weekdaySelected(NannyWeekday weekday) {
    update(() {
      if (!selectedWeekday.contains(weekday)) {
        selectedWeekday.add(weekday);
        if (errorText != null && selectedWeekday.isNotEmpty) {
          errorText = null;
        }
      } else {
        selectedWeekday.remove(weekday);
        final routesForRemovedDay = editor.roads
            .where((road) => road.weekDay == weekday)
            .toList(growable: false);
        for (final road in routesForRemovedDay) {
          editor.deleteRoad(road);
        }
      }
      selectedWeekday.sort((left, right) => left.index.compareTo(right.index));
    });
  }

  void selectCarType(DriveTariff type) {
    editor.tariff = type;
    update(() {});
  }

  void addParam(OtherParametr param) {
    editor.addParam(param);
    update(() {});
  }

  void removeParam(OtherParametr param) {
    editor.deleteParam(param);
    update(() {});
  }

  // FE-MVP-015: Переключение выбора ребенка. NEW-005: количество = длина выбранных.
  void toggleChildSelection(int childId) {
    if (selectedChildrenIds.contains(childId)) {
      selectedChildrenIds.remove(childId);
      _syncRouteChildrenWithSelectedChildren();
    } else {
      // FE-MVP-007: Ограничение максимум 4 детей
      if (selectedChildrenIds.length >= 4) {
        NannyDialogs.showMessageBox(
          context,
          "Ограничение",
          "Максимальное количество детей в одном расписании - 4",
        );
        return;
      }
      selectedChildrenIds.add(childId);
    }
    editor.childCount = selectedChildrenIds.length;
    update(() {});
  }

  List<NannyWeekday> get sortedSelectedWeekdays {
    final days = List<NannyWeekday>.from(selectedWeekday);
    days.sort((left, right) => left.index.compareTo(right.index));
    return days;
  }

  List<Road> routesForDay(NannyWeekday weekday) {
    return editor.roads
        .where((road) => road.weekDay == weekday)
        .toList(growable: false);
  }

  List<Child> get selectedContractChildren {
    final selectedIds = selectedChildrenIds.toSet();
    return children
        .where((child) => child.id != null && selectedIds.contains(child.id))
        .toList(growable: false);
  }

  List<int> initialRouteChildrenIds({Road? road}) {
    final selectedIds = selectedChildrenIds.toSet();
    final routeChildren = road?.children
            ?.where((childId) => selectedIds.contains(childId))
            .toList(growable: false) ??
        const <int>[];
    if (routeChildren.isNotEmpty) {
      return routeChildren;
    }
    return List<int>.from(selectedChildrenIds);
  }

  List<Child> routeChildrenForRoad(Road road) {
    final routeChildIds = initialRouteChildrenIds(road: road).toSet();
    return selectedContractChildren
        .where((child) => child.id != null && routeChildIds.contains(child.id))
        .toList(growable: false);
  }

  int get selectedDaysCount => sortedSelectedWeekdays.length;

  int get routesCount => editor.roads.length;

  int get tripsPerMonth => routesCount * 4;

  double? get estimatedMonthlyAmount {
    if (editor.roads.isEmpty) {
      return null;
    }

    final amounts = editor.roads
        .map((road) => road.amount)
        .whereType<double>()
        .toList(growable: false);

    if (amounts.length != editor.roads.length) {
      return null;
    }

    return amounts.fold<double>(0, (sum, amount) => sum + amount);
  }

  double? get estimatedWeeklyAmount {
    final monthly = estimatedMonthlyAmount;
    if (monthly == null) {
      return null;
    }
    return monthly / 4;
  }

  String get selectedServicesLabel {
    final labels = editor.params
        .map((param) => (param.title ?? '').trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    if (labels.isEmpty) {
      return 'Без дополнительных услуг';
    }

    return labels.join(', ');
  }

  void saveRoute({
    required Road route,
    required NannyWeekday weekday,
    required List<int> childIds,
    Road? updatingRoad,
  }) {
    if (updatingRoad != null) {
      editor.deleteRoad(updatingRoad);
    }

    editor.addRoad(
      route.copyWith(
        weekDay: weekday,
        children: childIds,
      ),
    );
    update(() {});
  }

  void _syncRouteChildrenWithSelectedChildren() {
    final selectedIds = selectedChildrenIds.toSet();
    final roadsSnapshot = List<Road>.from(editor.roads);
    if (roadsSnapshot.isEmpty) {
      return;
    }

    for (final road in roadsSnapshot) {
      editor.deleteRoad(road);
    }

    for (final road in roadsSnapshot) {
      final routeChildren = road.children == null
          ? List<int>.from(selectedChildrenIds)
          : road.children!
              .where((childId) => selectedIds.contains(childId))
              .toList(growable: false);
      editor.addRoad(road.copyWith(children: routeChildren));
    }
  }

  void confirm() async {
    if (selectedChildrenIds.isEmpty) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Выберите хотя бы одного ребёнка для поездки",
      );
      return;
    }
    editor.childCount = selectedChildrenIds.length;

    if (!editor.valiateSchedule()) {
      // Более понятные сообщения об ошибке вместо общего «Заполните форму!»
      if (editor.title.isEmpty) {
        NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          "Введите название графика поездок",
        );
      } else if (editor.roads.isEmpty) {
        NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          "Добавьте хотя бы один маршрут в график",
        );
      } else {
        NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          "Заполните обязательные поля формы",
        );
      }
      return;
    }

    // Валидация: для всех выбранных дней должны быть заданы маршруты
    final usedDays =
        editor.roads.map((r) => r.weekDay).toSet().cast<NannyWeekday>();
    final requiredDays = selectedWeekday.toSet().cast<NannyWeekday>();
    final missingDays =
        requiredDays.where((d) => !usedDays.contains(d)).toList();

    if (missingDays.isNotEmpty) {
      final missingNames = missingDays.map((d) => d.shortName).join(", ");
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Для всех выбранных дней графика должны быть заданы маршруты.\n"
            "Сейчас нет маршрутов для: $missingNames.",
      );
      return;
    }

    final routesWithoutChildren = editor.roads
        .where((road) => initialRouteChildrenIds(road: road).isEmpty)
        .toList(growable: false);
    if (routesWithoutChildren.isNotEmpty) {
      final daysWithoutChildren = routesWithoutChildren
          .map((road) => road.weekDay.shortName)
          .toSet()
          .join(", ");
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "У каждого маршрута должны быть выбраны дети.\n"
            "Проверьте маршруты для: $daysWithoutChildren.",
      );
      return;
    }

    // Нормализуем children у маршрутов перед отправкой,
    // не перетирая route-specific привязки.
    final roadsSnapshot = List<Road>.from(editor.roads);
    for (var r in roadsSnapshot) {
      editor.deleteRoad(r);
    }
    for (var r in roadsSnapshot) {
      editor.addRoad(
        r.copyWith(children: initialRouteChildrenIds(road: r)),
      );
    }

    LoadScreen.showLoad(context, true);

    int? createdId;
    if (schedule == null) {
      final result = await NannyOrdersApi.createSchedule(
          editor.createSchedule(selectedWeekday, id: schedule?.id));
      if (!result.success) {
        if (context.mounted) {
          LoadScreen.showLoad(context, false);
          NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
        }
        return;
      }
      createdId = result.response != null && result.response! > 0
          ? result.response
          : null;
    } else {
      final result = await NannyOrdersApi.updateScheduleById(
          editor.createSchedule(selectedWeekday, id: schedule?.id));
      if (!result.success) {
        if (context.mounted) {
          LoadScreen.showLoad(context, false);
          NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
        }
        return;
      }
    }

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    await NannyDialogs.showMessageBox(context, "Успех",
        "График успешно ${schedule == null ? "создан" : "обновлен"}!");
    // При создании возвращаем id нового графика (или -1 как fallback "выбрать самый новый")
    final resultToPop = schedule == null ? (createdId ?? -1) : null;
    if (!context.mounted) return;
    Navigator.of(context).pop(resultToPop);
  }
}
