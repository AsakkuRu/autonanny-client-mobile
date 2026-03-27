import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/search_query_request.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/nanny_core.dart';

class HomeVM extends ViewModelBase {
  HomeVM({
    required super.context,
    required super.update,
    this.onRealtimeReady,
  }) {
    initialSetup();
  }

  int currentIndex = 0;

  /// Количество непрочитанных сообщений в чатах (для бейджа на иконке «Чаты»).
  int unreadChatsCount = 0;

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

  /// Обновляет счётчик непрочитанных из get_chats (сумма new_message по всем чатам).
  Future<void> refreshUnreadChatsCount() async {
    final r = await NannyChatsApi.getChats(
      SearchQueryRequest(offset: 0, limit: 100, search: ''),
    );
    if (!r.success || r.response == null) return;
    int sum = 0;
    for (final c in r.response!.chats) {
      sum += c.message?.newMessages ?? 0;
    }
    if (!context.mounted) return;
    update(() => unreadChatsCount = sum);
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

    void refreshOnEvent(Map<String, dynamic> _) {
      refreshUnreadChatsCount();
    }

    for (final event in const [
      'connected',
      'chat.unread_changed',
      'chat.message_created',
      'chat.message_edited',
    ]) {
      _rootRealtimeSubs.add(socket.on(event).listen(refreshOnEvent));
    }
  }

  void dispose() {
    for (final sub in _rootRealtimeSubs) {
      sub.cancel();
    }
    _rootRealtimeSubs.clear();
    _localUnreadRefreshSub?.cancel();
  }
}
