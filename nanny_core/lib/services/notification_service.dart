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
  int _notificationId = 0;
  OverlayEntry? _inAppOverlayEntry;
  Timer? _inAppOverlayTimer;

  // Колбэк для in-app уведомлений (устанавливается UI-слоем)
  void Function(String title, String body, InAppStyle style)?
      onInAppNotification;
  FutureOr<void> Function(Map<String, dynamic> payload)? onLocalNotificationTap;
  Map<String, dynamic>? _pendingLocalTapPayload;

  /// Инициализация.
  Future<void> init([GlobalKey<NavigatorState>? navigatorKey]) async {
    _navigatorKey = navigatorKey;

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

    if (AppLifecycleService.isForeground) {
      _showInApp(title, body, config.inAppStyle);
    } else {
      _showLocalNotification(title, body, config, event: event, data: data);
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
    _showTopOverlay(
      context,
      title: title,
      body: body,
      duration: const Duration(seconds: 4),
    );
  }

  void _showToast(BuildContext context, String body) {
    _showTopOverlay(
      context,
      title: '',
      body: body,
      duration: const Duration(seconds: 2),
      compact: true,
    );
  }

  void _showTopOverlay(
    BuildContext context, {
    required String title,
    required String body,
    required Duration duration,
    bool compact = false,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _hideInAppOverlay();

    _inAppOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final topInset = MediaQuery.of(overlayContext).padding.top;
        return Positioned(
          top: topInset + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: _hideInAppOverlay,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF343443),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: compact ? 14 : 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty) ...[
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            if (body.isNotEmpty) const SizedBox(height: 4),
                          ],
                          if (body.isNotEmpty)
                            Text(
                              body,
                              style: TextStyle(
                                color: compact
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.82),
                                fontSize: 14,
                                height: 1.25,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_inAppOverlayEntry!);
    _inAppOverlayTimer = Timer(duration, _hideInAppOverlay);
  }

  void _hideInAppOverlay() {
    _inAppOverlayTimer?.cancel();
    _inAppOverlayTimer = null;
    _inAppOverlayEntry?.remove();
    _inAppOverlayEntry = null;
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
}
