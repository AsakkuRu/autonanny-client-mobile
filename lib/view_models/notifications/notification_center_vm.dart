import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/notification_item.dart';

/// B-014 TASK-B14: ViewModel центра уведомлений (клиент)
class NotificationCenterVM extends ViewModelBase {
  NotificationCenterVM({
    required super.context,
    required super.update,
  });

  List<NotificationItem> notifications = [];
  String selectedFilter = 'all';
  bool isLoading = false;

  final List<Map<String, String>> filters = const [
    {'key': 'all', 'label': 'Все'},
    {'key': 'order', 'label': 'Заказы'},
    {'key': 'payment', 'label': 'Платежи'},
    {'key': 'referral', 'label': 'Рефералы'},
    {'key': 'system', 'label': 'Система'},
  ];

  List<NotificationItem> get filteredNotifications {
    if (selectedFilter == 'all') return notifications;
    return notifications.where((n) => n.type == selectedFilter).toList();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void setFilter(String filter) {
    update(() => selectedFilter = filter);
  }

  @override
  Future<bool> loadPage() async {
    update(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    notifications = NotificationItem.mockList();
    update(() => isLoading = false);
    return true;
  }

  void markAsRead(int id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      update(() {
        notifications[index] = notifications[index].copyWith(isRead: true);
      });
    }
  }

  void markAllAsRead() {
    update(() {
      notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> refresh() async {
    await loadPage();
  }
}
