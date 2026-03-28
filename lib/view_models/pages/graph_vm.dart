import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_loading_overlay.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_client/views/pages/contract_builder_view.dart';
import 'package:nanny_client/views/rating/driver_rating_details_view.dart';
import 'package:nanny_components/base_views/views/direct.dart';
import 'package:nanny_components/base_views/views/driver_info.dart';
import 'package:nanny_components/dialogs/driver_qr_dialog.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';
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
    int? initialScheduleId,
  }) : _selectScheduleIdOnNextLoad = initialScheduleId;

  String spentsInWeek = "~ 0 ₽";
  String spentsInMonth = "~ 0 ₽";

  bool isOffline = false;

  List<Schedule> schedules = [];
  List<Child> children = [];
  Schedule? selectedSchedule;
  DriverContact? driverContact;
  List<ScheduleResponsesData> responses = [];
  List<OtherParametr> _otherParamsCatalog = [];

  /// ID контракта для выбора при следующей загрузке (после создания нового).
  int? _selectScheduleIdOnNextLoad;

  /// При следующей загрузке выбрать самый новый контракт (fallback если id не получен).
  bool _selectNewestOnNextLoad = false;

  /// После create/edit открыть детали выбранного контракта.
  bool _openSelectedScheduleDetailsOnNextLoad = false;

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
        unawaited(reloadPage());
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

  bool consumePendingDetailsOpen() {
    final shouldOpen = _openSelectedScheduleDetailsOnNextLoad;
    _openSelectedScheduleDetailsOnNextLoad = false;
    return shouldOpen;
  }

  List<NannyWeekday> selectedWeekday = [
    NannyWeekday.values[DateTime.now().weekday - 1]
  ];

  // --- Вспомогательные геттеры для статуса контракта и водителя ---

  List<ScheduleResponsesData> get _responsesForSelectedSchedule =>
      selectedSchedule == null
          ? const []
          : responses
              .where((r) => r.idSchedule == selectedSchedule?.id)
              .toList();

  bool get hasDriver => driverContact != null;

  /// Короткий статус программы/контракта для родителя.
  String get contractStatusLabel {
    final schedule = selectedSchedule;
    if (schedule == null) {
      return 'Контракт не выбран';
    }
    if (_isBalancePause(schedule.pauseReason)) {
      return 'Нужна оплата';
    }
    if (schedule.isPaused == true) {
      return 'Приостановлен';
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
    final schedule = selectedSchedule;
    if (schedule == null) {
      return 'Выберите контракт, чтобы увидеть его детали.';
    }
    if (_isBalancePause(schedule.pauseReason)) {
      return 'Поездки временно остановлены из-за нехватки средств. Откройте детали контракта, чтобы пополнить баланс или настроить автоплатёж.';
    }
    if (schedule.isPaused == true) {
      switch (schedule.pauseInitiatedBy) {
        case 1:
          return 'Водитель временно остановил поездки по этому контракту. В деталях контракта видны сроки паузы и причина.';
        case 2:
          return 'Вы временно поставили контракт на паузу. В деталях можно посмотреть сроки и при необходимости возобновить поездки досрочно.';
        case 3:
          return 'Контракт временно приостановлен системой. Проверьте детали контракта, чтобы понять причину паузы.';
        default:
          return 'Поездки по контракту временно остановлены. Откройте детали контракта, чтобы посмотреть сроки и причину паузы.';
      }
    }
    if (hasDriver) {
      return 'Вы выбрали автоняню, контракт активен. Перед поездкой будет доступен QR/PIN для верификации и чат с водителем.';
    }
    if (_responsesForSelectedSchedule.isNotEmpty) {
      return 'Есть отклики от водителей. Выберите подходящего водителя в списке откликов, чтобы подтвердить контракт.';
    }
    return 'Мы ищем для вас водителя. Как только появятся отклики, вы увидите их ниже и сможете выбрать автоняню.';
  }

  AutonannyStatusVariant get contractStatusVariant {
    final schedule = selectedSchedule;
    if (schedule == null) {
      return AutonannyStatusVariant.neutral;
    }
    if (_isBalancePause(schedule.pauseReason)) {
      return AutonannyStatusVariant.danger;
    }
    if (schedule.isPaused == true) {
      return AutonannyStatusVariant.warning;
    }
    if (hasDriver) {
      return AutonannyStatusVariant.success;
    }
    if (_responsesForSelectedSchedule.isNotEmpty) {
      return AutonannyStatusVariant.warning;
    }
    return AutonannyStatusVariant.neutral;
  }

  /// Краткая информация о ближайшей поездке по выбранному дню.
  String? get nextTripLabel {
    final schedule = selectedSchedule;
    if (schedule == null) {
      return null;
    }

    final road = _nearestUpcomingRoad(schedule);
    if (road == null) {
      return null;
    }

    return '${road.weekDay.shortName} · '
        '${road.startTime.formatTime()} – ${road.endTime.formatTime()}';
  }

  NannyWeekday? get selectedDay =>
      selectedWeekday.isEmpty ? null : selectedWeekday.first;

  List<Road> get selectedDayRoads {
    final day = selectedDay;
    if (selectedSchedule == null || day == null) {
      return const <Road>[];
    }
    final roadsForDay = selectedSchedule!.roads
        .where((road) => road.weekDay == day)
        .toList(growable: false);
    return List<Road>.from(roadsForDay)
      ..sort(
        (a, b) => a.startTime.hour.compareTo(b.startTime.hour) != 0
            ? a.startTime.hour.compareTo(b.startTime.hour)
            : a.startTime.minute.compareTo(b.startTime.minute),
      );
  }

  bool get hasRoutesForSelectedDay => selectedDayRoads.isNotEmpty;

  String get selectedDayEmptyMessage {
    final day = selectedDay;
    if (day == null) {
      return 'Выберите день, чтобы посмотреть маршруты контракта.';
    }
    return 'На ${day.fullName.toLowerCase()} по этому контракту поездки не запланированы. Переключите день или откройте детали контракта.';
  }

  Map<int, String> get contractChildNamesById {
    return {
      for (final child in children)
        if (child.id != null)
          child.id!: '${child.name} ${child.surname}'.trim(),
    };
  }

  List<Child> contractChildrenFor(Schedule schedule) {
    final selectedIds =
        schedule.roads.expand((road) => road.children ?? const <int>[]).toSet();

    return children
        .where((child) => child.id != null && selectedIds.contains(child.id))
        .toList(growable: false);
  }

  List<Child> get selectedScheduleChildren {
    final schedule = selectedSchedule;
    if (schedule == null) {
      return const <Child>[];
    }
    return contractChildrenFor(schedule);
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
      // В экране просмотра контракта для уже созданного расписания
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
      MaterialPageRoute(builder: (context) => const ContractBuilderView()),
    );
    if (result is int) {
      if (result > 0) {
        _selectScheduleIdOnNextLoad = result;
        _openSelectedScheduleDetailsOnNextLoad = true;
      } else if (result == -1) {
        // Fallback: id не получен от бэкенда, выберем самый новый контракт
        _selectNewestOnNextLoad = true;
        _openSelectedScheduleDetailsOnNextLoad = true;
      }
    }
    reloadPage();
  }

  void toGraphEdit({required Schedule schedule}) async {
    // Сразу фиксируем этот контракт как выбранный,
    // чтобы после возврата и перезагрузки остаться на нём.
    scheduleSelected(schedule);
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (context) => ContractBuilderView(contract: schedule),
      ),
    );
    if (result is int && result > 0) {
      _selectScheduleIdOnNextLoad = result;
      _openSelectedScheduleDetailsOnNextLoad = true;
    }
    reloadPage();
  }

  bool canEditSchedule(
    Schedule schedule, {
    int? responsesCount,
    bool? hasAssignedDriver,
  }) {
    return !_isScheduleOperational(
      schedule,
      responsesCount: responsesCount,
      hasAssignedDriver: hasAssignedDriver,
    );
  }

  String scheduleEditLockedMessage(
    Schedule schedule, {
    int? responsesCount,
    bool? hasAssignedDriver,
  }) {
    final effectiveResponsesCount = responsesCount ??
        responses.where((r) => r.idSchedule == schedule.id).length;
    final effectiveHasAssignedDriver = hasAssignedDriver ??
        (selectedSchedule?.id == schedule.id && driverContact != null);

    if (effectiveHasAssignedDriver) {
      return 'По контракту уже назначен водитель. Чтобы не сломать привязку маршрутов, чат, QR и историю поездок, редактирование отключено. Для изменений создайте новый контракт или расторгните текущий.';
    }

    if (effectiveResponsesCount > 0) {
      return 'По контракту уже есть отклики водителей. Изменение маршрутов может сделать текущие отклики неактуальными, поэтому редактирование заблокировано. Создайте новый контракт с обновлёнными условиями или дождитесь завершения обработки этого.';
    }

    return 'Контракт уже вошёл в рабочий контур приложения. Чтобы сохранить корректные маршруты, платежи и историю поездок, редактирование этого контракта недоступно. Для изменений используйте новый контракт.';
  }

  Future<void> showScheduleEditLockedInfo(
    Schedule schedule, {
    int? responsesCount,
    bool? hasAssignedDriver,
  }) async {
    await NannyDialogs.showMessageBox(
      context,
      'Редактирование недоступно',
      scheduleEditLockedMessage(
        schedule,
        responsesCount: responsesCount,
        hasAssignedDriver: hasAssignedDriver,
      ),
    );
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
      _ensureSelectedWeekdayForSchedule(schedule);
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

  Future<bool> deleteSchedule(Schedule schedule) async {
    final nearestTripLabel = _nearestTripLabelFor(schedule);
    final initialPrompt = nearestTripLabel == null
        ? "Расторгнуть контракт? Все будущие поездки будут отменены. Если до ближайшей поездки осталось меньше 30 минут, может списаться 50% стоимости."
        : "Расторгнуть контракт? Все будущие поездки будут отменены. Ближайшая поездка: $nearestTripLabel. Если до неё осталось меньше 30 минут, может списаться 50% стоимости.";

    if (!await NannyDialogs.confirmAction(
      context,
      initialPrompt,
      title: "Расторгнуть контракт",
      confirmText: "Расторгнуть",
      cancelText: "Не расторгать",
    )) {
      return false;
    }
    if (!context.mounted) return false;

    final previewResult = await requestDeleteSchedule(schedule);

    if (previewResult.success) {
      return true;
    }

    if (previewResult.requiresDebit) {
      final debitAmount = previewResult.debitAmount ?? 0;
      final debitPrompt = nearestTripLabel == null
          ? "До ближайшей поездки осталось меньше 30 минут. При расторжении спишется штраф ${_formatMoney(debitAmount)} в пользу водителя."
          : "До ближайшей поездки ($nearestTripLabel) осталось меньше 30 минут. При расторжении спишется штраф ${_formatMoney(debitAmount)} в пользу водителя.";

      if (!context.mounted) {
        return false;
      }
      final confirmDebit = await NannyDialogs.confirmAction(
        context,
        debitPrompt,
        title: "Поздняя отмена контракта",
        confirmText: "Подтвердить списание",
        cancelText: "Не отменять",
      );
      if (!confirmDebit || !context.mounted) {
        return false;
      }

      final debitResult = await confirmDeleteScheduleWithDebit(
        schedule,
        debitAmount: debitAmount,
      );
      if (!debitResult) {
        if (context.mounted) {
          NannyDialogs.showMessageBox(
            context,
            "Ошибка",
            "Не удалось расторгнуть контракт со списанием штрафа.",
          );
        }
        return false;
      }
      return true;
    }

    if (context.mounted) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        previewResult.message.isNotEmpty
            ? previewResult.message
            : "Не удалось расторгнуть контракт.",
      );
    }
    return false;
  }

  Future<ScheduleCancellationResult> requestDeleteSchedule(
    Schedule schedule,
  ) async {
    final scheduleId = schedule.id;
    if (scheduleId == null) {
      return const ScheduleCancellationResult(
        success: false,
        message: "Не удалось определить контракт для расторжения.",
      );
    }

    LoadScreen.showLoad(context, true);
    final previewResult =
        await NannyOrdersApi.requestScheduleCancellation(scheduleId);
    if (context.mounted) {
      LoadScreen.showLoad(context, false);
    }

    if (previewResult.success) {
      await reloadPage();
    }

    return previewResult;
  }

  Future<bool> confirmDeleteScheduleWithDebit(
    Schedule schedule, {
    required double debitAmount,
  }) async {
    final scheduleId = schedule.id;
    if (scheduleId == null) {
      return false;
    }

    LoadScreen.showLoad(context, true);
    final debitResult = await NannyOrdersApi.cancelScheduleWithDebit(
      id: scheduleId,
      debitAmount: debitAmount,
    );
    if (context.mounted) {
      LoadScreen.showLoad(context, false);
    }

    if (!debitResult.success) {
      return false;
    }

    await reloadPage();
    return true;
  }

  Future<bool> resumeSchedulePause(
    Schedule schedule, {
    bool requireConfirmation = true,
    bool showErrorDialogs = true,
  }) async {
    final scheduleId = schedule.id;
    if (scheduleId == null) {
      if (showErrorDialogs) {
        NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          "Не удалось определить контракт для возобновления.",
        );
      }
      return false;
    }

    if (requireConfirmation) {
      final confirm = await NannyDialogs.confirmAction(
        context,
        "Возобновить контракт досрочно? После этого поездки снова появятся в расписании.",
        title: "Возобновить контракт",
        confirmText: "Возобновить",
        cancelText: "Пока оставить на паузе",
      );
      if (!confirm || !context.mounted) {
        return false;
      }
    }

    LoadScreen.showLoad(context, true);
    final result = await NannyUsersApi.resumeContract(scheduleId);
    if (context.mounted) {
      LoadScreen.showLoad(context, false);
    }

    if (!result.success) {
      if (showErrorDialogs && context.mounted) {
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      }
      return false;
    }

    await reloadPage();
    return true;
  }

  Future<bool> pauseSchedule({
    required Schedule schedule,
    required String dateFrom,
    required String dateUntil,
    required String reason,
  }) async {
    final scheduleId = schedule.id;
    if (scheduleId == null) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Не удалось определить контракт для приостановки.",
      );
      return false;
    }

    LoadScreen.showLoad(context, true);
    final result = await NannyUsersApi.pauseContract(
      scheduleId: scheduleId,
      dateFrom: dateFrom,
      dateUntil: dateUntil,
      reason: reason,
    );
    if (context.mounted) {
      LoadScreen.showLoad(context, false);
    }

    if (!result.success) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      }
      return false;
    }

    await reloadPage();
    return true;
  }

  String _formatMoney(double amount) {
    final hasFraction = amount != amount.roundToDouble();
    final normalized = hasFraction
        ? amount
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '')
        : amount.round().toString();
    return "$normalized ₽";
  }

  String? _nearestTripLabelFor(Schedule schedule) {
    final nearestRoad = _nearestUpcomingRoad(schedule);
    if (nearestRoad == null) {
      return null;
    }

    final date = _nextOccurrenceFor(nearestRoad.weekDay, nearestRoad.startTime);
    final weekday = nearestRoad.weekDay.shortName;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "$weekday, $day.$month ${nearestRoad.startTime.formatTime()}";
  }

  Road? _nearestUpcomingRoad(Schedule schedule) {
    Road? nearestRoad;
    DateTime? nearestDateTime;

    for (final road in schedule.roads) {
      final occurrence = _nextOccurrenceFor(road.weekDay, road.startTime);
      if (nearestDateTime == null || occurrence.isBefore(nearestDateTime)) {
        nearestDateTime = occurrence;
        nearestRoad = road;
      }
    }

    return nearestRoad;
  }

  void _ensureSelectedWeekdayForSchedule(Schedule schedule) {
    if (schedule.roads.isEmpty) {
      return;
    }

    final currentDay = selectedWeekday.isEmpty ? null : selectedWeekday.first;
    final hasRoutesForCurrentDay = currentDay != null &&
        schedule.roads.any((road) => road.weekDay == currentDay);

    if (hasRoutesForCurrentDay) {
      return;
    }

    final nearestRoad = _nearestUpcomingRoad(schedule);
    if (nearestRoad == null) {
      return;
    }

    if (selectedWeekday.isEmpty) {
      selectedWeekday = [nearestRoad.weekDay];
      return;
    }

    selectedWeekday[0] = nearestRoad.weekDay;
  }

  DateTime _nextOccurrenceFor(NannyWeekday weekday, TimeOfDay startTime) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final targetIndex = weekday.index;
    final daysDifference = (targetIndex - todayIndex) % 7;

    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    ).add(Duration(days: daysDifference));

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }

    return candidate;
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
        "Выберите контракт",
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

  Future<void> openAssignedDriverProfile() async {
    final driver = driverContact;
    if (driver == null) {
      return;
    }
    await navigateToView(
      DriverInfoView(
        id: driver.id,
        onOpenRating: () => navigateToView(
          DriverRatingDetailsView(
            driverId: driver.id,
            driverName: driver.fullName,
            driverPhoto: driver.photo,
          ),
        ),
      ),
    );
  }

  Future<void> callAssignedDriver() async {
    final driver = driverContact;
    final rawPhone = driver?.phone.trim();
    if (rawPhone == null || rawPhone.isEmpty) {
      await NannyDialogs.showMessageBox(
        context,
        "Телефон недоступен",
        "Номер водителя пока не удалось загрузить. Попробуйте позже.",
      );
      return;
    }

    final normalizedPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final launched = await launchUrl(Uri(scheme: 'tel', path: normalizedPhone));
    if (!context.mounted || launched) {
      return;
    }

    await NannyDialogs.showMessageBox(
      context,
      "Не удалось открыть набор номера",
      "Попробуйте еще раз или свяжитесь с водителем через чат.",
    );
  }

  // Открытие профиля водителя по отклику
  void openDriverFromResponse(ScheduleResponsesData response) async {
    await navigateToView(DriverInfoView(
      id: response.idDriver,
      viewingOrder: true,
      scheduleData: response,
      onOpenRating: () => navigateToView(
        DriverRatingDetailsView(driverId: response.idDriver),
      ),
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
      final otherParamsResult = await NannyStaticDataApi.getOtherParams();
      if (otherParamsResult.success && otherParamsResult.response != null) {
        _otherParamsCatalog = otherParamsResult.response!;
      }

      schedules = _hydrateSchedulesWithOtherParams(scheduleResult.response!);

      final childrenResult = await NannyChildrenApi.getChildren();
      if (childrenResult.success && childrenResult.response != null) {
        children = childrenResult.response!;
      }

      // Сохраняем выбор пользователя: если до перезагрузки
      // был выбран конкретный контракт, пытаемся найти его в
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
          schedules.map((s) => s.toCacheJson()).toList(),
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
      if (selectedSchedule != null) {
        _ensureSelectedWeekdayForSchedule(selectedSchedule!);
      }

      // При первом открытии экрана сразу подтягиваем контакт водителя
      // для автоматически выбранного контракта, чтобы статус был корректным.
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
        if (selectedSchedule != null) {
          _ensureSelectedWeekdayForSchedule(selectedSchedule!);
        }

        // То же поведение в оффлайн-режиме: пытаемся загрузить контакт
        // по автоматически выбранному контракту (если есть сеть).
        if (selectedSchedule != null) {
          await loadDriverContact();
        }

        update(() {});
        return true;
      }
    } catch (_) {}

    return false;
  }

  List<Schedule> _hydrateSchedulesWithOtherParams(List<Schedule> rawSchedules) {
    if (_otherParamsCatalog.isEmpty) {
      return rawSchedules;
    }

    return rawSchedules
        .map(
          (schedule) => Schedule(
            id: schedule.id,
            title: schedule.title,
            isActive: schedule.isActive,
            description: schedule.description,
            duration: schedule.duration,
            childrenCount: schedule.childrenCount,
            datetimeCreate: schedule.datetimeCreate,
            weekdays: schedule.weekdays,
            tariff: schedule.tariff,
            otherParametrs: schedule.otherParametrs
                .map(_hydrateOtherParametr)
                .toList(growable: false),
            roads: schedule.roads,
            salary: schedule.salary,
            amountWeek: schedule.amountWeek,
            amountMonth: schedule.amountMonth,
            isPaused: schedule.isPaused,
            pauseFrom: schedule.pauseFrom,
            pauseUntil: schedule.pauseUntil,
            pauseReason: schedule.pauseReason,
            pauseInitiatedBy: schedule.pauseInitiatedBy,
          ),
        )
        .toList(growable: false);
  }

  OtherParametr _hydrateOtherParametr(OtherParametr param) {
    final match = _otherParamsCatalog.cast<OtherParametr?>().firstWhere(
          (candidate) => candidate?.id == param.id,
          orElse: () => null,
        );

    return OtherParametr(
      id: param.id ?? match?.id,
      title: param.title ?? match?.title,
      amount: param.amount ?? match?.amount,
      count: param.count,
    );
  }

  bool _isBalancePause(String? raw) {
    return raw == 'insufficient_balance' ||
        raw == 'low_balance' ||
        raw == 'lack_of_funds';
  }

  bool _isScheduleOperational(
    Schedule schedule, {
    int? responsesCount,
    bool? hasAssignedDriver,
  }) {
    final effectiveResponsesCount = responsesCount ??
        responses.where((r) => r.idSchedule == schedule.id).length;
    final effectiveHasAssignedDriver = hasAssignedDriver ??
        (selectedSchedule?.id == schedule.id && driverContact != null);

    return effectiveHasAssignedDriver ||
        effectiveResponsesCount > 0 ||
        schedule.isActive == true;
  }
}
