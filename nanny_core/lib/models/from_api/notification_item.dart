/// B-014 TASK-B14: Модель уведомления для центра уведомлений
class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? payload;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.payload,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      payload: payload,
    );
  }

  static List<NotificationItem> mockList() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 1,
        type: 'order',
        title: 'Водитель выехал',
        body: 'Петров Пётр уже едет по контракту «Утренний маршрут».',
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        payload: {
          'target': 'contracts',
          'schedule_id': 17,
        },
      ),
      NotificationItem(
        id: 2,
        type: 'payment',
        title: 'Баланс пополнен',
        body: 'На счёт зачислено +3 000 ₽. Средства доступны для следующих поездок.',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
        payload: {
          'target': 'wallet_operation',
          'transaction_type': 'deposit',
        },
      ),
      NotificationItem(
        id: 3,
        type: 'order',
        title: 'Контракт приостановлен',
        body: '«Утренний маршрут» временно на паузе. Проверьте детали контракта.',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
        payload: {
          'target': 'contracts',
          'schedule_id': 17,
        },
      ),
      NotificationItem(
        id: 4,
        type: 'system',
        title: 'Обновление приложения',
        body: 'Доступна новая версия АвтоНяни с улучшениями.',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }
}
