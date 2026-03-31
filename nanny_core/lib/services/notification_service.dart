import 'dart:async';
import 'dart:convert';

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
/// NotificationService().handleEvent('trip.status_changed', {'order_id': 42, 'status': 'assigned'});
/// ```
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  int _notificationId = 0;
  String? _lastPresentationSignature;
  DateTime? _lastPresentationAt;
  static const Duration _presentationDedupWindow = Duration(seconds: 2);

  // Колбэк для in-app уведомлений (устанавливается UI-слоем)
  void Function(String title, String body, InAppStyle style)?
      onInAppNotification;
  FutureOr<void> Function(Map<String, dynamic> payload)? onLocalNotificationTap;
  Map<String, dynamic>? _pendingLocalTapPayload;

  /// Инициализация.
  Future<void> init([
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  ]) async {
    _navigatorKey = navigatorKey;
    _scaffoldMessengerKey = scaffoldMessengerKey;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

  void registerTapHandler(
    FutureOr<void> Function(Map<String, dynamic> payload) handler,
  ) {
    onLocalNotificationTap = handler;

    final pendingPayload = _pendingLocalTapPayload;
    if (pendingPayload == null) {
      return;
    }

    _pendingLocalTapPayload = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.sync(() => handler(pendingPayload));
    });
  }

  /// Обработать входящее WS-событие.
  void handleEvent(String event, Map<String, dynamic> data) {
    final config = _resolveConfig(event, data);
    if (config == null) return;

    final title = _interpolate(config.titleTemplate, data);
    final body = _interpolate(config.bodyTemplate, data);
    final signature = _presentationSignature(
      event: event,
      title: title,
      body: body,
      data: data,
    );
    if (_shouldSuppressPresentation(signature)) {
      return;
    }

    if (AppLifecycleService.isForeground) {
      final shownInApp = _showInApp(title, body, config.inAppStyle);
      if (shownInApp) {
        return;
      }
    }

    _showLocalNotification(title, body, config, event: event, data: data);
  }

  void showInAppMessage(
    String title,
    String body, {
    InAppStyle style = InAppStyle.banner,
  }) {
    if (title.trim().isEmpty && body.trim().isEmpty) {
      return;
    }
    if (_shouldSuppressPresentation('manual|$style|$title|$body')) {
      return;
    }
    _showInApp(title, body, style);
  }

  // ── In-App ────────────────────────────────────────────────────

  bool _showInApp(String title, String body, InAppStyle style) {
    if (onInAppNotification != null) {
      onInAppNotification!(title, body, style);
      return true;
    }

    // Fallback: через overlay если navigatorKey доступен
    switch (style) {
      case InAppStyle.banner:
        return _showBanner(title, body);
      case InAppStyle.toast:
        return _showToast(body);
      case InAppStyle.dialog:
        final context = _navigatorKey?.currentContext;
        if (context == null) {
          return false;
        }
        _showDialog(context, title, body);
        return true;
      case InAppStyle.none:
        return false;
    }
  }

  bool _showBanner(String title, String body) {
    final messenger = _scaffoldMessengerKey?.currentState;
    if (messenger == null) {
      return false;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (body.isNotEmpty)
              Text(
                body,
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin:
            const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      ),
    );
    return true;
  }

  bool _showToast(String body) {
    final messenger = _scaffoldMessengerKey?.currentState;
    if (messenger == null) {
      return false;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(body),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    return true;
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
    String title,
    String body,
    NotificationConfig config, {
    required String event,
    required Map<String, dynamic> data,
  }) async {
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
      payload: _buildLocalNotificationPayload(event, data),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return;
      }

      final normalized = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final handler = onLocalNotificationTap;
      if (handler == null) {
        _pendingLocalTapPayload = normalized;
        return;
      }

      Future.sync(() => handler(normalized));
    } catch (_) {
      // Игнорируем битый payload, чтобы не падать при тапе по уведомлению.
    }
  }

  // ── Каталог уведомлений ───────────────────────────────────────

  NotificationConfig? _resolveConfig(String event, Map<String, dynamic> data) {
    // События без уведомлений
    if (_silentEvents.contains(event)) return null;

    // Специальная обработка для trip.status_changed (зависит от канонического статуса)
    if (event == 'trip.status_changed') {
      final status = data['status']?.toString();
      if (status == null || status.isEmpty) return null;
      return _statusConfigs[status];
    }

    return _eventConfigs[event];
  }

  static const _silentEvents = {
    'connected',
    'pong',
    'subscriptions.updated',
    'driver.position_updated',
    'chat.unread_changed',
    'trip.assigned',
  };

  /// Конфигурации по каноническому trip status
  static final Map<String, NotificationConfig> _statusConfigs = {
    'assigned': const NotificationConfig(
      titleTemplate: 'Водитель найден!',
      bodyTemplate: 'Водитель принял ваш заказ',
      priority: NotificationPriority.high,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'driver_departed': const NotificationConfig(
      titleTemplate: 'Водитель в пути',
      bodyTemplate: 'Водитель едет к точке посадки',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'driver_arrived': const NotificationConfig(
      titleTemplate: 'Водитель прибыл!',
      bodyTemplate: 'Водитель ожидает на месте',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'child_onboard': const NotificationConfig(
      titleTemplate: 'Ребёнок в машине',
      bodyTemplate: 'Поездка началась',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'arrived_destination': const NotificationConfig(
      titleTemplate: 'Почти приехали',
      bodyTemplate: 'Водитель приближается к месту назначения',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'completed': const NotificationConfig(
      titleTemplate: 'Поездка завершена',
      bodyTemplate: 'Детали сохранены в истории поездок',
      priority: NotificationPriority.high,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'cancelled_by_driver': const NotificationConfig(
      titleTemplate: 'Водитель отменил поездку',
      bodyTemplate: 'Поиск нового водителя...',
      priority: NotificationPriority.max,
      playSound: true,
      inAppStyle: InAppStyle.dialog,
      channelId: 'trip_status_channel',
    ),
    'cancelled_by_client': const NotificationConfig(
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
    'trip.cancelled': const NotificationConfig(
      titleTemplate: 'Поездка отменена',
      bodyTemplate: 'Поездка была отменена',
      priority: NotificationPriority.high,
      playSound: true,
      inAppStyle: InAppStyle.banner,
      channelId: 'trip_status_channel',
    ),
    'chat.message_created': const NotificationConfig(
      titleTemplate: 'Новое сообщение',
      bodyTemplate: '{text}',
      priority: NotificationPriority.defaultPriority,
      inAppStyle: InAppStyle.banner,
      channelId: 'chat_channel',
    ),
    'route.change_result': const NotificationConfig(
      titleTemplate: 'Маршрут',
      bodyTemplate: '{message}',
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

  String _buildLocalNotificationPayload(
    String event,
    Map<String, dynamic> data,
  ) {
    return jsonEncode({
      'event': event,
      'data': _normalizePayloadValue(data),
    });
  }

  dynamic _normalizePayloadValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _normalizePayloadValue(nestedValue)),
      );
    }

    if (value is Iterable) {
      return value.map(_normalizePayloadValue).toList(growable: false);
    }

    return value.toString();
  }

  Importance _mapImportance(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.max:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.defaultPriority:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  Priority _mapPriority(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.max:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  String _presentationSignature({
    required String event,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final chatId = _readPayloadId(
      data,
      const ['chat_id', 'id_chat', 'chatId', 'id'],
    );
    final messageId = _readPayloadId(
      data,
      const ['message_id', 'id_message'],
    );
    final orderId = _readPayloadId(
      data,
      const ['order_id', 'id_order'],
    );
    final scheduleId = _readPayloadId(
      data,
      const ['schedule_id', 'id_schedule', 'contract_id'],
    );

    return [
      event,
      data['type']?.toString() ?? '',
      chatId ?? '',
      messageId ?? '',
      orderId ?? '',
      scheduleId ?? '',
      title,
      body,
    ].join('|');
  }

  String? _readPayloadId(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key];
      if (value == null) {
        continue;
      }
      final normalized = value.toString();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  bool _shouldSuppressPresentation(String signature) {
    final now = DateTime.now();
    final lastSignature = _lastPresentationSignature;
    final lastAt = _lastPresentationAt;
    if (lastSignature == signature &&
        lastAt != null &&
        now.difference(lastAt) < _presentationDedupWindow) {
      return true;
    }

    _lastPresentationSignature = signature;
    _lastPresentationAt = now;
    return false;
  }
}
