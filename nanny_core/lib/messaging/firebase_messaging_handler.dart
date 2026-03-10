import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/messaging/route_deviation_notifications.dart';
import 'package:nanny_core/messaging/trip_status_notifications.dart';

class FirebaseMessagingHandler {
  static void init() {
    // FE-MVP-019: Инициализация локальных уведомлений
    TripStatusNotifications.initialize();
    // TASK-C1: Инициализация уведомлений об отклонениях от маршрута
    RouteDeviationNotifications.initialize();

    FirebaseMessaging.onMessage.listen((msg) {
      Logger().w("Got message from firebase:\n${msg.data}\nNotification data:${msg.notification?.title}\n${msg.notification?.body}");
      
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
      if(msg.data["action"] == null) return;
      var action = NotificationAction.values.firstWhere((e) => e.name == msg.data["action"]);

      // TODO: Restore notification action handling if needed
      // NannyGlobals.notificationAction.value = action;
      // NannyGlobals.notificationActionData.value = msg.data;

      _handleAction(action, msg);
    });

    Logger().i("Inited firebase messages handler");
  }

  static void checkInitialMessage() async {
    var msg = await FirebaseMessaging.instance.getInitialMessage();
    if(msg == null) return;

    if(msg.data["action"] == null) return;
    var action = NotificationAction.values.firstWhere((e) => e.name == msg.data["action"]);

    _handleAction(action, msg);
  }

  static void _handleAction(NotificationAction action, RemoteMessage msg) {
    switch(action) {
      case NotificationAction.message:
        if(NannyGlobals.currentContext.widget.runtimeType == DirectView) {
          Navigator.pop(NannyGlobals.currentContext);
        }
      
        Navigator.push(
          NannyGlobals.currentContext, 
          MaterialPageRoute(builder: (context) => DirectView(idChat: int.parse( msg.data["id"] )))
        );
      break;

      case NotificationAction.order:
      break;

      case NotificationAction.orderFeedback:
      break;

      case NotificationAction.orderRequest:
      break;

      case NotificationAction.orderRequestSuccess:
      break;

      case NotificationAction.orderRequestDenied:
      break;

      case NotificationAction.fine:
      break;

      case NotificationAction.replyOrder:
      break;
    }
  }
}