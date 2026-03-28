import 'dart:async';

import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/api/nanny_users_api.dart';
import 'package:nanny_core/models/from_api/notification_item.dart';

/// B-014 TASK-B14: ViewModel центра уведомлений (клиент)
class NotificationCenterVM extends ViewModelBase {
  NotificationCenterVM({
    required super.context,
    required super.update,
  }) {
    unawaited(_bindRealtimeUpdates());
  }

  List<NotificationItem> notifications = [];
  String selectedFilter = 'all';
  bool isLoading = false;
  String? errorMessage;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;
  bool _reloadingFromRealtime = false;

  final List<Map<String, String>> filters = const [
    {'key': 'all', 'label': 'Все'},
    {'key': 'order', 'label': 'Заказы'},
    {'key': 'message', 'label': 'Сообщения'},
    {'key': 'payment', 'label': 'Платежи'},
    {'key': 'referral', 'label': 'Рефералы'},
    {'key': 'system', 'label': 'Система'},
  ];

  List<NotificationItem> get filteredNotifications {
    final filtered = selectedFilter == 'all'
        ? List<NotificationItem>.from(notifications)
        : notifications.where((n) => n.type == selectedFilter).toList();
    filtered.sort((a, b) {
      final createdAtCompare = b.createdAt.compareTo(a.createdAt);
      if (createdAtCompare != 0) {
        return createdAtCompare;
      }

      final unreadCompare = (b.isRead ? 0 : 1).compareTo(a.isRead ? 0 : 1);
      if (unreadCompare != 0) {
        return unreadCompare;
      }

      return b.id.compareTo(a.id);
    });
    return filtered;
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void setFilter(String filter) {
    update(() => selectedFilter = filter);
  }

  @override
  Future<bool> loadPage() async {
    update(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await NannyUsersApi.getNotifications(limit: 100);
    if (!result.success || result.response == null) {
      update(() {
        notifications = [];
        errorMessage = result.errorMessage.isNotEmpty
            ? result.errorMessage
            : 'Не удалось загрузить уведомления';
        isLoading = false;
      });
      return false;
    }

    update(() {
      notifications = result.response!;
      errorMessage = null;
      isLoading = false;
    });
    return true;
  }

  void markAsRead(int id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      update(() {
        notifications[index] = notifications[index].copyWith(isRead: true);
      });
      NannyUsersApi.markNotificationRead(id);
    }
  }

  void markAllAsRead() {
    update(() {
      notifications =
          notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    NannyUsersApi.markAllNotificationsRead();
  }

  Future<bool> refresh() async {
    return loadPage();
  }

  Future<void> _bindRealtimeUpdates() async {
    await _realtimeSub?.cancel();
    final socket = UnifiedSocket.instance ?? await UnifiedSocket.connect();
    _realtimeSub = socket.events.listen((msg) {
      final event = msg['event']?.toString();
      if (event == 'connected') {
        unawaited(_refreshFromRealtime());
        return;
      }
      if (event != 'history_notification.created') {
        return;
      }

      final data = msg['data'];
      if (data is! Map) {
        unawaited(_refreshFromRealtime());
        return;
      }

      final rawNotification = data['notification'];
      if (rawNotification is! Map) {
        unawaited(_refreshFromRealtime());
        return;
      }

      _mergeRealtimeNotification(
        Map<String, dynamic>.from(rawNotification),
      );
    });
  }

  Future<void> _refreshFromRealtime() async {
    if (_reloadingFromRealtime || isLoading) {
      return;
    }
    _reloadingFromRealtime = true;
    try {
      await refresh();
    } finally {
      _reloadingFromRealtime = false;
    }
  }

  void _mergeRealtimeNotification(Map<String, dynamic> rawNotification) {
    final item = NotificationItem.fromJson(rawNotification);
    if (item.id == 0) {
      unawaited(_refreshFromRealtime());
      return;
    }

    final existingIndex = notifications.indexWhere((n) => n.id == item.id);
    update(() {
      if (existingIndex == -1) {
        notifications = [item, ...notifications];
        return;
      }
      notifications[existingIndex] = item;
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}
