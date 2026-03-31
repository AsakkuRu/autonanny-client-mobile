import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPayloadHelper {
  static Map<String, dynamic> normalizeForegroundPayload(RemoteMessage msg) {
    final payload = Map<String, dynamic>.from(msg.data);

    payload.putIfAbsent(
      'text',
      () => payload['text_preview'] ?? msg.notification?.body ?? '',
    );
    payload.putIfAbsent(
      'message',
      () => payload['body'] ?? msg.notification?.body ?? payload['text'] ?? '',
    );
    payload.putIfAbsent('title', () => msg.notification?.title ?? '');
    payload.putIfAbsent('body', () => msg.notification?.body ?? '');

    return payload;
  }

  static String? resolveForegroundEvent(Map<String, dynamic> payload) {
    final event = payload['event']?.toString();
    if (event != null && event.isNotEmpty) {
      return event;
    }

    switch (payload['type']?.toString()) {
      case 'message':
      case 'chat.message_created':
      case 'new_chat':
        return 'chat.message_created';
      case 'trip_status':
      case 'trip_status_update':
        return 'trip.status_changed';
      case 'trip_cancelled':
        return 'trip.cancelled';
      case 'route.change_requested':
        return 'route.change_requested';
      case 'route.change_result':
        return 'route.change_result';
      default:
        return null;
    }
  }

  static int? readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool isChatPayload(Map<String, dynamic> payload) {
    final target = payload['target']?.toString();
    final type = payload['type']?.toString();
    final chatId = readInt(
      payload['chat_id'] ?? payload['id_chat'] ?? payload['id'],
    );
    final looksLikeChat = target == 'chat' ||
        target == 'support_chat' ||
        type == 'message' ||
        type == 'chat.message_created' ||
        type == 'new_chat';
    return looksLikeChat && chatId != null;
  }
}
