import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_loading_overlay.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_client/views/pages/graph_create.dart';
import 'package:nanny_components/base_views/views/direct.dart';
import 'package:nanny_components/base_views/views/driver_info.dart';
import 'package:nanny_components/dialogs/driver_qr_dialog.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:nanny_core/api/api_models/answer_schedule_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/nanny_core.dart';

class GraphVM extends ViewModelBase {
  GraphVM({
    required super.context,
    required super.update,
  });

  String spentsInWeek = "~ 0 ₽";
  String spentsInMonth = "~ 0 ₽";

  bool isOffline = false;

  List<Schedule> schedules = [];
  List<Child> children = [];
  Schedule? selectedSchedule;
  DriverContact? driverContact;
  List<ScheduleResponsesData> responses = [];

  /// ID графика для выбора при следующей загрузке (после создания нового).
  int? _selectScheduleIdOnNextLoad;

  /// При следующей загрузке выбрать самый новый график (fallback если id не получен).
  bool _selectNewestOnNextLoad = false;

  StreamSubscription<dynamic>? _scheduleUpdatesSub;
  StreamSubscription<dynamic>? _connectedSub;
  DateTime? _lastResponsesLoadAt;
  static const _responsesDebounceMs = 500;

  /// Подгрузка откликов (при событии contract.responses.updated или fallback).
  /// При обновлении откликов также подгружаем контакт водителя — заявка могла быть принята в чате.
  Future<void> loadResponsesOnly() async {
    if (isOffline) return;
    final now = DateTime.now();
    if (_lastResponsesLoadAt != null &&
        now.difference(_lastResponsesLoadAt!).inMilliseconds <
            _responsesDebounceMs) {
      return;
    }
    _lastResponsesLoadAt = now;
    var responsesResult = await NannyOrdersApi.getScheduleResponses();
    if (responsesResult.success && responsesResult.response != null) {
      responses = responsesResult.response!;
      update(() {});
      // После принятия заявки отклик исчезает; подгружаем контакт водителя
      if (selectedSchedule != null) {
        await loadDriverContact();
        update(() {});
      }
    }
  }

  /// Подписка на уведомления о новых откликах водителей по UnifiedSocket.
  void startScheduleUpdatesListener() {
    _scheduleUpdatesSub?.cancel();
    _connectedSub?.cancel();
    unawaited(_bindScheduleUpdatesListener());
  }

  Future<void> _bindScheduleUpdatesListener() async {
    try {
      final socket = UnifiedSocket.instance ?? await UnifiedSocket.connect();
      _setContractResponsesSubscription(socket, true);
      _scheduleUpdatesSub = socket.on('contract.responses.updated').listen((_) {
        reloadPage(); // FIX-005: перезагрузить полностью, чтобы подтянуть is_paused
      });
      _connectedSub = socket.on('connected').listen((_) {
        _setContractResponsesSubscription(socket, true);
      });
    } catch (e, st) {
      Logger().e('GraphVM unified schedule listener error: $e\n$st');
    }
  }

  void _setContractResponsesSubscription(
    UnifiedSocket socket,
    bool enabled,
  ) {
    socket.send('subscriptions.update', {
      'subscriptions': {'contract.responses': enabled}
    });
  }

  void stopScheduleUpdatesListener() {
    _scheduleUpdatesSub?.cancel();
    _connectedSub?.cancel();
    final socket = UnifiedSocket.instance;
    if (socket != null && socket.connected) {
      _setContractResponsesSubscription(socket, false);
    }
    _scheduleUpdatesSub = null;
    _connectedSub = null;
  }

  List<NannyWeekday> selectedWeekday = [
    NannyWeekday.values[DateTime.now().weekday - 1]
  ];

  // --- Вспомогательные геттеры для статуса графика и водителя ---

  List<ScheduleResponsesData> get _responsesForSelectedSchedule =>
      selectedSchedule == null
          ? const []
          : responses
              .where((r) => r.idSchedule == selectedSchedule?.id)
              .toList();

  bool get hasDriver => driverContact != null;

  /// Короткий статус программы/контракта для родителя.
  String get contractStatusLabel {
    if (selectedSchedule == null) {
      return 'График не выбран';
    }
    if (hasDriver) {
      return 'Контракт подтверждён';
    }
    if (_responsesForSelectedSchedule.isNotEmpty) {
      return 'Ожидает выбора водителя';
    }
    return 'Ожидает откликов водителей';
  }

  /// Дополнительное описание статуса.
  String get contractStatusDescription {
    if (selectedSchedule == null) {
      return 'Выберите график, чтобы увидеть детали программы.';
    }
    if (hasDriver) {
      return 'Вы выбрали автоняню, контракт активен. Перед поездкой будет доступен QR/PIN для верификации и чат с водителем.';
    }
    if (_responsesForSelectedSchedule.isNotEmpty) {
      return 'Есть отклики от водителей. Выберите подходящего водителя в списке откликов, чтобы подтвердить контракт.';
    }
    return 'Мы ищем для вас водителя. Как только появятся отклики, вы увидите их ниже и сможете выбрать автоняню.';
  }

  /// Краткая информация о ближайшей поездке по выбранному дню.
  String? get nextTripLabel {
    if (selectedSchedule == null || selectedWeekday.isEmpty) return null;
    final day = selectedWeekday.first;
    final roadsForDay =
        selectedSchedule!.roads.where((r) => r.weekDay == day).toList()
          ..sort(
            (a, b) => a.startTime.hour.compareTo(b.startTime.hour) != 0
                ? a.startTime.hour.compareTo(b.startTime.hour)
                : a.startTime.minute.compareTo(b.startTime.minute),
          );
    if (roadsForDay.isEmpty) return null;
    final road = roadsForDay.first;
    return '${road.startTime.formatTime()} – ${road.endTime.formatTime()}';
  }

  Map<int, String> get contractChildNamesById {
    return {
      for (final child in children)
        if (child.id != null)
          child.id!: '${child.name} ${child.surname}'.trim(),
    };
  }

  List<Child> get selectedScheduleChildren {
    final selectedIds = selectedSchedule == null
        ? <int>{}
        : selectedSchedule!.roads
            .expand((road) => road.children ?? const <int>[])
            .toSet();

    return children
        .where((child) => child.id != null && selectedIds.contains(child.id))
        .toList(growable: false);
  }

  List<int> initialRouteChildrenIds({Road? road}) {
    final scheduleChildrenIds = selectedScheduleChildren
        .map((child) => child.id)
        .whereType<int>()
        .toSet();

    final routeChildren = road?.children
            ?.where((childId) => scheduleChildrenIds.contains(childId))
            .toList(growable: false) ??
        const <int>[];

    if (routeChildren.isNotEmpty) {
      return routeChildren;
    }

    return scheduleChildrenIds.toList(growable: false);
  }

  void _updateSpentsFromSelectedSchedule() {
    final schedule = selectedSchedule;
    if (schedule == null ||
        schedule.amountWeek == null ||
        schedule.amountMonth == null ||
        (schedule.amountWeek == 0 && schedule.amountMonth == 0)) {
      spentsInWeek = "—";
      spentsInMonth = "—";
    } else {
      spentsInWeek = "~ ${schedule.amountWeek!.round()} ₽";
      spentsInMonth = "~ ${schedule.amountMonth!.round()} ₽";
    }
  }

  Future<void> createOrEditRoute({Road? editingRoad}) async {
    if (selectedSchedule == null) return;
    final availableChildren = selectedScheduleChildren;

    final result = await NannyDialogs.showRouteCreateOrEditSheet(
      context,
      selectedWeekday.first,
      road: editingRoad,
      // В экране просмотра графика для уже созданного расписания
      // работа ведётся с конкретным днём, поэтому информация о "всех днях"
      // нам здесь не нужна — используем только сформированный Road.
      allSelectedWeekdays: [selectedWeekday.first],
      applyToAllDaysDefault: false,
      availableChildren: availableChildren.isEmpty ? null : availableChildren,
      initialSelectedChildIds: editingRoad == null
          ? null
          : initialRouteChildrenIds(road: editingRoad),
    );

    if (result == null) return;
    final road = availableChildren.isEmpty
        ? result.road
        : result.road.copyWith(
            children:
                result.childIds ?? initialRouteChildrenIds(road: editingRoad),
          );

    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    var apiResult = editingRoad == null
        ? await NannyOrdersApi.createScheduleRoadById(
            selectedSchedule!.id!, road)
        : await NannyOrdersApi.updateScheduleRoadById(road);

    if (!apiResult.success) {
      if (context.mounted) {
        LoadScreen.showLoad(context, false);
        NannyDialogs.showMessageBox(context, "Ошибка", apiResult.errorMessage);
      }

      return;
    }

    if (!context.mounted) return;

    LoadScreen.showLoad(context, false);

    NannyDialogs.showMessageBox(context, "Успех",
        editingRoad == null ? "Маршрут добавлен" : "Маршрут обновлён");
    reloadPage();
  }

  void toGraphCreate() async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (context) => const GraphCreate()),
    );
    if (result is int) {
      if (result > 0) {
        _selectScheduleIdOnNextLoad = result;
      } else if (result == -1) {
        // Fallback: id не получен от бэкенда, выберем самый новый график
        _selectNewestOnNextLoad = true;
      }
    }
    reloadPage();
  }

  void toGraphEdit({required Schedule schedule}) async {
    // Сразу фиксируем этот график как выбранный,
    // чтобы после возврата и перезагрузки остаться на нём.
    scheduleSelected(schedule);
    await navigateToView(GraphCreate(schedule: schedule));
    reloadPage();
  }

  void weekdaySelected(DateTime date) {
    //selectedWeekday.add(NannyWeekday.values[date.weekday - 1]);
    selectedWeekday[0] = NannyWeekday.values[date.weekday - 1];
    update(() {});
  }

  Future<void> scheduleSelected(Schedule schedule) async {
    update(() {
      selectedSchedule = schedule;
      driverContact = null; // Сбрасываем предыдущие контакты
    });
    _updateSpentsFromSelectedSchedule();

    // Загружаем контакты водителя
    await loadDriverContact();
  }

  Future<void> loadDriverContact() async {
    if (selectedSchedule == null || selectedSchedule!.id == null) return;

    var result = await NannyUsersApi.getDriverContact(selectedSchedule!.id!);
    if (result.success && result.response != null) {
      update(() {
        driverContact = result.response;
      });
    }
  }

  void deleteSchedule(Schedule schedule) async {
    if (!await NannyDialogs.confirmAction(
        context, "Удалить выбранный график?")) {
      return;
    }
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    var result = await NannyOrdersApi.deleteScheduleById(schedule.id!);
    if (!result.success) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      }
    }

    if (context.mounted) LoadScreen.showLoad(context, false);

    await reloadPage();
  }

  void tryDeleteRoad(Road road) async {
    bool confirm =
        await NannyDialogs.confirmAction(context, "Удалить выбранный маршрут?");

    if (!confirm) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    var result = await NannyOrdersApi.deleteScheduleRoadById(road.id!);
    if (!result.success) {
      if (context.mounted) {
        LoadScreen.showLoad(context, false);
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      }
      return;
    }

    if (context.mounted) LoadScreen.showLoad(context, false);

    reloadPage();
  }

  // FE-MVP-017: Показ QR-кода для верификации водителя (QR + PIN для ввода водителем)
  Future<void> showDriverQR() async {
    if (selectedSchedule == null || driverContact == null) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Информация о водителе недоступна",
      );
      return;
    }

    // Запрашиваем код встречи — он содержит meetingCode и id_schedule_road
    String? meetingCodePin;
    int? scheduleRoadId;
    final codeResult =
        await NannyOrdersApi.getMeetingCodeForSchedule(selectedSchedule!.id!);
    if (codeResult.success && codeResult.response?.meetingCode != null) {
      meetingCodePin = codeResult.response!.meetingCode;
      scheduleRoadId = codeResult.response!.idScheduleRoad;
    }

    // QR содержит всё необходимое для верификации: schedule:roadId:meetingCode
    // Водитель сканирует и сразу проходит верификацию без ввода PIN
    final String qrData;
    if (scheduleRoadId != null && meetingCodePin != null) {
      qrData = 'schedule:$scheduleRoadId:$meetingCodePin';
    } else {
      // Fallback: старый формат если код недоступен
      qrData =
          '${selectedSchedule!.id}:${NannyUser.userInfo!.id}:${DateTime.now().millisecondsSinceEpoch}';
    }

    if (!context.mounted) return;
    DriverQRDialog.show(
      context,
      driverName: '${driverContact!.name} ${driverContact!.surname}',
      carNumber: driverContact!.car?.number,
      carInfo: driverContact!.car?.fullInfo,
      photoPath: driverContact!.photo,
      qrData: qrData,
      meetingCodePin: meetingCodePin,
    );
  }

  // FE-MVP-010: По нажатию «Написать» создаём чат (если нет) и сразу открываем его
  Future<void> openDriverChat() async {
    if (selectedSchedule == null) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Выберите расписание",
      );
      return;
    }

    LoadScreen.showLoad(context, true);

    final result = await NannyChatsApi.createDriverChat(selectedSchedule!.id!);

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (!result.success) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        result.errorMessage,
      );
      return;
    }

    final chatId = result.response!;
    final driverName = driverContact != null
        ? '${driverContact!.name} ${driverContact!.surname}'
        : 'Водитель';
    await navigateToView(DirectView(idChat: chatId, name: driverName));
  }

  // Открытие профиля водителя по отклику
  void openDriverFromResponse(ScheduleResponsesData response) async {
    await navigateToView(DriverInfoView(
      id: response.idDriver,
      viewingOrder: true,
      scheduleData: response,
    ));
  }

  void answerResponse(ScheduleResponsesData response, bool accept) async {
    LoadScreen.showLoad(context, true);
    var result = await NannyOrdersApi.answerScheduleRequest(
      AnswerScheduleRequest(
        idSchedule: response.idSchedule,
        idResponses: [response.id],
        flag: accept,
      ),
    );
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);
    if (!result.success) {
      NannyDialogs.showMessageBox(context, 'Ошибка', result.errorMessage);
      return;
    }
    NannyDialogs.showMessageBox(
      context,
      'Успех',
      accept ? 'Водитель принят' : 'Отклик отклонён',
    );
    update(() {
      responses = responses
          .where((r) => !(r.idSchedule == response.idSchedule &&
              r.idDriver == response.idDriver))
          .toList();
    });
    if (accept && selectedSchedule?.id == response.idSchedule) {
      await loadDriverContact();
    }
    reloadPage();
  }

  @override
  Future<bool> loadPage() async {
    final idToSelect = _selectScheduleIdOnNextLoad ?? selectedSchedule?.id;
    final selectNewest = _selectNewestOnNextLoad;
    _selectScheduleIdOnNextLoad = null;
    _selectNewestOnNextLoad = false;
    final previouslySelectedId = idToSelect;

    var scheduleResult = await NannyOrdersApi.getSchedules();

    if (scheduleResult.success) {
      isOffline = false;
      schedules = scheduleResult.response!;

      final childrenResult = await NannyChildrenApi.getChildren();
      if (childrenResult.success && childrenResult.response != null) {
        children = childrenResult.response!;
      }

      // Сохраняем выбор пользователя: если до перезагрузки
      // был выбран конкретный график, пытаемся найти его в
      // обновлённом списке. При создании нового — выбираем по id или самый новый.
      if (previouslySelectedId != null) {
        selectedSchedule = schedules.firstWhere(
          (s) => s.id == previouslySelectedId,
          orElse: () => schedules.firstOrNull ?? schedules.first,
        );
      } else if (selectNewest && schedules.isNotEmpty) {
        selectedSchedule =
            schedules.reduce((a, b) => (a.id ?? 0) > (b.id ?? 0) ? a : b);
      } else {
        selectedSchedule = schedules.firstOrNull;
      }

      // Кэшируем расписание
      try {
        await NannyStorage.cacheSchedules(
          schedules.map((s) => s.toJson()).toList(),
        );
      } catch (_) {}

      var responsesResult = await NannyOrdersApi.getScheduleResponses();
      if (responsesResult.success && responsesResult.response != null) {
        responses = responsesResult.response!;
        try {
          await NannyStorage.cacheResponses(
            responses.map((r) => r.toJson()).toList(),
          );
        } catch (_) {}
      }

      _updateSpentsFromSelectedSchedule();

      // При первом открытии экрана сразу подтягиваем контакт водителя
      // для автоматически выбранного графика, чтобы статус был корректным.
      if (selectedSchedule != null) {
        await loadDriverContact();
      }

      update(() {});
      return true;
    }

    // Оффлайн-режим: загрузка из кэша
    try {
      final cachedSchedules = await NannyStorage.getCachedSchedules();
      if (cachedSchedules != null && cachedSchedules.isNotEmpty) {
        isOffline = true;
        schedules = cachedSchedules
            .map((x) => Schedule.fromJson(Map<String, dynamic>.from(x)))
            .toList();

        if (previouslySelectedId != null) {
          selectedSchedule = schedules.firstWhere(
            (s) => s.id == previouslySelectedId,
            orElse: () => schedules.firstOrNull ?? schedules.first,
          );
        } else {
          selectedSchedule = schedules.firstOrNull;
        }

        final cachedResponses = await NannyStorage.getCachedResponses();
        if (cachedResponses != null) {
          responses = cachedResponses
              .map((x) =>
                  ScheduleResponsesData.fromJson(Map<String, dynamic>.from(x)))
              .toList();
        }

        _updateSpentsFromSelectedSchedule();

        // То же поведение в оффлайн-режиме: пытаемся загрузить контакт
        // по автоматически выбранному графику (если есть сеть).
        if (selectedSchedule != null) {
          await loadDriverContact();
        }

        update(() {});
        return true;
      }
    } catch (_) {}

    return false;
  }
}
