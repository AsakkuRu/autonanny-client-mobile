import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_resolver.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
import 'package:nanny_client/views/pages/balance.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/messaging/route_deviation_notifications.dart';
import 'package:nanny_client/views/pages/graph.dart';
import 'package:nanny_client/views/pages/transactions/transactions_history_view.dart';
import 'package:nanny_client/views/rating/driver_rating_view.dart';

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
      case 'weekly_payment_failed':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TransactionsHistoryView(
              initialTransactionType: 'payment',
            ),
          ),
        );
        return;
      case 'contract_resumed':
        final scheduleId =
            int.tryParse(msg.data['schedule_id']?.toString() ?? '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GraphView(
              persistState: false,
              initialScheduleId: scheduleId,
              openInitialScheduleDetails: scheduleId != null,
            ),
          ),
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

    final type = msg.data['type']?.toString() ?? '';
    final resolvedTarget =
        msg.data['target']?.toString() ?? _fallbackTarget(type);
    if (resolvedTarget == null) {
      return false;
    }

    final scheduleId = _readIntPayload(
      msg.data['schedule_id'] ?? msg.data['id_schedule'],
    );
    final orderId = _readIntPayload(
      msg.data['order_id'] ?? msg.data['id_order'],
    );
    final chatId = _readIntPayload(
      msg.data['chat_id'] ?? msg.data['id_chat'] ?? msg.data['id'],
    );

    switch (resolvedTarget) {
      case 'rating_request':
        if (orderId == null) {
          return false;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverRatingView(
              orderId: orderId,
              driverName: msg.data['driver_name']?.toString(),
              driverPhoto: msg.data['driver_photo']?.toString(),
            ),
          ),
        );
        return true;
      case 'trip':
      case 'active_trip':
        _openActiveTrip(context, orderId);
        return true;
      case 'contracts':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GraphView(
              persistState: false,
              initialScheduleId: scheduleId,
              openInitialScheduleDetails: scheduleId != null,
            ),
          ),
        );
        return true;
      case 'balance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BalanceView(persistState: false),
          ),
        );
        return true;
      case 'wallet_operation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionsHistoryView(
              initialTransactionType:
                  msg.data['transaction_type']?.toString() ?? 'payment',
              initialSearchQuery: _buildWalletSearchQuery(
                scheduleId: scheduleId,
                orderId: orderId,
              ),
            ),
          ),
        );
        return true;
      case 'chat':
        if (chatId == null) {
          return false;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectView(
              idChat: chatId,
              name: msg.data['chat_name']?.toString(),
            ),
          ),
        );
        return true;
      default:
        return false;
    }
  }

  static Future<void> _openActiveTrip(
    BuildContext context,
    int? expectedOrderId,
  ) async {
    final activeTrip = await ActiveTripResolver.resolveCurrentActiveTrip();
    if (!context.mounted) {
      return;
    }

    if (activeTrip == null || activeTrip.token.isEmpty) {
      _showInfoMessage(
          context, 'Активная поездка уже завершена или недоступна.');
      return;
    }
    if (expectedOrderId != null &&
        activeTrip.orderId != null &&
        activeTrip.orderId != expectedOrderId) {
      _showInfoMessage(
          context, 'Эта поездка уже завершена или больше не активна.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveTripScreen(token: activeTrip.token),
      ),
    );
  }

  static void _showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static int? _readIntPayload(dynamic rawValue) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is String) {
      return int.tryParse(rawValue);
    }
    return null;
  }

  static String? _fallbackTarget(String type) {
    switch (type) {
      case 'payment':
      case 'weekly_payment_success':
      case 'weekly_payment_failed':
        return 'wallet_operation';
      case 'message':
        return 'chat';
      case 'order':
      case 'contract_resumed':
        return 'contracts';
      case 'rating_request':
        return 'rating_request';
      case 'trip':
      case 'active_trip':
        return 'active_trip';
      default:
        return null;
    }
  }

  static String? _buildWalletSearchQuery({
    required int? scheduleId,
    required int? orderId,
  }) {
    if (orderId != null) {
      return '#$orderId';
    }
    if (scheduleId != null) {
      return '#$scheduleId';
    }
    return null;
  }
}
