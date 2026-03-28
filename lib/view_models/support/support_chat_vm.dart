import 'dart:async';

import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/api/nanny_chats_api.dart';

class SupportMessage {
  final int id;
  final String text;
  final DateTime timestamp;
  final bool isFromMe;
  final bool isRead;
  final String? attachmentUrl;

  SupportMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isFromMe,
    this.isRead = false,
    this.attachmentUrl,
  });

  String get timeString {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class SupportChatVM extends ViewModelBase {
  SupportChatVM({
    required super.context,
    required super.update,
  });

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<SupportMessage> messages = [];
  bool isLoading = true;
  bool isSending = false;
  int? chatId;
  String? loadError;
  Timer? _pollTimer;
  bool _pollingNow = false;

  static const Duration _pollInterval = Duration(seconds: 12);

  // TASK-C5: флаг показа баннера оценки после закрытия тикета
  bool showRatingBanner = false;
  bool ratingSubmitted = false;

  @override
  Future<bool> loadPage() async {
    _stopPolling();
    update(() {
      isLoading = true;
      loadError = null;
    });

    final chatResult = await NannyChatsApi.createSupportChat();
    if (chatResult.success && chatResult.response != null) {
      chatId = chatResult.response;
      await _loadMessages();
      _checkIfTicketClosed();
      _startPolling();
    } else {
      chatId = null;
      messages = [];
      loadError = chatResult.errorMessage;
    }

    update(() => isLoading = false);
    return loadError == null;
  }

  // Показываем рейтинг только когда backend начнет отдавать реальный статус закрытия тикета.
  void _checkIfTicketClosed() {
    showRatingBanner = false;
  }

  void onRatingSubmitted() {
    update(() {
      ratingSubmitted = true;
      showRatingBanner = false;
    });
  }

  void dismissRatingBanner() {
    update(() => showRatingBanner = false);
  }

  Future<void> _loadMessages() async {
    final result = await NannyChatsApi.getSupportMessages();
    if (result.success && result.response != null) {
      chatId = result.response!.idChat == 0 ? chatId : result.response!.idChat;
      messages = result.response!.messages
          .map((m) => SupportMessage(
                id: m.id ?? 0,
                text: m.msg,
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  (m.timestampSend * 1000).round(),
                ),
                isFromMe: m.isMe,
                isRead: true,
              ))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      loadError = null;
    } else {
      loadError = result.errorMessage;
    }
  }

  int? _latestMessageId() {
    if (messages.isEmpty) return null;

    var latestId = messages.first.id;
    for (final message in messages.skip(1)) {
      if (message.id > latestId) {
        latestId = message.id;
      }
    }
    return latestId;
  }

  bool _isNearBottom() {
    if (!scrollController.hasClients) return true;
    return scrollController.offset <= 120;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_pollNewMessages());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollNewMessages() async {
    if (_pollingNow || chatId == null) return;
    _pollingNow = true;

    try {
      final result = await NannyChatsApi.getSupportMessages(
        lastMessageId: _latestMessageId(),
      );
      if (!result.success || result.response == null) {
        return;
      }

      chatId = result.response!.idChat == 0 ? chatId : result.response!.idChat;
      final freshMessages = result.response!.messages
          .map((m) => SupportMessage(
                id: m.id ?? 0,
                text: m.msg,
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  (m.timestampSend * 1000).round(),
                ),
                isFromMe: m.isMe,
                isRead: true,
              ))
          .toList();
      if (freshMessages.isEmpty) {
        return;
      }

      final shouldScroll = _isNearBottom();
      final existingIds = messages.map((message) => message.id).toSet();
      final uniqueMessages = freshMessages
          .where((message) => !existingIds.contains(message.id))
          .toList();
      if (uniqueMessages.isEmpty) {
        return;
      }

      messages = [...uniqueMessages, ...messages]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      loadError = null;
      update(() {});

      if (shouldScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } finally {
      _pollingNow = false;
    }
  }

  Future<void> refresh() async {
    await loadPage();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending) return;

    update(() => isSending = true);

    if (chatId == null) {
      final chatResult = await NannyChatsApi.createSupportChat();
      if (!chatResult.success || chatResult.response == null) {
        update(() => isSending = false);
        if (!context.mounted) {
          return;
        }
        await NannyDialogs.showResultSheet(
          context,
          title: 'Не удалось отправить сообщение',
          message: chatResult.errorMessage,
          tone: AutonannyBannerTone.danger,
          leading: const AutonannyIcon(AutonannyIcons.warning),
        );
        return;
      }
      chatId = chatResult.response;
    }

    final result = await NannyChatsApi.sendSupportMessage(message: text);
    if (result.success) {
      messageController.clear();
      await _loadMessages();
      _scrollToBottom();
    }

    update(() => isSending = false);

    if (!context.mounted) return;

    if (!result.success) {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Не удалось отправить сообщение',
        message: result.errorMessage,
        tone: AutonannyBannerTone.danger,
        leading: const AutonannyIcon(AutonannyIcons.warning),
      );
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _stopPolling();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
