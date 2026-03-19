import 'package:nanny_core/nanny_core.dart';

class ActiveTripSessionData {
  const ActiveTripSessionData({
    required this.token,
    this.orderId,
    this.statusId,
    this.chatId,
  });

  final String token;
  final int? orderId;
  final int? statusId;
  final int? chatId;

  Map<String, dynamic> toJson() => {
        'token': token,
        'order_id': orderId,
        'status_id': statusId,
        'chat_id': chatId,
      };

  factory ActiveTripSessionData.fromJson(Map<String, dynamic> json) {
    return ActiveTripSessionData(
      token: (json['token'] ?? '').toString(),
      orderId: json['order_id'] is num ? (json['order_id'] as num).toInt() : null,
      statusId: json['status_id'] is num ? (json['status_id'] as num).toInt() : null,
      chatId: json['chat_id'] is num ? (json['chat_id'] as num).toInt() : null,
    );
  }
}

class ActiveTripSessionStore {
  static const String _key = 'active_trip_session';

  static Future<void> save(ActiveTripSessionData data) async {
    await NannyStorage.setCustomItem(_key, data.toJson());
  }

  static Future<ActiveTripSessionData?> load() async {
    final raw = await NannyStorage.getCustomItem<Map<String, dynamic>>(_key);
    if (raw == null) return null;
    final parsed = ActiveTripSessionData.fromJson(raw);
    if (parsed.token.isEmpty) return null;
    return parsed;
  }

  static Future<void> clear() async {
    await NannyStorage.deleteCustomItem(_key);
  }
}
