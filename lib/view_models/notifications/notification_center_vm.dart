import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/api/nanny_users_api.dart';
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
  String? errorMessage;

  final List<Map<String, String>> filters = const [
    {'key': 'all', 'label': 'Все'},
    {'key': 'order', 'label': 'Заказы'},
    {'key': 'message', 'label': 'Сообщения'},
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
}
