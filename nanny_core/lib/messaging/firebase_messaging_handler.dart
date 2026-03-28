// ignore: depend_on_referenced_packages
import 'package:nanny_client/routing/client_entity_router.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/messaging/route_deviation_notifications.dart';

class FirebaseMessagingHandler {
  static void init() {
    PushTokenSync.init();

    // FE-MVP-019: Инициализация локальных уведомлений
    TripStatusNotifications.initialize();
    // TASK-C1: Инициализация уведомлений об отклонениях от маршрута
    RouteDeviationNotifications.initialize();

    FirebaseMessaging.onMessage.listen((msg) {
      Logger().w(
          "Got message from firebase:\n${msg.data}\nNotification data:${msg.notification?.title}\n${msg.notification?.body}");

      final type = msg.data['type']?.toString();

      // FE-MVP-019: Обработка уведомлений о статусе поездки
      if (type == 'trip_status' || type == 'trip_status_update') {
        TripStatusNotifications.handleFirebaseMessage(msg);
      }

      // TASK-C1: Обработка уведомлений об отклонении от маршрута
      if (type == 'route_deviation') {
        RouteDeviationNotifications.handleFirebaseMessage(msg);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      await _handleIncomingMessage(msg);
    });

    Logger().i("Inited firebase messages handler");
  }

  static void checkInitialMessage() async {
    var msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg == null) return;

    await _handleIncomingMessage(msg);
  }

  static Future<void> handleLocalNotificationTap(
    Map<String, dynamic> payload,
  ) async {
    final event = payload['event']?.toString();
    final rawData = payload['data'];
    final data = rawData is Map
        ? rawData.map((key, value) => MapEntry(key.toString(), value))
        : payload;

    final context = NannyGlobals.navKey.currentContext;
    if (event == null || context == null) {
      return;
    }

    switch (event) {
      case 'chat.message_created':
        await ClientEntityRouter.openEntity(
          context,
          payload: Map<String, dynamic>.from(data),
          target: 'chat',
          type: event,
        );
        return;
      case 'trip.status_changed':
      case 'trip.cancelled':
      case 'order.expired':
      case 'route.change_result':
      case 'route.change_requested':
        await ClientEntityRouter.openEntity(
          context,
          payload: data,
          target: 'trip',
          type: event,
        );
        return;
      default:
        return;
    }
  }

  static Future<void> _handleIncomingMessage(RemoteMessage msg) async {
    final actionName = msg.data["action"]?.toString();
    if (actionName == null || actionName.isEmpty) {
      await _handleTypeFallback(msg);
      return;
    }

    final action =
        NotificationAction.values.cast<NotificationAction?>().firstWhere(
              (e) => e?.name == actionName,
              orElse: () => null,
            );
    if (action == null) {
      Logger().w('Unknown firebase notification action: $actionName');
      await _handleTypeFallback(msg);
      return;
    }

    await _handleAction(action, msg);
  }

  static Future<void> _handleTypeFallback(RemoteMessage msg) async {
    if (await _handleTargetFallback(msg)) {
      return;
    }

    final type = msg.data['type']?.toString();
    final context = NannyGlobals.navKey.currentContext;
    if (type == null || context == null || !context.mounted) {
      return;
    }

    switch (type) {
      case 'weekly_payment_success':
      case 'weekly_payment_failed':
      case 'contract_resumed':
      case 'contract_suspended':
      case 'trip_status':
      case 'trip_status_update':
      case 'active_trip':
      case 'trip.assigned':
      case 'trip.cancelled':
      case 'order.expired':
      case 'route.change_requested':
      case 'route.change_result':
        await ClientEntityRouter.openEntity(
          context,
          payload: Map<String, dynamic>.from(msg.data),
          type: type,
        );
        return;
      default:
        return;
    }
  }

  static Future<void> _handleAction(
    NotificationAction action,
    RemoteMessage msg,
  ) async {
    switch (action) {
      case NotificationAction.message:
        await ClientEntityRouter.openEntity(
          NannyGlobals.currentContext,
          payload: Map<String, dynamic>.from(msg.data),
          target: 'chat',
          type: msg.data['type']?.toString() ?? 'message',
        );
        break;

      case NotificationAction.order:
      case NotificationAction.orderFeedback:
      case NotificationAction.orderRequest:
      case NotificationAction.orderRequestSuccess:
      case NotificationAction.orderRequestDenied:
      case NotificationAction.fine:
      case NotificationAction.replyOrder:
        await _handleTypeFallback(msg);
        break;
    }
  }

  static Future<bool> _handleTargetFallback(RemoteMessage msg) async {
    final context = NannyGlobals.navKey.currentContext;
    if (context == null) {
      return false;
    }
    return ClientEntityRouter.openEntity(
      context,
      payload: Map<String, dynamic>.from(msg.data),
      target: msg.data['target']?.toString(),
      type: msg.data['type']?.toString(),
    );
  }
}
