import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/sos_activate_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/api/nanny_users_api.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:geolocator/geolocator.dart';
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
  StreamSubscription? _statusSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _driversSub;
  StreamSubscription? _expiredSub;
  StreamSubscription? _routeSub;
  Timer? _statusPollTimer;
  bool _receivedSocketEvent = false;

  String? token;
  int? orderId;
  int? chatId;
  int? driverId;
  int? statusId;
  int? etaMinutes;
  int? pinCode;
  bool noDriversFound = false;
  bool isBusy = false;
  bool connectionTimedOut = false;
  String statusText = 'Подключаем поездку...';
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
    if (isArrived) _startStatusPolling();
    return true;
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollOrderStatus();
    });
  }

  void _stopStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  Future<void> _pollOrderStatus() async {
    if (statusId == 14 || statusId == 15) {
      _stopStatusPolling();
      return;
    }
    final res = await NannyOrdersApi.getCurrentOrder();
    if (!res.success || res.response == null) return;
    final data = res.response!.data;
    if (data is! Map) return;
    final orders = data['orders'];
    if (orders is! List || orders.isEmpty) return;
    for (final raw in orders) {
      if (raw is! Map) continue;
      final sid = _toInt(raw['id_status']);
      if (sid == null || sid == 3 || sid == 11) continue;
      if (sid == 14 || sid == 15) {
        _applyIncomingStatus(sid);
        _refreshStatusText();
        _stopStatusPolling();
        if (context.mounted) update(() {});
      }
      break;
    }
  }

  Future<void> _restoreFromCurrentOrder() async {
    final cached = await ActiveTripSessionStore.load();
    if (cached != null) {
      token = cached.token;
      orderId = cached.orderId;
      statusId = cached.statusId;
      chatId = cached.chatId;
    }

    final res = await NannyOrdersApi.getCurrentOrder();
    if (!res.success || res.response == null) return;
    final data = res.response!.data;
    if (data is! Map) return;
    final orders = data['orders'];
    if (orders is! List || orders.isEmpty) {
      token = null;
      await ActiveTripSessionStore.clear();
      return;
    }

    Map? activeOrder;
    for (final raw in orders) {
      if (raw is! Map) continue;
      final sid = _toInt(raw['id_status']);
      if (sid == null || sid == 3 || sid == 11) continue;
      activeOrder = raw;
      break;
    }

    if (activeOrder == null) {
      token = null;
      await ActiveTripSessionStore.clear();
      return;
    }

    token = (activeOrder['token'] ?? token ?? '').toString();
    orderId = _toInt(activeOrder['id_order']) ?? orderId;
    statusId = _toInt(activeOrder['id_status']) ?? statusId;
    chatId = _toInt(activeOrder['id_chat']) ?? chatId;
    addresses = _extractAddresses(activeOrder);
    children = _extractChildren(activeOrder);
    _refreshStatusText();
    ensureRoutePolyline();
  }

  Future<void> ensureRoutePolyline() async {
    if (addresses.isEmpty) return;
    final first = addresses.first;
    final fromLat = _toDouble(first['from_lat']);
    final fromLon = _toDouble(first['from_lon']);
    final toLat = _toDouble(first['to_lat']);
    final toLon = _toDouble(first['to_lon']);
    if (fromLat == null || fromLon == null || toLat == null || toLon == null) return;
    final poly = await RouteManager.calculateRoute(
      origin: LatLng(fromLat, fromLon),
      destination: LatLng(toLat, toLon),
      id: 'active_trip_route',
    );
    if (poly != null && context.mounted) {
      routePolylines = {poly};
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
    _receivedSocketEvent = false;
    connectionTimedOut = false;
    _subscribeToEvents();

    Future.delayed(const Duration(seconds: 5), () async {
      if (_receivedSocketEvent || isFinished || token == null) return;
      // Источник правды по актуальности поездки — сервер.
      // Не очищаем локальную сессию по клиентскому таймеру:
      // UnifiedSocket продолжит переподключения, а сервер сам отменит
      // заказ при необходимости (например, по timeout поиска водителя).
      connectionTimedOut = true;
      statusText = 'Проблемы соединения. Продолжаем переподключение...';
      update(() {});
    });
  }

  void _subscribeToEvents() {
    if (_socket == null) return;

    // Статус заказа
    _statusSub = _socket!.on('order.status_changed').listen((msg) {
      _receivedSocketEvent = true;
      connectionTimedOut = false;
      final data = msg['data'] ?? {};
      final status = _toInt(data['status']);
      driverId = _toInt(data['driver_id']) ?? driverId;
      orderId = _toInt(data['order_id']) ?? orderId;

      if (status != null) {
        _applyIncomingStatus(status);
        NotificationService().handleEvent('order.status_changed', data);
      }

      if (status == 11 || status == 3 || status == 2) {
        ActiveTripSessionStore.clear();
      } else {
        _persistSession();
      }
      _refreshStatusText();
      if (context.mounted) update(() {});
    });

    // Позиция водителя
    _locationSub = _socket!.on('order.driver_location').listen((msg) {
      _receivedSocketEvent = true;
      final data = msg['data'] ?? {};
      if (data['lat'] != null && data['lon'] != null) {
        driverLocation = {'lat': data['lat'], 'lon': data['lon']};
      }
      if (data['eta_seconds'] is num) {
        etaMinutes = ((data['eta_seconds'] as num) / 60).ceil();
      }
      if (context.mounted) update(() {});
    });

    // Водители рядом (при поиске)
    _driversSub = _socket!.on('order.drivers_nearby').listen((msg) {
      _receivedSocketEvent = true;
      final drivers = msg['data']?['drivers'];
      if (drivers is List) {
        nearbyDrivers = drivers
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (context.mounted) update(() {});
      }
    });

    // Тайм-аут поиска
    _expiredSub = _socket!.on('order.expired').listen((msg) {
      _receivedSocketEvent = true;
      noDriversFound = true;
      statusId = 3;
      statusText = 'Водитель не найден';
      ActiveTripSessionStore.clear();
      NotificationService().handleEvent('order.expired', msg['data'] ?? {});
      if (context.mounted) update(() {});
    });

    // Маршрут
    _routeSub = _socket!.on('route.change_result').listen((msg) {
      final data = msg['data'] ?? {};
      final accepted = data['accepted'] == true;
      routeChangeStatus = accepted ? 'accepted' : 'rejected';
      NotificationService().handleEvent('route.change_result', data);
      if (context.mounted) update(() {});
    });
  }

  /// @deprecated Не используется — логика перенесена в _subscribeToEvents().
  /// Оставлен временно для обратной совместимости. Удалить после проверки.
  void _handleMessage(dynamic rawEvent) {
    try {
      _receivedSocketEvent = true;
      connectionTimedOut = false;
      final decoded = rawEvent is String ? jsonDecode(rawEvent) : rawEvent;
      if (decoded is! Map) return;
      final Map<String, dynamic> data =
          decoded.map((k, v) => MapEntry(k.toString(), v));

      orderId = _toInt(data['order_id']) ?? _toInt(data['id_order']) ?? orderId;
      driverId = _toInt(data['id_driver']) ?? driverId;
      chatId = _toInt(data['id_chat']) ?? chatId;

      if (data.containsKey('id_status')) {
        _applyIncomingStatus(_toInt(data['id_status']));
      } else if (data.containsKey('status')) {
        _applyIncomingStatus(_toInt(data['status']));
      }

      if (data.containsKey('lat') && data.containsKey('lon')) {
        driverLocation = {
          'lat': data['lat'],
          'lon': data['lon'],
        };
      }
      if (data['duration'] is num) {
        etaMinutes = ((data['duration'] as num) / 60).ceil();
      }

      if (data['order'] is Map) {
        final order = Map<String, dynamic>.from(data['order'] as Map);
        orderId = _toInt(order['id_order']) ?? _toInt(order['order_id']) ?? orderId;
        driverId = _toInt(order['id_driver']) ?? driverId;
        chatId = _toInt(order['id_chat']) ?? chatId;
        _applyIncomingStatus(_toInt(order['id_status']) ?? _toInt(order['status']));
        addresses = _extractAddresses(order);
        children = _extractChildren(order);
        ensureRoutePolyline();
      }

      if (data['type'] == 'no_drivers_found') {
        noDriversFound = true;
      }

      if (data['type'] == 'drivers_update' && data['drivers'] is List) {
        nearbyDrivers = (data['drivers'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
      }

      // Обработка одиночного водителя (подключился после клиента или обновил позицию)
      if (data['type'] == 'driver_update' && data['data'] is Map) {
        final driver = Map<String, dynamic>.from(data['data'] as Map);
        final id = driver['id_driver'] ?? driver['id'];
        final idx = nearbyDrivers.indexWhere((d) =>
            (d['id_driver'] ?? d['id']) == id);
        if (idx >= 0) {
          nearbyDrivers = List<Map<String, dynamic>>.from(nearbyDrivers)
            ..[idx] = driver;
        } else {
          nearbyDrivers = [...nearbyDrivers, driver];
        }
      }

      if (data['route_change_status'] is String) {
        routeChangeStatus = data['route_change_status'].toString();
      }

      if (data['event_type'] == 'route_changed' && data['addresses'] is List) {
        final rawAddrs = (data['addresses'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        // Backend sends raw waypoints [{address, lat, lng}].
        // ensureRoutePolyline() expects segment format [{from_lat, from_lon, to_lat, to_lon}].
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
        if (newAddresses.isNotEmpty) addresses = newAddresses;
        routeChangeStatus = 'accepted';
        ensureRoutePolyline();
      }
      if (data['event_type'] == 'route_change_rejected') {
        routeChangeStatus = 'rejected';
      }

      if (statusId == 11 || statusId == 3 || statusId == 2) {
        ActiveTripSessionStore.clear();
      } else {
        _persistSession();
      }
      _refreshStatusText();
      update(() {});
    } catch (e) {
      Logger().e('ActiveTripVM parse error: $e');
    }
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
        statusText = noDriversFound ? 'Водители не найдены' : 'Ищем водителя...';
    }
  }

  void _applyIncomingStatus(int? nextStatus) {
    if (nextStatus == null) return;
    if (statusId == null) {
      statusId = nextStatus;
      return;
    }

    final current = _statusPriority[statusId!] ?? statusId!;
    final next = _statusPriority[nextStatus] ?? nextStatus;
    // Разрешаем «откат» 14→6/7: если 14 пришёл по ошибке (до верификации), сервер пришлёт 6/7.
    final allowRollback = statusId == 14 && (nextStatus == 6 || nextStatus == 7);
    // Do not roll back from more advanced states (e.g. 13 -> 4).
    if (next >= current ||
        nextStatus == 2 ||
        nextStatus == 3 ||
        nextStatus == 11 ||
        allowRollback) {
      final wasArrived = statusId == 6 || statusId == 7;
      statusId = nextStatus;
      if (nextStatus == 14 || nextStatus == 15) {
        _stopStatusPolling();
        // Закрыть окно QR/PIN при переходе из «ожидание» в «поездка началась»
        if (wasArrived) onTripStarted?.call();
      }
    }
  }

  Future<void> cancelSearchOrTrip() async {
    if (isBusy) return;
    isBusy = true;
    update(() {});
    try {
      if (isSearching && _socket != null && orderId != null) {
        _socket!.send('order.cancel', {'order_id': orderId});
      } else if (orderId != null) {
        await NannyOrdersApi.cancelOrder(orderId: orderId!);
      }
      statusId = 3;
      statusText = 'Поездка отменена';
      await ActiveTripSessionStore.clear();
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
      routeChangeStatus = 'requested';
      return true;
    } finally {
      isBusy = false;
      update(() {});
    }
  }

  List<Map<String, dynamic>> buildRouteChangePayload(AddressData newDestination) {
    final first = addresses.isNotEmpty ? addresses.first : const <String, dynamic>{};
    final fromAddress = (first['from_address'] ?? first['from'] ?? '').toString();
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

  Future<Map<String, dynamic>?> fetchMeetingCodeForOrder() async {
    if (orderId == null || isBusy) return null;
    isBusy = true;
    update(() {});
    try {
      final res = await NannyOrdersApi.getMeetingCodeForOrder(orderId!);
      if (!res.success || res.response == null) return null;
      final mc = res.response!;
      if (mc.meetingCode == null || mc.meetingCode!.isEmpty) return null;
      return {'meeting_code': mc.meetingCode!, 'order_id': orderId};
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

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void dispose() {
    _stopStatusPolling();
    _statusSub?.cancel();
    _locationSub?.cancel();
    _driversSub?.cancel();
    _expiredSub?.cancel();
    _routeSub?.cancel();
    // Не dispose сокет — он общий синглтон
    _socket = null;
  }
}
