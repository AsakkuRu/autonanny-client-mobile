import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/search_query_request.dart';
import 'package:nanny_core/nanny_core.dart';

class HomeVM extends ViewModelBase {
  HomeVM({
    required super.context,
    required super.update,
    this.onChatSocketReady,
  }) {
    initialSetup();
  }

  int currentIndex = 0;

  /// Количество непрочитанных сообщений в чатах (для бейджа на иконке «Чаты»).
  int unreadChatsCount = 0;

  /// Вызывается после того, как ChatsSocket подключён.
  /// Используется в NewHomeView для подписки на trip_started.
  final VoidCallback? onChatSocketReady;

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
    await NannyGlobals.initChatSocket();
    onChatSocketReady?.call();
    refreshUnreadChatsCount();
    NannyGlobals.chatsSocket.stream.listen((_) {
      refreshUnreadChatsCount();
    });

    if (Platform.isAndroid || Platform.isIOS) {
      FirebaseMessagingHandler.checkInitialMessage();
    }
  }
}