import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_core/api/api_models/sos_activate_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/services/notification_service.dart';
import 'package:nanny_core/nanny_core.dart';

class ActiveTripVM extends ViewModelBase {
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
  bool noDriversFound = false;
  bool isBusy = false;
  bool connectionTimedOut = false;
  String statusText = 'Ищем водителя...';
  Map<String, dynamic>? driverLocation;
  List<Map<String, dynamic>> nearbyDrivers = [];
  List<Map<String, dynamic>> addresses = [];
  List<Map<String, dynamic>> children = [];
  String routeChangeStatus = '';
  Set<Polyline> routePolylines = {};

  bool get isFinished => statusId == 11;
  bool get isSearching => statusId == 4 || statusId == null;
  bool get isArrived => statusId == 7 || statusId == 6;
  bool get isInProgress => statusId == 14 || statusId == 15;
  bool get isEnRoute => statusId == 13 || statusId == 5;

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
        statusId = likelyCompleted ? 11 : 3;
        statusText =
            likelyCompleted ? 'Поездка завершена' : 'Поездка больше не активна';
        token = null;
        await ActiveTripSessionStore.clear();
        _stopStatusPolling();
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
      final status = _mapTripStatusToUiStatusId(data['status']?.toString());
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
      final cancelledStatus = _mapTripStatusToUiStatusId(
            data['status']?.toString(),
          ) ??
          3;
      _applyIncomingStatus(cancelledStatus);
      NotificationService().handleEvent('trip.cancelled', data);
      ActiveTripSessionStore.clear();
      _refreshStatusText();
      _stopStatusPolling();
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

  List<Map<String, dynamic>> _extractChildren(Map data) {
    final raw = data['children'];
    if (raw is! List) return children;
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
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
      _startStatusPolling();
    }
  }

  Future<bool> cancelSearchOrTrip() async {
    if (isBusy) return false;
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
        return false;
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
        return false;
      }

      statusId = 3;
      statusText = 'Поездка отменена';
      token = null;
      await ActiveTripSessionStore.clear();
      return true;
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
    statusId = _toInt(activeOrder['id_status']) ?? statusId;
    chatId = _toInt(activeOrder['id_chat']) ?? chatId;
    addresses = _extractAddresses(activeOrder);
    children = _extractChildren(activeOrder);
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
      if (context.mounted) update(() {});
    } catch (e, st) {
      debugPrint(
        '[ActiveTrip] terminal state reconciliation failed: $e\n$st',
      );
    } finally {
      _isReconcilingTerminalState = false;
    }
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

  void dispose() {
    _stopStatusPolling();
    _connectedSub?.cancel();
    _assignedSub?.cancel();
    _statusSub?.cancel();
    _cancelledSub?.cancel();
    _locationSub?.cancel();
    _expiredSub?.cancel();
    _routeSub?.cancel();
    // Не dispose сокет — он общий синглтон
    _socket = null;
  }
}
