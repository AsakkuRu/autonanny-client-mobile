import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:nanny_client/routing/client_entity_router.dart';
import 'package:nanny_core/nanny_core.dart';

/// TASK-C1: Сервис уведомлений об отклонении водителя от маршрута
class RouteDeviationNotifications {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _notificationId = 200;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    _initialized = true;
    Logger().i('Route deviation notifications initialized');
  }

  static Future<void> showDeviationNotification({
    required double deviationMeters,
    int? orderId,
    Map<String, dynamic>? payload,
  }) async {
    if (!_initialized) await initialize();

    final meters = deviationMeters.toStringAsFixed(0);
    const androidDetails = AndroidNotificationDetails(
      'route_deviation_channel',
      'Отклонения от маршрута',
      channelDescription: 'Уведомления об отклонении водителя от маршрута',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      _notificationId,
      '⚠️ Отклонение от маршрута',
      'Водитель отклонился от запланированного маршрута на $meters м',
      details,
      payload: jsonEncode({
        'target': 'trip',
        'type': 'route_deviation',
        if (orderId != null) 'order_id': orderId,
        'deviation_meters': deviationMeters,
        ...?payload,
      }),
    );

    Logger().w('Route deviation notification shown: ${meters}m deviation');
  }

  static Future<void> handleFirebaseMessage(RemoteMessage message) async {
    Logger().i('Handling route deviation message: ${message.data}');

    if (message.data['type'] != 'route_deviation') return;

    final deviationMeters =
        double.tryParse(message.data['deviation_meters']?.toString() ?? '0') ??
            0;
    final orderId = int.tryParse(message.data['order_id']?.toString() ?? '');

    await showDeviationNotification(
      deviationMeters: deviationMeters,
      orderId: orderId,
      payload: Map<String, dynamic>.from(message.data),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return;
      }

      unawaited(
        _openTripFromPayload(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        ),
      );
    } catch (error, stackTrace) {
      Logger().e(
        'Failed to handle route deviation notification tap: $error\n$stackTrace',
      );
    }
  }

  static Future<void> _openTripFromPayload(Map<String, dynamic> payload) async {
    final context = NannyGlobals.navKey.currentContext;
    if (context == null) {
      return;
    }

    await ClientEntityRouter.openEntity(
      context,
      payload: payload,
      target: payload['target']?.toString() ?? 'trip',
      type: payload['type']?.toString() ?? 'route_deviation',
    );
  }
}
