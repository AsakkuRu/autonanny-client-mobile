import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// TASK-C1: Сервис уведомлений об отклонении водителя от маршрута
class RouteDeviationNotifications {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int _notificationId = 200;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
    _initialized = true;
    Logger().i('Route deviation notifications initialized');
  }

  static Future<void> showDeviationNotification({
    required double deviationMeters,
    int? orderId,
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
      payload: orderId != null ? 'route_deviation_$orderId' : 'route_deviation',
    );

    Logger().w('Route deviation notification shown: ${meters}m deviation');
  }

  static Future<void> handleFirebaseMessage(RemoteMessage message) async {
    Logger().i('Handling route deviation message: ${message.data}');

    if (message.data['type'] != 'route_deviation') return;

    final deviationMeters = double.tryParse(
            message.data['deviation_meters']?.toString() ?? '0') ??
        0;
    final orderId = int.tryParse(message.data['order_id']?.toString() ?? '');

    await showDeviationNotification(
      deviationMeters: deviationMeters,
      orderId: orderId,
    );
  }
}
