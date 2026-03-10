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
        title: 'Заказ подтверждён',
        body: 'Водитель Алексей принял ваш заказ и едет к вам.',
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationItem(
        id: 2,
        type: 'payment',
        title: 'Поездка завершена',
        body: 'Списано 450 ₽ за поездку ул. Ленина → Школа №42.',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: 3,
        type: 'referral',
        title: 'Бонус за реферала',
        body: 'Вы получили 200 ₽ за приглашённого пользователя.',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
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
