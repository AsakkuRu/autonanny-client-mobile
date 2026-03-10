import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
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
  int? chatId;

  // TASK-C5: флаг показа баннера оценки после закрытия тикета
  bool showRatingBanner = false;
  bool ratingSubmitted = false;

  @override
  Future<bool> loadPage() async {
    update(() => isLoading = true);

    final chatResult = await NannyChatsApi.createSupportChat();
    if (chatResult.success && chatResult.response != null) {
      chatId = chatResult.response;
      await _loadMessages();
      _checkIfTicketClosed();
    } else {
      messages = _generateMockMessages();
      // Mock: симулируем закрытый тикет для демонстрации
      _checkIfTicketClosed();
    }

    update(() => isLoading = false);
    return true;
  }

  // Проверяем, закрыт ли тикет (mock: если есть сообщения — показываем баннер)
  void _checkIfTicketClosed() {
    if (!ratingSubmitted && messages.isNotEmpty) {
      showRatingBanner = true;
    }
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
      messages = result.response!.messages.map((m) => SupportMessage(
        id: m.id ?? 0,
        text: m.msg,
        timestamp: DateTime.fromMillisecondsSinceEpoch((m.timestampSend * 1000).toInt()),
        isFromMe: m.isMe,
        isRead: true,
      )).toList();
    }
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = SupportMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text,
      timestamp: DateTime.now(),
      isFromMe: true,
      isRead: false,
    );

    update(() {
      messages.insert(0, newMessage);
      messageController.clear();
    });

    _scrollToBottom();
  }

  void attachFile() async {
    NannyDialogs.showMessageBox(
      context,
      'Прикрепление файла',
      'Функция прикрепления файлов будет добавлена в следующей версии',
    );
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

  void dispose() {
    messageController.dispose();
    scrollController.dispose();
  }

  List<SupportMessage> _generateMockMessages() {
    final now = DateTime.now();
    return [
      SupportMessage(
        id: 1,
        text: 'Здравствуйте! Чем могу помочь?',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isFromMe: false,
        isRead: true,
      ),
      SupportMessage(
        id: 2,
        text: 'Добрый день! У меня вопрос по оплате поездки.',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isFromMe: true,
        isRead: true,
      ),
    ];
  }
}
