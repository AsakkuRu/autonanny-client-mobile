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
      editor.childCount = schedule!
          .childrenCount; // Заполнение количества детей, если это нужно

      // Заполнение дней недели
      selectedWeekday = schedule!.weekdays;

      // Заполнение других параметров, если они есть в schedule
      for (var param in schedule!.otherParametrs) {
        editor.addParam(param); // Добавляем параметры, если они есть
      }
      // Заполнение маршрутов
      for (var road in schedule!.roads) {
        editor.addRoad(road); // Добавляем параметры, если они есть
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
    var road = await NannyDialogs.showRouteCreateOrEditSheet(
        context, selectedWeekday.first,
        road: updatingRoad);
    if (road == null) return;

    if (updatingRoad != null) {
      editor.deleteRoad(
        editor.roads.firstWhere(
          (e) => e.isIdenticalTo(updatingRoad),
        ),
      );
    }

    for (var weekday in selectedWeekday) {
      // FE-MVP-015: Добавляем выбранных детей к маршруту
      var updatedRoad = road.copyWith(
        weekDay: weekday,
        children: selectedChildrenIds.isNotEmpty ? selectedChildrenIds : null,
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
    update(() {
      if (!selectedWeekday.contains(weekday)) {
        selectedWeekday.add(weekday);
        if (errorText != null && selectedWeekday.length >= 4) {
          errorText = null;
        }
      } else {
        selectedWeekday.remove(weekday);
      }
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

  // FE-MVP-015: Переключение выбора ребенка
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
    update(() {});
  }

  void confirm() async {
    if (!editor.valiateSchedule()) {
      NannyDialogs.showMessageBox(context, "Ошибка", "Заполните форму!");
      return;
    }
    
    LoadScreen.showLoad(context, true);

    var result = schedule == null
        ? await NannyOrdersApi.createSchedule(
            editor.createSchedule(selectedWeekday, id: schedule?.id),
          )
        : await NannyOrdersApi.updateScheduleById(
            editor.createSchedule(selectedWeekday, id: schedule?.id),
          );
    if (!result.success) {
      if (context.mounted) {
        LoadScreen.showLoad(context, false);
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      }
      return;
    }

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    await NannyDialogs.showMessageBox(context, "Успех",
        "График успешно ${schedule == null ? "создан" : "обновлен"}!");
    Navigator.of(context).pop();
  }

  // FE-MVP-008: Подсчёт количества поездок в месяц
  int _calculateTripsPerMonth() {
    // Количество уникальных маршрутов
    int uniqueRoads = editor.roads.length;
    
    // Если нет маршрутов, возвращаем 0
    if (uniqueRoads == 0) return 0;
    
    // Подсчитываем количество дней недели, на которые назначены маршруты
    Set<NannyWeekday> uniqueDays = {};
    for (var road in editor.roads) {
      uniqueDays.add(road.weekDay);
    }
    
    // Среднее количество недель в месяце = 4
    // Количество поездок в месяц = количество уникальных дней × 4
    return uniqueDays.length * 4;
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
