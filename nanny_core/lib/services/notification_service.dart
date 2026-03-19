import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nanny_core/services/app_lifecycle_service.dart';

/// Конфигурация одного типа уведомления.
class NotificationConfig {
  final String titleTemplate;
  final String bodyTemplate;
  final NotificationPriority priority;
  final bool playSound;
  final InAppStyle inAppStyle;
  final String? channelId;

  const NotificationConfig({
    required this.titleTemplate,
    required this.bodyTemplate,
    this.priority = NotificationPriority.defaultPriority,
    this.playSound = false,
    this.inAppStyle = InAppStyle.banner,
    this.channelId,
  });
}

enum NotificationPriority { max, high, defaultPriority, low }
enum InAppStyle { banner, toast, dialog, none }

/// Единый сервис уведомлений.
///
/// Принимает WS-события и решает как показать:
/// - foreground → in-app banner/toast/dialog
/// - background → local notification (системное)
///
/// Использование:
/// ```dart
/// NotificationService().init(navigatorKey);
/// NotificationService().handleEvent('order.status_changed', {'order_id': 42, 'status': 13});
/// ```
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  int _notificationId = 0;

  // Колбэк для in-app уведомлений (устанавливается UI-слоем)
  void Function(String title, String body, InAppStyle style)? onInAppNotification;

  /// Инициализация.
  Future<void> init([GlobalKey<NavigatorState>? navigatorKey]) async {
    _navigatorKey = navigatorKey;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Обработать входящее WS-событие.
  void handleEvent(String event, Map<String, dynamic> data) {
    final config = _resolveConfig(event, data);
    if (config == null) return;

    final title = _interpolate(config.titleTemplate, data);
    final body = _interpolate(config.bodyTemplate, data);

    if (AppLifecycleService.isForeground) {
      _showInApp(title, body, config.inAppStyle);
    } else {
      _showLocalNotification(title, body, config);
    }
  }

  // ── In-App ────────────────────────────────────────────────────

  void _showInApp(String title, String body, InAppStyle style) {
    if (onInAppNotification != null) {
      onInAppNotification!(title, body, style);
      return;
    }

    // Fallback: через overlay если navigatorKey доступен
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    switch (style) {
      case InAppStyle.banner:
        _showBanner(context, title, body);
        break;
      case InAppStyle.toast:
        _showToast(context, body);
        break;
      case InAppStyle.dialog:
        _showDialog(context, title, body);
        break;
      case InAppStyle.none:
        break;
    }
  }

  void _showBanner(BuildContext context, String title, String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            if (body.isNotEmpty) Text(body, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      ),
    );
  }

  void _showToast(BuildContext context, String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Ок"),
          ),
        ],
      ),
    );
  }

  // ── Local Notification ────────────────────────────────────────

  Future<void> _showLocalNotification(
    String title, String body, NotificationConfig config,
  ) async {
    final importance = _mapImportance(config.priority);
    final priority = _mapPriority(config.priority);

    await _localNotifications.show(
      _notificationId++,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          config.channelId ?? 'autonanny_default',
          'AutoNanny',
          importance: importance,
          priority: priority,
          playSound: config.playSound,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // TODO: навигация по тапу на уведомление
  }

  // ── Каталог уведомлений ───────────────────────────────────────

  NotificationConfig? _resolveConfig(String event, Map<String, dynamic> data) {
    // События без уведомлений
    if (_silentEvents.contains(event)) return null;

    // Специальная обработка для order.status_changed (зависит от статуса)
    if (event == 'order.status_changed') {
      final status = data['status'];
      return _statusConfigs[status];
    }

    return _eventConfigs[event];
  }

  static const _silentEvents = {
    'connected', 'pong', 'order.driver_location', 'order.drivers_nearby', 'order.taken',
  };

  /// Конфигурации по статусу заказа
  static final Map<int, NotificationConfig> _statusConfigs = {
    13: const NotificationConfig(
      titleTemplate: 'Водитель найден!',
      bodyTemplate: 'Водитель принял ваш заказ',
      priority: NotificationPriority.high,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    5: const NotificationConfig(
      titleTemplate: 'Водитель в пути',
      bodyTemplate: 'Водитель едет к точке посадки',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    6: const NotificationConfig(
      titleTemplate: 'Водитель прибыл!',
      bodyTemplate: 'Водитель ожидает на месте',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    7: const NotificationConfig(
      titleTemplate: 'Водитель прибыл!',
      bodyTemplate: 'Водитель ожидает на месте',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    14: const NotificationConfig(
      titleTemplate: 'Ребёнок в машине',
      bodyTemplate: 'Поездка началась',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    15: const NotificationConfig(
      titleTemplate: 'Почти приехали',
      bodyTemplate: 'Водитель приближается к месту назначения',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    11: const NotificationConfig(
      titleTemplate: 'Поездка завершена',
      bodyTemplate: 'Ваша поездка успешно завершена',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.dialog,
      channelId: 'trip_status_channel',
    ),
    2: const NotificationConfig(
      titleTemplate: 'Водитель отменил поездку',
      bodyTemplate: 'Поиск нового водителя...',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.dialog,
      channelId: 'trip_status_channel',
    ),
    3: const NotificationConfig(
      titleTemplate: 'Поездка отменена',
      bodyTemplate: 'Заказ был отменён',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.toast,
      channelId: 'trip_status_channel',
    ),
  };

  /// Конфигурации по типу события
  static final Map<String, NotificationConfig> _eventConfigs = {
    'order.expired': const NotificationConfig(
      titleTemplate: 'Водитель не найден',
      bodyTemplate: 'Не удалось найти водителя за 10 минут',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.dialog,
      channelId: 'trip_status_channel',
    ),
    'order.cancelled': const NotificationConfig(
      titleTemplate: 'Заказ отменён',
      bodyTemplate: 'Клиент отменил заказ',
      priority: NotificationPriority.high,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'order.new_available': const NotificationConfig(
      titleTemplate: 'Новый заказ рядом!',
      bodyTemplate: 'Откройте приложение для просмотра',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'order_channel',
    ),
    'chat.message': const NotificationConfig(
      titleTemplate: 'Новое сообщение',
      bodyTemplate: '{text}',
      priority: NotificationPriority.defaultPriority,
      inAppStyle: InAppStyle.banner,
      channelId: 'chat_channel',
    ),
    'route.change_result': const NotificationConfig(
      titleTemplate: 'Маршрут',
      bodyTemplate: 'Изменение маршрута обработано',
      priority: NotificationPriority.defaultPriority,
      inAppStyle: InAppStyle.toast,
    ),
    'route.change_requested': const NotificationConfig(
      titleTemplate: 'Изменение маршрута',
      bodyTemplate: 'Клиент запросил изменение маршрута',
      priority: NotificationPriority.high,
      playSound: true,
      inAppStyle: InAppStyle.dialog,
      channelId: 'trip_status_channel',
    ),
  };

  // ── Утилиты ───────────────────────────────────────────────────

  String _interpolate(String template, Map<String, dynamic> data) {
    var result = template;
    data.forEach((key, value) {
      result = result.replaceAll('{$key}', value?.toString() ?? '');
    });
    return result;
  }

  Importance _mapImportance(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.max: return Importance.max;
      case NotificationPriority.high: return Importance.high;
      case NotificationPriority.defaultPriority: return Importance.defaultImportance;
      case NotificationPriority.low: return Importance.low;
    }
  }

  Priority _mapPriority(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.max: return Priority.max;
      case NotificationPriority.high: return Priority.high;
      case NotificationPriority.defaultPriority: return Priority.defaultPriority;
      case NotificationPriority.low: return Priority.low;
    }
  }
}
