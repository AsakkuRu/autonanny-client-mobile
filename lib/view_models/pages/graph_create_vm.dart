import 'package:flutter/material.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
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

      // NEW-005: при редактировании восстанавливаем выбранных детей из маршрутов
      if (schedule!.roads.isNotEmpty && schedule!.roads.first.children != null) {
        selectedChildrenIds = List<int>.from(schedule!.roads.first.children!);
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

  void addOrEditRoute({Road? updatingRoad}) async {
    if (updatingRoad == null && selectedWeekday.isEmpty) {
      NannyDialogs.showMessageBox(context, "Ошибка", "Выберите хотя бы один день");
      return;
    }
    final NannyWeekday baseWeekday =
        updatingRoad?.weekDay ??
            (selectedWeekday.isNotEmpty
                ? selectedWeekday.first
                : NannyWeekday.monday);

    final result = await NannyDialogs.showRouteCreateOrEditSheet(
      context,
      baseWeekday,
      road: updatingRoad,
      tariffId: editor.tariff.id,
      allSelectedWeekdays: selectedWeekday,
    );
    if (result == null) return;

    final road = result.road;

    // Определяем целевые дни для маршрута
    final List<NannyWeekday> targetDays =
        result.applyToAllSelectedDays && selectedWeekday.isNotEmpty
            ? List<NannyWeekday>.from(selectedWeekday)
            : (result.targetWeekdays ?? [road.weekDay]);

    // Если редактируем существующий маршрут — удаляем все его копии (по шаблону)
    if (updatingRoad != null) {
      final existingCopies =
          editor.roads.where((e) => e.isIdenticalTo(updatingRoad)).toList();
      for (final r in existingCopies) {
        editor.deleteRoad(r);
      }
    }

    // Добавляем новые маршруты по выбранным дням
    for (var weekday in targetDays) {
      final updatedRoad = road.copyWith(
        weekDay: weekday,
        children:
            selectedChildrenIds.isNotEmpty ? selectedChildrenIds : null,
      );
      editor.addRoad(updatedRoad);
    }

    update(() {});
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
    final previousDays = List<NannyWeekday>.from(selectedWeekday);

    update(() {
      if (!selectedWeekday.contains(weekday)) {
        selectedWeekday.add(weekday);
        if (errorText != null && selectedWeekday.isNotEmpty) {
          errorText = null;
        }
      } else {
        selectedWeekday.remove(weekday);
      }
    });

    _syncRoutesForAllDays(previousDays, selectedWeekday);
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

  void _syncRoutesForAllDays(
    List<NannyWeekday> previousDays,
    List<NannyWeekday> currentDays,
  ) {
    if (previousDays.isEmpty || editor.roads.isEmpty) return;

    final prevSet = previousDays.toSet();
    final currentSet = currentDays.toSet();

    final addedDays = currentSet.difference(prevSet);
    final removedDays = prevSet.difference(currentSet);

    if (addedDays.isEmpty && removedDays.isEmpty) return;

    final List<Road> templates = [];
    final Map<Road, Set<NannyWeekday>> templateDays = {};

    for (final road in editor.roads) {
      final existing = templates.cast<Road?>().firstWhere(
            (t) => t != null && t.isIdenticalTo(road),
            orElse: () => null,
          );

      if (existing == null) {
        templates.add(road);
        templateDays[road] = {road.weekDay};
      } else {
        templateDays[existing]!.add(road.weekDay);
      }
    }

    final List<Road> roadsToAdd = [];
    final List<Road> roadsToRemove = [];

    for (final template in templates) {
      final days = templateDays[template] ?? {};

      // Считаем маршрут "общим", если на момент изменения он покрывал
      // все ранее выбранные дни графика.
      if (prevSet.difference(days).isEmpty) {
        for (final day in addedDays) {
          roadsToAdd.add(
            template.copyWith(
              weekDay: day,
            ),
          );
        }

        for (final day in removedDays) {
          roadsToRemove.addAll(
            editor.roads.where(
              (r) => r.isIdenticalTo(template) && r.weekDay == day,
            ),
          );
        }
      }
    }

    for (final road in roadsToRemove) {
      editor.deleteRoad(road);
    }
    for (final road in roadsToAdd) {
      editor.addRoad(road);
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
      final missingNames =
          missingDays.map((d) => d.shortName).join(", ");
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Для всех выбранных дней графика должны быть заданы маршруты.\n"
        "Сейчас нет маршрутов для: $missingNames.",
      );
      return;
    }

    // Синхронизируем текущий выбор детей во все маршруты (в запрос уходят road.children)
    final roadsSnapshot = List<Road>.from(editor.roads);
    for (var r in roadsSnapshot) {
      editor.deleteRoad(r);
    }
    final childrenToSend = selectedChildrenIds;
    for (var r in roadsSnapshot) {
      editor.addRoad(r.copyWith(children: childrenToSend));
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
    final resultToPop = schedule == null
        ? (createdId ?? -1)
        : null;
    Navigator.of(context).pop(resultToPop);
  }

  // FE-MVP-008: Подсчёт количества поездок в месяц
  int _calculateTripsPerMonth() {
    // Каждый маршрут = 1 поездка в неделю, среднее кол-во недель в месяце = 4
    return editor.roads.length * 4;
  }

  String _getTripsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'поездка';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'поездки';
    } else {
      return 'поездок';
    }
  }
}
