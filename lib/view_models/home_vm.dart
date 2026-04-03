import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nanny_components/base_views/views/direct.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/api/api_models/search_query_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/services/notification_service.dart';

class HomeVM extends ViewModelBase {
  HomeVM({
    required super.context,
    required super.update,
    this.onRealtimeReady,
  }) {
    initialSetup();
  }

  int currentIndex = 0;

  /// Непрочитанные сообщения в диалогах (вкладка «Чаты»).
  int unreadChatMessagesCount = 0;

  /// Отклики водителей по контрактам (вкладка «Заявки»).
  int pendingScheduleResponsesCount = 0;

  /// Суммарный бейдж на «Чаты» в нижней навигации: сообщения + новые заявки.
  int get chatsBottomNavBadgeCount =>
      (unreadChatMessagesCount + pendingScheduleResponsesCount).clamp(0, 99);

  /// Вызывается после инициализации UnifiedSocket.
  /// Используется в NewHomeView для root-level realtime подписок.
  final VoidCallback? onRealtimeReady;
  UnifiedSocket? _socket;
  final List<StreamSubscription<Map<String, dynamic>>> _rootRealtimeSubs = [];
  StreamSubscription<void>? _localUnreadRefreshSub;

  void indexChanged(int index) {
    update(() => currentIndex = index);
    if (index == 3) refreshUnreadChatsCount();
  }

  /// Непрочитанные сообщения + число откликов по контрактам (для бейджей).
  Future<void> refreshUnreadChatsCount() async {
    final r = await NannyChatsApi.getChats(
      SearchQueryRequest(offset: 0, limit: 100, search: ''),
    );
    int sum = 0;
    if (r.success && r.response != null) {
      for (final c in r.response!.chats) {
        sum += c.message?.newMessages ?? 0;
      }
    }
    int pending = 0;
    final sr = await NannyOrdersApi.getScheduleResponses();
    if (sr.success && sr.response != null) {
      pending = sr.response!.length;
    }
    if (!context.mounted) return;
    update(() {
      unreadChatMessagesCount = sum;
      pendingScheduleResponsesCount = pending;
    });
  }

  void initialSetup() async {
    try {
      _socket = await UnifiedSocket.connect();
      onRealtimeReady?.call();
      _bindRootRealtimeListeners();
    } catch (e, st) {
      debugPrint('[HomeVM] UnifiedSocket init error: $e\n$st');
    }

    refreshUnreadChatsCount();
    _localUnreadRefreshSub?.cancel();
    _localUnreadRefreshSub =
        NannyGlobals.chatUnreadRefreshController.stream.listen((_) {
      refreshUnreadChatsCount();
    });

    if (Platform.isAndroid || Platform.isIOS) {
      FirebaseMessagingHandler.checkInitialMessage();
    }
  }

  void _bindRootRealtimeListeners() {
    for (final sub in _rootRealtimeSubs) {
      sub.cancel();
    }
    _rootRealtimeSubs.clear();

    final socket = _socket;
    if (socket == null) return;

    socket.send('subscriptions.update', {
      'subscriptions': {
        'contract.responses': true,
      },
    });

    void refreshOnEvent(Map<String, dynamic> _) {
      refreshUnreadChatsCount();
    }

    _rootRealtimeSubs.add(socket.on('connected').listen((_) {
      socket.send('subscriptions.update', {
        'subscriptions': {
          'contract.responses': true,
        },
      });
      refreshUnreadChatsCount();
    }));
    _rootRealtimeSubs.add(socket.on('chat.unread_changed').listen(refreshOnEvent));
    _rootRealtimeSubs.add(socket.on('chat.message_edited').listen(refreshOnEvent));
    _rootRealtimeSubs.add(
      socket.on('contract.responses.updated').listen(refreshOnEvent),
    );
    _rootRealtimeSubs.add(
      socket.on('chat.message_created').listen(_handleChatMessageCreated),
    );
  }

  void _handleChatMessageCreated(Map<String, dynamic> event) {
    refreshUnreadChatsCount();

    final payload = _normalizeRealtimePayload(event);
    if (payload.isEmpty || _readBool(payload['is_me'])) {
      return;
    }

    final chatId = _readInt(
      payload['chat_id'] ?? payload['id_chat'] ?? payload['id'],
    );
    if (chatId != null && DirectView.activeChatId == chatId) {
      return;
    }

    NotificationService().handleEvent('chat.message_created', payload);
  }

  Map<String, dynamic> _normalizeRealtimePayload(Map<String, dynamic> event) {
    final rawData = event['data'];
    if (rawData is Map) {
      final payload = rawData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      payload.putIfAbsent(
        'text',
        () => payload['text_preview'] ?? payload['message'] ?? '',
      );
      return payload;
    }
    return const <String, dynamic>{};
  }

  bool _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  void dispose() {
    for (final sub in _rootRealtimeSubs) {
      sub.cancel();
    }
    _rootRealtimeSubs.clear();
    _localUnreadRefreshSub?.cancel();
  }
}
