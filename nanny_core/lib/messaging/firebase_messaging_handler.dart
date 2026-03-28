import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:nanny_client/routing/client_entity_router.dart';
import 'package:nanny_components/nanny_components.dart';
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

      // FE-MVP-019: Обработка уведомлений о статусе поездки
      if (msg.data['type'] == 'trip_status') {
        TripStatusNotifications.handleFirebaseMessage(msg);
      }

      // TASK-C1: Обработка уведомлений об отклонении от маршрута
      if (msg.data['type'] == 'route_deviation') {
        RouteDeviationNotifications.handleFirebaseMessage(msg);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // if(msg.notification == null) return;
      if (msg.data["action"] == null) {
        _handleTypeFallback(msg);
        return;
      }
      var action = NotificationAction.values
          .firstWhere((e) => e.name == msg.data["action"]);

      // TODO: Restore notification action handling if needed
      // NannyGlobals.notificationAction.value = action;
      // NannyGlobals.notificationActionData.value = msg.data;

      _handleAction(action, msg);
    });

    Logger().i("Inited firebase messages handler");
  }

  static void checkInitialMessage() async {
    var msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg == null) return;

    if (msg.data["action"] == null) {
      _handleTypeFallback(msg);
      return;
    }
    var action = NotificationAction.values
        .firstWhere((e) => e.name == msg.data["action"]);

    _handleAction(action, msg);
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
        final chatId = ClientEntityRouter.readInt(
          data['chat_id'] ?? data['id_chat'] ?? data['id'],
        );
        if (chatId == null) {
          return;
        }

        if (NannyGlobals.currentContext.widget.runtimeType == DirectView) {
          Navigator.pop(NannyGlobals.currentContext);
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectView(
              idChat: chatId,
              name: data['chat_name']?.toString(),
            ),
          ),
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

  static void _handleTypeFallback(RemoteMessage msg) {
    if (_handleTargetFallback(msg)) {
      return;
    }

    final type = msg.data['type']?.toString();
    final context = NannyGlobals.navKey.currentContext;
    if (type == null || context == null) {
      return;
    }

    switch (type) {
      case 'weekly_payment_success':
        ClientEntityRouter.openEntity(
          context,
          payload: Map<String, dynamic>.from(msg.data),
          type: type,
        );
        return;
      case 'weekly_payment_failed':
        ClientEntityRouter.openEntity(
          context,
          payload: Map<String, dynamic>.from(msg.data),
          type: type,
        );
        return;
      case 'contract_resumed':
        ClientEntityRouter.openEntity(
          context,
          payload: Map<String, dynamic>.from(msg.data),
          type: type,
        );
        return;
      default:
        return;
    }
  }

  static void _handleAction(NotificationAction action, RemoteMessage msg) {
    switch (action) {
      case NotificationAction.message:
        if (NannyGlobals.currentContext.widget.runtimeType == DirectView) {
          Navigator.pop(NannyGlobals.currentContext);
        }

        Navigator.push(
            NannyGlobals.currentContext,
            MaterialPageRoute(
                builder: (context) =>
                    DirectView(idChat: int.parse(msg.data["id"]))));
        break;

      case NotificationAction.order:
      case NotificationAction.orderFeedback:
      case NotificationAction.orderRequest:
      case NotificationAction.orderRequestSuccess:
      case NotificationAction.orderRequestDenied:
      case NotificationAction.fine:
      case NotificationAction.replyOrder:
        _handleTypeFallback(msg);
        break;
    }
  }

  static bool _handleTargetFallback(RemoteMessage msg) {
    final context = NannyGlobals.navKey.currentContext;
    if (context == null) {
      return false;
    }
    ClientEntityRouter.openEntity(
      context,
      payload: Map<String, dynamic>.from(msg.data),
      target: msg.data['target']?.toString(),
      type: msg.data['type']?.toString(),
    );
    return true;
  }
}
