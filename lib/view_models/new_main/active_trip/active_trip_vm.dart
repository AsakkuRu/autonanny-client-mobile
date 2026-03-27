import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_components/base_views/views/direct.dart';
import 'package:nanny_components/base_views/views/driver_info.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/views/rating/driver_rating_details_view.dart';
import 'package:nanny_core/api/api_models/sos_activate_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:nanny_core/services/notification_service.dart';
import 'package:nanny_core/nanny_core.dart';

class ActiveTripVM extends ViewModelBase {
  static const int _defaultFreeWaitingSecondsLimit = 10 * 60;
  static const double _defaultPaidWaitingRatePerMinute = 5.8;

  ActiveTripVM({
    required super.context,
    required super.update,
    this.initialToken,
    this.onTripStarted,
  });

  final String? initialToken;

  /// Вызывается при переходе в статус 14/15 (поездка началась). Закрыть QR/PIN диалог.
  final VoidCallback? onTripStarted;

  UnifiedSocket? _socket;
  StreamSubscription? _connectedSub;
  StreamSubscription? _assignedSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _cancelledSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _expiredSub;
  StreamSubscription? _routeSub;
  Timer? _statusPollTimer;
  Timer? _waitingTimer;
  Duration? _statusPollInterval;
  bool _isReconcilingTerminalState = false;
  bool _isReconcilingStatusState = false;

  String? token;
  int? orderId;
  int? scheduleRoadId;
  int? chatId;
  int? driverId;
  int? statusId;
  int? etaMinutes;
  int? pinCode;
  double baseTripPrice = 0;
  bool noDriversFound = false;
  bool isBusy = false;
  bool connectionTimedOut = false;
  String? awaitingSince;
  bool meetingVerified = false;
  int waitingSeconds = 0;
  int freeWaitingSecondsLimit = _defaultFreeWaitingSecondsLimit;
  double paidWaitingRatePerMinute = _defaultPaidWaitingRatePerMinute;
  String statusText = 'Ищем водителя...';
  DriverContact? driverContact;
  Map<String, dynamic>? driverLocation;
  List<Map<String, dynamic>> nearbyDrivers = [];
  List<Map<String, dynamic>> addresses = [];
  List<Map<String, dynamic>> children = [];
  List<String> serviceTitles = [];
  String routeChangeStatus = '';
  int routeChangeResultVersion = 0;
  bool? lastRouteChangeAccepted;
  String? lastRouteChangeDestination;
  Set<Polyline> routePolylines = {};
  ActiveTripTerminalResult? terminalResult;
  int terminalResultVersion = 0;
  bool _terminalResultPublished = false;

  bool get isFinished => statusId == 11;
  bool get isSearching => statusId == 4 || statusId == null;
  bool get isArrived => statusId == 7 || statusId == 6;
  bool get isInProgress => statusId == 14 || statusId == 15;
  bool get isEnRoute => statusId == 13 || statusId == 5;
  bool get isTerminalCancelled => statusId == 2 || statusId == 3;
  bool get isTerminalState =>
      isFinished || isTerminalCancelled || noDriversFound;
  bool get canShowSos => isInProgress;
  bool get hasWaitingTimer => isArrived && awaitingSince?.isNotEmpty == true;
  bool get isWithinFreeWaitingWindow =>
      waitingSeconds < freeWaitingSecondsLimit;
  double get waitingCharge {
    final paidSeconds = waitingSeconds - freeWaitingSecondsLimit;
    if (paidSeconds <= 0) {
      return 0;
    }
    return double.parse(
      ((paidSeconds / 60) * paidWaitingRatePerMinute).toStringAsFixed(2),
    );
  }

  bool get hasPaidWaiting => waitingCharge > 0;
  String get waitingRateLabel =>
      '${_formatMoney(paidWaitingRatePerMinute)} ₽/мин';
  String get waitingChargeLabel => '${_formatMoney(waitingCharge)} ₽';
  String get currentTripTotalLabel =>
      '${_formatMoney(baseTripPrice + waitingCharge)} ₽';
  String get waitingTimerLabel {
    final minutes = (waitingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (waitingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get waitingStatusTitle =>
      isWithinFreeWaitingWindow ? 'Бесплатное ожидание' : 'Платное ожидание';
  String get waitingStatusHint {
    if (isWithinFreeWaitingWindow) {
      final remaining = (freeWaitingSecondsLimit - waitingSeconds).clamp(
        0,
        freeWaitingSecondsLimit,
      );
      final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
      final seconds = (remaining % 60).toString().padLeft(2, '0');
      return 'Первые ${_freeWindowLabel()} бесплатно. Осталось $minutes:$seconds.';
    }
    return 'После ${_freeWindowThresholdLabel()} начисляется $waitingRateLabel. Уже добавлено $waitingChargeLabel.';
  }

  static const Map<int, int> _statusPriority = {
    2: 90,
    3: 100,
    4: 10,
    5: 30,
    6: 40,
    7: 45,
    8: 46,
    9: 47,
    10: 48,
    11: 110,
    12: 49,
    13: 25,
    14: 60,
    15: 70,
  };

  @override
  Future<bool> loadPage() async {
    token = initialToken;
    await _restoreFromCurrentOrder();
    if (token == null || token!.isEmpty) {
      statusText = 'Активная поездка не найдена';
      await ActiveTripSessionStore.clear();
      return true;
    }

    await _connectSocket();
    await _persistSession();
    _startStatusPolling(immediate: true);
    return true;
  }

  Duration? _resolveStatusPollInterval() {
    final currentStatus = statusId;
    if (currentStatus == null ||
        currentStatus == 11 ||
        currentStatus == 2 ||
        currentStatus == 3) {
      return null;
    }

    if (currentStatus == 4) {
      return const Duration(seconds: 3);
    }

    if (currentStatus == 6 ||
        currentStatus == 7 ||
        currentStatus == 14 ||
        currentStatus == 15) {
      return const Duration(seconds: 3);
    }

    return const Duration(seconds: 5);
  }

  void _startStatusPolling({bool immediate = false}) {
    final nextInterval = _resolveStatusPollInterval();
    if (nextInterval == null) {
      _stopStatusPolling();
      return;
    }

    final shouldRestart =
        _statusPollTimer == null || _statusPollInterval != nextInterval;
    if (shouldRestart) {
      _statusPollTimer?.cancel();
      _statusPollInterval = nextInterval;
      _statusPollTimer = Timer.periodic(nextInterval, (_) {
        _pollOrderStatus();
      });
    }

    if (immediate) {
      _pollOrderStatus();
    }
  }

  void _stopStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
    _statusPollInterval = null;
  }

  Future<void> _pollOrderStatus() async {
    if (_resolveStatusPollInterval() == null) {
      _stopStatusPolling();
      return;
    }
    final res = await NannyOrdersApi.getCurrentOrder();
    if (!res.success || res.response == null) return;
    final data = res.response!.data;
    if (data is! Map) return;
    final activeOrders = _extractActiveOrders(data['orders']);
    final activeOrder = _selectActiveOrder(activeOrders);

    if (activeOrder == null) {
      if (token != null || orderId != null) {
        final likelyCompleted = statusId == 14 || statusId == 15;
        final fallbackStatus = likelyCompleted ? 11 : 3;
        statusId = fallbackStatus;
        statusText =
            likelyCompleted ? 'Поездка завершена' : 'Поездка больше не активна';
        token = null;
        await ActiveTripSessionStore.clear();
        _stopStatusPolling();
        _publishTerminalResult(
          fallbackStatus == 11
              ? const ActiveTripTerminalResult(
                  title: 'Поездка завершена',
                  message:
                      'Поездка закрыта на стороне сервера. Вы можете оценить водителя сейчас или позже в истории поездок.',
                  statusId: 11,
                  supportsDriverRating: true,
                )
              : const ActiveTripTerminalResult(
                  title: 'Поездка больше не активна',
                  message:
                      'Активная поездка уже закрыта. Если отмена была выполнена ранее, новое действие не требуется.',
                  statusId: 3,
                ),
        );
        if (context.mounted) update(() {});
      }
      return;
    }

    _applyOrderSnapshot(activeOrder, updateRoute: false);
    _refreshStatusText();
    _startStatusPolling();
    if (context.mounted) {
      update(() {});
    }
  }

  Future<void> _restoreFromCurrentOrder() async {
    final cached = await ActiveTripSessionStore.load();
    if (cached != null) {
      token = token ?? cached.token;
      orderId ??= cached.orderId;
      statusId ??= cached.statusId;
      chatId ??= cached.chatId;
    }

    final res = await NannyOrdersApi.getCurrentOrder();
    if (!res.success || res.response == null) return;
    final data = res.response!.data;
    if (data is! Map) return;
    final activeOrders = _extractActiveOrders(data['orders']);
    if (activeOrders.isEmpty) {
      token = null;
      await ActiveTripSessionStore.clear();
      return;
    }

    final activeOrder = _selectActiveOrder(
      activeOrders,
      allowFallback: token == null || token!.isEmpty,
    );
    if (activeOrder == null) {
      token = null;
      await ActiveTripSessionStore.clear();
      return;
    }

    _applyOrderSnapshot(activeOrder);
    _refreshStatusText();
    await _persistSession();
  }

  Future<void> ensureRoutePolyline() async {
    if (addresses.isEmpty) return;
    final polylines = <Polyline>{};

    for (var i = 0; i < addresses.length; i++) {
      final segment = addresses[i];
      final fromLat = _toDouble(segment['from_lat']);
      final fromLon = _toDouble(segment['from_lon']);
      final toLat = _toDouble(segment['to_lat']);
      final toLon = _toDouble(segment['to_lon']);
      if (fromLat == null ||
          fromLon == null ||
          toLat == null ||
          toLon == null) {
        continue;
      }

      final poly = await RouteManager.calculateRoute(
        origin: LatLng(fromLat, fromLon),
        destination: LatLng(toLat, toLon),
        id: 'active_trip_route_$i',
      );
      if (poly != null) {
        polylines.add(poly);
      }
    }

    if (polylines.isNotEmpty && context.mounted) {
      routePolylines = polylines;
      update(() {});
    }
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatMoney(double value) {
    final normalized = value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return normalized.replaceAll('.', ',');
  }

  String _freeWindowLabel() {
    final minutes = freeWaitingSecondsLimit ~/ 60;
    if (minutes <= 0) {
      return '$freeWaitingSecondsLimit сек';
    }
    return '$minutes мин';
  }

  String _freeWindowThresholdLabel() {
    final minutes = freeWaitingSecondsLimit ~/ 60;
    if (minutes <= 0) {
      return '$freeWaitingSecondsLimit-й секунды';
    }
    return '$minutes-й минуты';
  }

  Future<void> _connectSocket() async {
    try {
      _socket = await UnifiedSocket.connect();
    } catch (_) {
      statusText = 'Ошибка подключения';
      update(() {});
      return;
    }
    connectionTimedOut = false;
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    if (_socket == null) return;

    _connectedSub?.cancel();
    _assignedSub?.cancel();
    _statusSub?.cancel();
    _cancelledSub?.cancel();
    _locationSub?.cancel();
    _expiredSub?.cancel();
    _routeSub?.cancel();

    _connectedSub = _socket!.on('connected').listen((_) {
      connectionTimedOut = false;
      _startStatusPolling(immediate: true);
      if (context.mounted) update(() {});
    });

    _assignedSub = _socket!.on('trip.assigned').listen((msg) {
      connectionTimedOut = false;
      final data = Map<String, dynamic>.from(msg['data'] ?? const {});
      if (!_matchesTrackedTrip(data)) return;
      orderId = _toInt(data['order_id']) ?? orderId;
      driverId = _toInt(data['driver_id']) ?? driverId;
      chatId = _toInt(data['chat_id']) ?? chatId;

      final incomingToken = data['token'];
      if (incomingToken is String && incomingToken.isNotEmpty) {
        token = incomingToken;
      }

      noDriversFound = false;
      _applyIncomingStatus(13);
      _refreshStatusText();
      _persistSession();
      _startStatusPolling();
      if (context.mounted) update(() {});
    });

    _statusSub = _socket!.on('trip.status_changed').listen((msg) {
      connectionTimedOut = false;
      final data = Map<String, dynamic>.from(msg['data'] ?? const {});
      final status = _toInt(data['legacy_status_id']) ??
          _mapTripStatusToUiStatusId(data['status']?.toString());
      if (!_matchesTrackedTrip(data)) {
        if (status != null) {
          _reconcileStatusStateFromServer();
        }
        if (status != null && (status == 11 || status == 2 || status == 3)) {
          _reconcileTerminalStateFromServer(fallbackStatus: status);
        }
        return;
      }
      driverId = _toInt(data['driver_id']) ?? driverId;
      orderId = _toInt(data['order_id']) ?? orderId;
      scheduleRoadId = _toInt(data['schedule_road_id']) ??
          _toInt(data['id_schedule_road']) ??
          scheduleRoadId;
      chatId = _toInt(data['chat_id']) ?? chatId;

      final incomingToken = data['token'];
      if (incomingToken is String && incomingToken.isNotEmpty) {
        token = incomingToken;
      }

      if (status != null) {
        _applyIncomingStatus(status);
        try {
          NotificationService().handleEvent('trip.status_changed', data);
        } catch (e, st) {
          debugPrint(
            '[ActiveTrip] notification handling failed for trip.status_changed: $e\n$st',
          );
        }
        if (status == 11) {
          _publishTerminalResult(
            const ActiveTripTerminalResult(
              title: 'Поездка завершена',
              message:
                  'Маршрут завершен. Вы можете оценить водителя сейчас или позже в истории поездок.',
              statusId: 11,
              supportsDriverRating: true,
            ),
          );
        } else if (status == 2) {
          _publishTerminalResult(
            const ActiveTripTerminalResult(
              title: 'Водитель отменил поездку',
              message:
                  'Поездка остановлена. Можно закрыть экран и при необходимости оформить новую поездку.',
              statusId: 2,
            ),
          );
        } else if (status == 3) {
          _publishTerminalResult(
            const ActiveTripTerminalResult(
              title: 'Поездка отменена',
              message:
                  'Активная поездка уже закрыта. Дополнительных действий не требуется.',
              statusId: 3,
            ),
          );
        }
      }

      if (status == 11) {
        ActiveTripSessionStore.clear();
        _stopStatusPolling();
      } else {
        _persistSession();
      }
      _refreshStatusText();
      _startStatusPolling();
      if (context.mounted) update(() {});
    });

    _cancelledSub = _socket!.on('trip.cancelled').listen((msg) {
      connectionTimedOut = false;
      final data = Map<String, dynamic>.from(msg['data'] ?? const {});
      if (!_matchesTrackedTrip(data)) {
        _reconcileTerminalStateFromServer(fallbackStatus: 2);
        return;
      }
      final cancelledStatus = _toInt(data['legacy_status_id']) ??
          _mapTripStatusToUiStatusId(
            data['status']?.toString(),
          ) ??
          3;
      _applyIncomingStatus(cancelledStatus);
      NotificationService().handleEvent('trip.cancelled', data);
      ActiveTripSessionStore.clear();
      _refreshStatusText();
      _stopStatusPolling();
      _publishTerminalResult(
        cancelledStatus == 2
            ? const ActiveTripTerminalResult(
                title: 'Водитель отменил поездку',
                message:
                    'Поездка остановлена. Вы можете закрыть экран и заказать нового водителя.',
                statusId: 2,
              )
            : const ActiveTripTerminalResult(
                title: 'Поездка отменена',
                message:
                    'Активная поездка закрыта. Водитель уже получил уведомление об отмене.',
                statusId: 3,
              ),
      );
      if (context.mounted) update(() {});
    });

    _locationSub = _socket!.on('driver.position_updated').listen((msg) {
      final data = Map<String, dynamic>.from(msg['data'] ?? const {});
      if (!_matchesTrackedTrip(data)) return;
      if (data['lat'] != null && data['lon'] != null) {
        driverLocation = {'lat': data['lat'], 'lon': data['lon']};
      }
      if (data['eta_seconds'] is num) {
        etaMinutes = ((data['eta_seconds'] as num) / 60).ceil();
      }
      if (context.mounted) update(() {});
    });

    _expiredSub = _socket!.on('order.expired').listen((msg) {
      final data = Map<String, dynamic>.from(msg['data'] ?? const {});
      if (!_matchesTrackedTrip(data)) return;
      noDriversFound = true;
      statusId = 3;
      statusText = 'Водитель не найден';
      ActiveTripSessionStore.clear();
      NotificationService().handleEvent('order.expired', data);
      _publishTerminalResult(
        const ActiveTripTerminalResult(
          title: 'Водитель не найден',
          message:
              'Заказ завершен без назначения водителя. Можно закрыть экран и попробовать снова чуть позже.',
          statusId: 3,
          noDriversFound: true,
        ),
      );
      if (context.mounted) update(() {});
    });

    // Маршрут
    _routeSub = _socket!.on('route.change_result').listen((msg) {
      final data = Map<String, dynamic>.from(msg['data'] ?? const {});
      if (!_matchesTrackedTrip(data)) return;
      final accepted = data['accepted'] == true ||
          data['route_change_status']?.toString() == 'accepted';
      final routeChangeMessage = accepted
          ? 'Водитель принял изменение маршрута'
          : 'Водитель отклонил изменение маршрута';
      routeChangeStatus = routeChangeMessage;
      lastRouteChangeAccepted = accepted;
      lastRouteChangeDestination = _extractRouteChangeDestination(data);
      routeChangeResultVersion++;
      data['message'] = routeChangeMessage;

      if (accepted && data['addresses'] is List) {
        final rawAddrs = (data['addresses'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final newAddresses = <Map<String, dynamic>>[];
        for (var i = 0; i < rawAddrs.length - 1; i++) {
          final a = rawAddrs[i];
          final b = rawAddrs[i + 1];
          newAddresses.add({
            'from_address': a['address'] ?? '',
            'from_lat': a['lat'],
            'from_lon': a['lng'],
            'to_address': b['address'] ?? '',
            'to_lat': b['lat'],
            'to_lon': b['lng'],
          });
        }

        if (newAddresses.isNotEmpty) {
          addresses = newAddresses;
          ensureRoutePolyline();
        }
      }

      NotificationService().handleEvent('route.change_result', data);
      if (context.mounted) update(() {});
    });
  }

  List<Map<String, dynamic>> _extractAddresses(Map data) {
    final raw = data['addresses'];
    if (raw is! List) return addresses;
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  String _extractRouteChangeDestination(Map<String, dynamic> data) {
    final rawAddresses = data['addresses'];
    if (rawAddresses is List && rawAddresses.isNotEmpty) {
      final last = rawAddresses.last;
      if (last is Map) {
        final address =
            (last['address'] ?? last['to_address'] ?? '').toString().trim();
        if (address.isNotEmpty) {
          return address;
        }
      }
    }

    if (addresses.isNotEmpty) {
      final last = addresses.last;
      final address =
          (last['to_address'] ?? last['to'] ?? '').toString().trim();
      if (address.isNotEmpty) {
        return address;
      }
    }

    return 'Маршрут без новой точки';
  }

  List<Map<String, dynamic>> _extractChildren(Map data) {
    final raw = data['children'];
    if (raw is! List) return children;
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  List<String> _extractServiceTitles(Map data) {
    final raw = data['other_params'] ?? data['other_parameters'];
    if (raw is! List) {
      return serviceTitles;
    }

    final titles = <String>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final title = (map['name'] ?? map['title'] ?? '').toString().trim();
      if (title.isEmpty || titles.contains(title)) {
        continue;
      }
      titles.add(title);
    }
    return List.unmodifiable(titles);
  }

  DriverContact? _extractDriverContact(Map data) {
    final raw = data['driver'];
    if (raw is! Map) {
      return driverContact;
    }

    try {
      return DriverContact.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return driverContact;
    }
  }

  String? _extractAwaitingSince(Map data) {
    final raw = data['awaiting_since'];
    if (raw == null) return awaitingSince;
    final normalized = raw.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool _extractMeetingVerified(Map data) {
    final raw = data['meeting_verified'];
    if (raw == null) return meetingVerified;
    return raw == true;
  }

  int _resolveWaitingSeconds(String? rawAwaitingSince) {
    final raw = rawAwaitingSince?.trim();
    if (raw == null || raw.isEmpty) return 0;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 0;
    final diff = DateTime.now().difference(parsed.toLocal()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void _syncWaitingTimer({int? serverWaitingSeconds}) {
    if (!isArrived || awaitingSince?.isEmpty != false) {
      waitingSeconds = 0;
      _waitingTimer?.cancel();
      _waitingTimer = null;
      return;
    }

    waitingSeconds =
        serverWaitingSeconds ?? _resolveWaitingSeconds(awaitingSince);
    if (_waitingTimer != null) {
      return;
    }

    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isArrived || awaitingSince?.isEmpty != false) {
        _waitingTimer?.cancel();
        _waitingTimer = null;
        return;
      }
      waitingSeconds++;
      if (context.mounted) {
        update(() {});
      }
    });
  }

  void _refreshStatusText() {
    switch (statusId) {
      case 13:
      case 5:
        statusText = 'Водитель едет к вам';
        break;
      case 6:
      case 7:
        statusText = 'Водитель прибыл и ожидает';
        break;
      case 14:
        statusText = 'Ребёнок в пути';
        break;
      case 15:
        statusText = 'Почти приехали';
        break;
      case 2:
        statusText = 'Водитель отменил поездку';
        break;
      case 11:
        statusText = 'Поездка завершена';
        break;
      case 3:
        statusText = 'Поездка отменена';
        break;
      case 4:
      default:
        statusText =
            noDriversFound ? 'Водители не найдены' : 'Ищем водителя...';
    }
  }

  void _applyIncomingStatus(int? nextStatus) {
    if (nextStatus == null) return;
    if (statusId == null) {
      statusId = nextStatus;
      noDriversFound = false;
      return;
    }

    final current = _statusPriority[statusId!] ?? statusId!;
    final next = _statusPriority[nextStatus] ?? nextStatus;
    // Разрешаем «откат» 14→6/7: если 14 пришёл по ошибке (до верификации), сервер пришлёт 6/7.
    final allowRollback =
        statusId == 14 && (nextStatus == 6 || nextStatus == 7);
    // Do not roll back from more advanced states (e.g. 13 -> 4).
    if (next >= current ||
        nextStatus == 2 ||
        nextStatus == 3 ||
        nextStatus == 11 ||
        allowRollback) {
      final wasArrived = statusId == 6 || statusId == 7;
      statusId = nextStatus;
      noDriversFound = false;
      if (nextStatus == 14) {
        // Закрыть окно QR/PIN при переходе из «ожидание» в «поездка началась»
        if (wasArrived) onTripStarted?.call();
      }
      _syncWaitingTimer();
      _startStatusPolling();
    }
  }

  Future<OrderCancellationResult?> cancelSearchOrTrip() async {
    if (isBusy) return null;
    isBusy = true;
    update(() {});
    try {
      if (orderId == null) {
        if (context.mounted) {
          await NannyDialogs.showMessageBox(
            context,
            'Ошибка',
            'Не удалось определить активную поездку для отмены.',
          );
        }
        return null;
      }

      final result = await NannyOrdersApi.cancelOrder(orderId: orderId!);
      if (!result.success) {
        if (context.mounted) {
          await NannyDialogs.showMessageBox(
            context,
            'Ошибка',
            result.errorMessage.isNotEmpty
                ? result.errorMessage
                : 'Не удалось отменить поездку. Попробуйте ещё раз.',
          );
        }
        return null;
      }

      statusId = 3;
      statusText = 'Поездка отменена';
      token = null;
      _terminalResultPublished = true;
      await ActiveTripSessionStore.clear();
      return result.response ??
          const OrderCancellationResult(message: 'Поездка отменена');
    } finally {
      isBusy = false;
      update(() {});
    }
  }

  Future<bool> submitRouteChange(List<Map<String, dynamic>> nextRoute) async {
    if (orderId == null || isBusy) return false;
    isBusy = true;
    update(() {});
    try {
      final res = await NannyOrdersApi.updateOrderRoute(
        orderId: orderId!,
        addresses: nextRoute,
      );
      if (!res.success) return false;
      routeChangeStatus = 'Запрос на изменение маршрута отправлен';
      return true;
    } finally {
      isBusy = false;
      update(() {});
    }
  }

  List<Map<String, dynamic>> buildRouteChangePayload(
      AddressData newDestination) {
    final first =
        addresses.isNotEmpty ? addresses.first : const <String, dynamic>{};
    final fromAddress =
        (first['from_address'] ?? first['from'] ?? '').toString();
    final fromLat = (first['from_lat'] as num?)?.toDouble() ?? 0.0;
    final fromLon = (first['from_lon'] as num?)?.toDouble() ?? 0.0;

    return [
      {
        'address': fromAddress,
        'lat': fromLat,
        'lng': fromLon,
      },
      {
        'address': newDestination.address,
        'lat': newDestination.location.latitude,
        'lng': newDestination.location.longitude,
      },
    ];
  }

  Future<Map<String, dynamic>?> fetchMeetingCodeForTrip() async {
    if (orderId == null || isBusy) return null;
    isBusy = true;
    update(() {});
    try {
      final res = await NannyOrdersApi.getMeetingCodeForOrder(orderId!);
      if (!res.success || res.response == null) return null;
      final mc = res.response!;
      if (mc.meetingCode == null || mc.meetingCode!.isEmpty) return null;
      final verificationScope = mc.verificationScope ??
          ((mc.idScheduleRoad ?? scheduleRoadId) != null
              ? 'schedule'
              : 'order');
      return {
        'meeting_code': mc.meetingCode!,
        'order_id': mc.idOrder ?? orderId,
        'schedule_road_id': mc.idScheduleRoad ?? scheduleRoadId,
        'verification_scope': verificationScope,
      };
    } finally {
      isBusy = false;
      update(() {});
    }
  }

  Future<void> confirmSos() async {
    if (isBusy) return;
    isBusy = true;
    update(() {});

    try {
      Position? position;
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (enabled) {
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
          }
        }
      } catch (_) {}

      final request = SOSActivateRequest(
        latitude: position?.latitude,
        longitude: position?.longitude,
        idOrder: orderId,
      );

      final result = await NannyUsersApi.activateSOS(request);

      if (!context.mounted) return;

      if (result.success) {
        await NannyDialogs.showMessageBox(
          context,
          'SOS активирован',
          'Экстренное уведомление отправлено. Администраторы получили ваши координаты.',
        );
      } else {
        await NannyDialogs.showMessageBox(
          context,
          'Ошибка',
          result.errorMessage.isNotEmpty
              ? result.errorMessage
              : 'Не удалось отправить SOS. Проверьте подключение к интернету.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        await NannyDialogs.showMessageBox(
          context,
          'Ошибка',
          'Не удалось отправить SOS. Проверьте подключение к интернету.',
        );
      }
    } finally {
      isBusy = false;
      update(() {});
    }
  }

  Future<void> openAssignedDriverProfile() async {
    if (driverId == null) {
      if (context.mounted) {
        await NannyDialogs.showMessageBox(
          context,
          'Профиль недоступен',
          'Информация о водителе еще загружается. Попробуйте снова через пару секунд.',
        );
      }
      return;
    }

    await navigateToView(
      DriverInfoView(
        id: driverId!,
        onOpenRating: () => navigateToView(
          DriverRatingDetailsView(
            driverId: driverId!,
            driverName: driverContact?.fullName,
            driverPhoto: driverContact?.photo,
          ),
        ),
      ),
    );
  }

  Future<void> openAssignedDriverChat() async {
    if (chatId == null) {
      if (context.mounted) {
        await NannyDialogs.showMessageBox(
          context,
          'Чат недоступен',
          'Чат с водителем пока не создан или еще не синхронизировался.',
        );
      }
      return;
    }

    final driverName = driverContact?.fullName.trim();
    await navigateToView(
      DirectView(
        idChat: chatId!,
        name:
            driverName == null || driverName.isEmpty ? 'Водитель' : driverName,
      ),
    );
  }

  Future<void> callAssignedDriver() async {
    final rawPhone = driverContact?.phone.trim();
    if (rawPhone == null || rawPhone.isEmpty) {
      if (context.mounted) {
        await NannyDialogs.showMessageBox(
          context,
          'Телефон недоступен',
          'Номер водителя пока не удалось загрузить. Попробуйте немного позже.',
        );
      }
      return;
    }

    final normalizedPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final launched = await launchUrl(Uri(scheme: 'tel', path: normalizedPhone));
    if (!context.mounted || launched) {
      return;
    }

    await NannyDialogs.showMessageBox(
      context,
      'Не удалось открыть набор номера',
      'Попробуйте еще раз или свяжитесь с водителем через чат.',
    );
  }

  Future<void> _persistSession() async {
    if (token == null || token!.isEmpty) return;
    await ActiveTripSessionStore.save(
      ActiveTripSessionData(
        token: token!,
        orderId: orderId,
        statusId: statusId,
        chatId: chatId,
      ),
    );
  }

  List<Map<String, dynamic>> _extractActiveOrders(dynamic rawOrders) {
    if (rawOrders is! List) return const [];
    return rawOrders.whereType<Map>().map((raw) {
      return Map<String, dynamic>.from(raw);
    }).where((order) {
      final sid = _toInt(order['id_status']);
      return sid != null && sid != 2 && sid != 3 && sid != 11;
    }).toList(growable: false);
  }

  Map<String, dynamic>? _selectActiveOrder(
    List<Map<String, dynamic>> activeOrders, {
    bool allowFallback = false,
  }) {
    if (activeOrders.isEmpty) return null;

    if (orderId != null) {
      for (final order in activeOrders) {
        if (_toInt(order['id_order']) == orderId) return order;
      }
    }

    final preferredToken = token ?? initialToken;
    if (preferredToken != null && preferredToken.isNotEmpty) {
      for (final order in activeOrders) {
        final orderToken = order['token']?.toString();
        if (orderToken != null &&
            orderToken.isNotEmpty &&
            orderToken == preferredToken) {
          return order;
        }
      }
    }

    return allowFallback ? activeOrders.first : null;
  }

  void _applyOrderSnapshot(
    Map<String, dynamic> activeOrder, {
    bool updateRoute = true,
  }) {
    token = (activeOrder['token'] ?? token ?? '').toString();
    orderId = _toInt(activeOrder['id_order']) ?? orderId;
    scheduleRoadId = _toInt(activeOrder['id_schedule_road']) ?? scheduleRoadId;
    driverId = _toInt(activeOrder['id_driver']) ?? driverId;
    statusId = _toInt(activeOrder['id_status']) ?? statusId;
    chatId = _toInt(activeOrder['id_chat']) ?? chatId;
    baseTripPrice = _toDouble(activeOrder['total_price']) ??
        _toDouble(activeOrder['amount']) ??
        baseTripPrice;
    freeWaitingSecondsLimit =
        _toInt(activeOrder['free_wait_seconds']) ?? freeWaitingSecondsLimit;
    paidWaitingRatePerMinute =
        _toDouble(activeOrder['waiting_rate_per_minute']) ??
            paidWaitingRatePerMinute;
    driverContact = _extractDriverContact(activeOrder);
    addresses = _extractAddresses(activeOrder);
    children = _extractChildren(activeOrder);
    serviceTitles = _extractServiceTitles(activeOrder);
    awaitingSince = _extractAwaitingSince(activeOrder);
    meetingVerified = _extractMeetingVerified(activeOrder);
    _syncWaitingTimer(
      serverWaitingSeconds: _toInt(activeOrder['waiting_seconds']),
    );
    if (updateRoute) {
      ensureRoutePolyline();
    }
  }

  bool _matchesTrackedTrip(Map<String, dynamic> data) {
    final incomingOrderId = _toInt(data['order_id']);
    if (orderId != null && incomingOrderId != null) {
      return orderId == incomingOrderId;
    }

    final incomingScheduleRoadId =
        _toInt(data['schedule_road_id']) ?? _toInt(data['id_schedule_road']);
    if (scheduleRoadId != null && incomingScheduleRoadId != null) {
      return scheduleRoadId == incomingScheduleRoadId;
    }

    final trackedToken = token ?? initialToken;
    final incomingToken = data['token']?.toString();
    if (trackedToken != null &&
        trackedToken.isNotEmpty &&
        incomingToken != null &&
        incomingToken.isNotEmpty) {
      return trackedToken == incomingToken;
    }

    if (orderId != null || (trackedToken != null && trackedToken.isNotEmpty)) {
      return false;
    }

    return true;
  }

  Future<void> _reconcileTerminalStateFromServer({
    required int fallbackStatus,
  }) async {
    if (_isReconcilingTerminalState) return;
    if (orderId == null &&
        scheduleRoadId == null &&
        (token == null || token!.isEmpty) &&
        (initialToken == null || initialToken!.isEmpty)) {
      return;
    }

    _isReconcilingTerminalState = true;
    try {
      final res = await NannyOrdersApi.getCurrentOrder();
      if (!res.success || res.response == null) return;
      final data = res.response!.data;
      if (data is! Map) return;

      final activeOrders = _extractActiveOrders(data['orders']);
      final activeOrder = _selectActiveOrder(activeOrders);
      if (activeOrder != null) {
        _applyOrderSnapshot(activeOrder, updateRoute: false);
        _refreshStatusText();
        _startStatusPolling();
        if (context.mounted) update(() {});
        return;
      }

      statusId = fallbackStatus;
      switch (fallbackStatus) {
        case 11:
          statusText = 'Поездка завершена';
          break;
        case 2:
          statusText = 'Водитель отменил поездку';
          break;
        case 3:
          statusText = 'Поездка отменена';
          break;
        default:
          _refreshStatusText();
      }
      token = null;
      await ActiveTripSessionStore.clear();
      _stopStatusPolling();
      _publishTerminalResult(
        switch (fallbackStatus) {
          11 => const ActiveTripTerminalResult(
              title: 'Поездка завершена',
              message:
                  'Поездка уже завершилась. Вы можете оценить водителя сейчас или позже в истории поездок.',
              statusId: 11,
              supportsDriverRating: true,
            ),
          2 => const ActiveTripTerminalResult(
              title: 'Водитель отменил поездку',
              message:
                  'Поездка закрыта. Можно вернуться на главный экран и оформить новую поездку.',
              statusId: 2,
            ),
          _ => ActiveTripTerminalResult(
              title: noDriversFound ? 'Водитель не найден' : 'Поездка отменена',
              message: noDriversFound
                  ? 'Поиск водителя завершен без назначения. Попробуйте создать заказ повторно позже.'
                  : 'Активная поездка уже была отменена и больше недоступна.',
              statusId: fallbackStatus,
              noDriversFound: noDriversFound,
            ),
        },
      );
      if (context.mounted) update(() {});
    } catch (e, st) {
      debugPrint(
        '[ActiveTrip] terminal state reconciliation failed: $e\n$st',
      );
    } finally {
      _isReconcilingTerminalState = false;
    }
  }

  void _publishTerminalResult(ActiveTripTerminalResult result) {
    if (_terminalResultPublished) {
      return;
    }
    _terminalResultPublished = true;
    terminalResult = result;
    terminalResultVersion += 1;
  }

  Future<void> _reconcileStatusStateFromServer() async {
    if (_isReconcilingStatusState) return;
    if (orderId == null &&
        scheduleRoadId == null &&
        (token == null || token!.isEmpty) &&
        (initialToken == null || initialToken!.isEmpty)) {
      return;
    }

    _isReconcilingStatusState = true;
    try {
      await _pollOrderStatus();
    } finally {
      _isReconcilingStatusState = false;
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int? _mapTripStatusToUiStatusId(String? status) {
    switch (status) {
      case 'assigned':
        return 13;
      case 'driver_departed':
        return 5;
      case 'driver_arrived':
        return 6;
      case 'child_onboard':
        return 14;
      case 'arrived_destination':
        return 15;
      case 'completed':
        return 11;
      case 'cancelled_by_driver':
        return 2;
      case 'cancelled_by_client':
        return 3;
      case 'searching':
        return 4;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _stopStatusPolling();
    _connectedSub?.cancel();
    _assignedSub?.cancel();
    _statusSub?.cancel();
    _cancelledSub?.cancel();
    _locationSub?.cancel();
    _expiredSub?.cancel();
    _routeSub?.cancel();
    _waitingTimer?.cancel();
    // Не dispose сокет — он общий синглтон
    _socket = null;
  }
}

class ActiveTripTerminalResult {
  const ActiveTripTerminalResult({
    required this.title,
    required this.message,
    required this.statusId,
    this.supportsDriverRating = false,
    this.noDriversFound = false,
  });

  final String title;
  final String message;
  final int statusId;
  final bool supportsDriverRating;
  final bool noDriversFound;
}
