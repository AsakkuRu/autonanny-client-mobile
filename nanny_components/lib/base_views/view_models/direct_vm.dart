import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/messages_request.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/models/from_api/chat_message.dart';
import 'package:nanny_core/models/from_api/direct_chat.dart';
import 'package:nanny_core/nanny_core.dart';

class DirectVM extends ViewModelBase {
  DirectVM({
    required super.context,
    required super.update,
    required this.idChat,
  }) {
    messagesRequest = _initDirect();
  }

  // Chat Info
  final int idChat;
  UnifiedSocket? _socket;

  // Controllers
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // State Variables
  bool loading = false;
  bool isLoadingMore = false;
  bool hasMoreMessages = true;
  bool isEditingMode = false;
  int offset = 0;
  int? editingMessageId; // ID редактируемого сообщения
  static const int limit = 15;

  late Future<ApiResponse<DirectChat>> messagesRequest;
  List<ChatMessage>? messages;

  // Stream Subscription
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _editedSub;
  StreamSubscription<Map<String, dynamic>>? _connectedSub;
  bool _syncingReadState = false;
  bool _reloadingFromRealtime = false;

  // Инициализация
  Future<ApiResponse<DirectChat>> _initDirect() async {
    await _bindRealtime();
    unawaited(_syncReadState());
    return loadMessages();
  }

  Future<void> _bindRealtime() async {
    await _messageSub?.cancel();
    await _editedSub?.cancel();
    await _connectedSub?.cancel();
    _socket = UnifiedSocket.instance ?? await UnifiedSocket.connect();
    _messageSub =
        _socket?.on('chat.message_created').listen(chatStreamCallback);
    _editedSub = _socket?.on('chat.message_edited').listen(chatStreamCallback);
    _connectedSub = _socket?.on('connected').listen((_) {
      unawaited(_refreshMessagesFromRealtime());
    });
  }

  // Загрузка сообщений
  Future<ApiResponse<DirectChat>> loadMessages() async {
    return _loadMessages(reset: false);
  }

  Future<ApiResponse<DirectChat>> reloadMessages() async {
    return _loadMessages(reset: true);
  }

  Future<ApiResponse<DirectChat>> _loadMessages({required bool reset}) async {
    if (isLoadingMore) return ApiResponse.empty();
    if (!reset && !hasMoreMessages) return ApiResponse.empty();

    if (reset) {
      hasMoreMessages = true;
      offset = 0;
      messages = <ChatMessage>[];
    }

    isLoadingMore = true;
    update(() {});

    final response = await NannyChatsApi.getMessages(
      MessagesRequest(idChat: idChat, offset: offset, limit: limit),
    );

    if (response.success) {
      final newMessages = response.response?.messages ?? [];
      if (newMessages.isEmpty) {
        hasMoreMessages = false;
      } else {
        messages ??= [];
        final existingIds =
            messages!.map((message) => message.id).whereType<int>().toSet();
        final uniqueNewMessages = newMessages
            .where(
              (message) =>
                  message.id == null || !existingIds.contains(message.id),
            )
            .toList(growable: false);
        messages!.addAll(uniqueNewMessages);
        offset += newMessages.length;
      }
    }

    isLoadingMore = false;
    update(() {});
    return response;
  }

  Future<void> _refreshMessagesFromRealtime() async {
    if (_reloadingFromRealtime || isLoadingMore) {
      return;
    }
    _reloadingFromRealtime = true;
    try {
      if (messages == null) {
        messagesRequest = reloadMessages();
        update(() {});
        await messagesRequest;
      } else {
        await reloadMessages();
      }
      await _syncReadState();
    } finally {
      _reloadingFromRealtime = false;
    }
  }

  Future<void> _syncReadState() async {
    if (_syncingReadState) return;
    _syncingReadState = true;
    try {
      await NannyChatsApi.markChatRead(idChat);
      NannyGlobals.chatUnreadRefreshController.add(null);
    } finally {
      _syncingReadState = false;
    }
  }

  // Переключение режима редактирования
  void toggleEditingMode() {
    isEditingMode = !isEditingMode;
    update(() {});
  }

  // Начать редактирование сообщения
  void startEditingMessage(ChatMessage message) {
    textController.text = message.msg;
    editingMessageId = message.id;
    update(() {});
  }

  // Отправка текстового сообщения
  Future<void> sendTextMessage() async {
    if (textController.text.trim().isEmpty) return;

    // FE-MVP-024: Фильтрация нецензурных слов
    final checkResult = ProfanityFilter.checkText(textController.text);

    // Если обнаружена нецензурная лексика, показываем предупреждение
    if (checkResult.hasProfanity) {
      NannyDialogs.showMessageBox(
        context,
        'Внимание',
        'Ваше сообщение содержит недопустимые слова. Они будут заменены на "***".',
      );
    }

    final message = ChatMessage(
        id: editingMessageId,
        idChat: idChat,
        msg: checkResult.filteredText, // Используем отфильтрованный текст
        msgType: 1,
        timestampSend: 0,
        isMe: true);

    final sent = await _sendMessage(message);
    if (!sent) {
      return;
    }

    textController.clear();
    editingMessageId = null;
    isEditingMode = false;
  }

  // Отправка сообщения
  Future<bool> _sendMessage(ChatMessage msg) async {
    ApiResponse<Map<String, dynamic>> result;
    if (msg.id != null) {
      result = await NannyChatsApi.editMessage(
        chatId: msg.idChat,
        messageId: msg.id!,
        text: msg.msg,
      );
    } else {
      result = await NannyChatsApi.sendMessage(
        chatId: msg.idChat,
        text: msg.msg,
        msgType: msg.msgType,
      );
    }

    if (!result.success) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(
          context,
          'Не удалось отправить сообщение',
          result.errorMessage.isNotEmpty
              ? result.errorMessage
              : 'Проверьте подключение к интернету и попробуйте еще раз.',
        );
      }
      return false;
    }

    NannyGlobals.chatUnreadRefreshController.add(null);
    return true;
  }

  // Прикрепление изображения
  Future<void> attachImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickMedia();

    if (file == null || !context.mounted) return;

    LoadScreen.showLoad(context, true);
    var fileUpload = await NannyFilesApi.uploadFiles([file]);

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (!fileUpload.success) {
      NannyDialogs.showMessageBox(
        context,
        'Не удалось загрузить файл',
        fileUpload.errorMessage.isNotEmpty
            ? fileUpload.errorMessage
            : 'Проверьте подключение к интернету и попробуйте еще раз.',
      );
      return;
    }

    await _sendMessage(ChatMessage(
      idChat: idChat,
      msg: fileUpload.response!.paths.first,
      msgType: fileUpload.response!.types.first,
      timestampSend: 0,
    ));
  }

  // Обработка входящих сообщений
  void chatStreamCallback(Map<String, dynamic> data) {
    final event = data['event']?.toString();
    final payload = data['data'];
    if (payload is! Map) return;

    final chatIdRaw = payload['chat_id'];
    final chatId = chatIdRaw is int ? chatIdRaw : int.tryParse('$chatIdRaw');
    if (chatId != idChat) return;

    if (event == 'chat.message_edited') {
      final editedMessageIdRaw = payload['message_id'];
      final editedMessageId = editedMessageIdRaw is int
          ? editedMessageIdRaw
          : int.tryParse('$editedMessageIdRaw');
      if (editedMessageId == null) return;

      final editedIndex =
          messages?.indexWhere((m) => m.id == editedMessageId) ?? -1;
      if (editedIndex == -1) {
        unawaited(reloadMessages());
        return;
      }

      messages?[editedIndex] = messages![editedIndex].copyWith(
        msg: payload['text']?.toString() ?? messages![editedIndex].msg,
        edited: true,
      );
      update(() {});
      return;
    }

    final messageIdRaw = payload['message_id'];
    final messageId =
        messageIdRaw is int ? messageIdRaw : int.tryParse('$messageIdRaw');
    final msgTypeRaw = payload['msg_type'];
    final msgType =
        msgTypeRaw is int ? msgTypeRaw : int.tryParse('$msgTypeRaw') ?? 0;
    final ts = (payload['ts'] as num?)?.toDouble() ?? 0;
    final senderIdRaw = payload['sender_id'];
    final senderId =
        senderIdRaw is int ? senderIdRaw : int.tryParse('$senderIdRaw');

    final msg = ChatMessage(
      id: messageId,
      idChat: chatId ?? 0,
      msg: payload['text']?.toString() ?? '',
      msgType: msgType,
      timestampSend: ts,
      isMe: payload['is_me'] == true || senderId == NannyUser.userInfo?.id,
    );

    final existingMessageIndex = messages?.indexWhere((m) => m.id == msg.id);
    if (existingMessageIndex != null && existingMessageIndex != -1) {
      // Обновить существующее сообщение
      messages?[existingMessageIndex] = msg;
    } else {
      // Добавить новое сообщение
      messages ??= [];
      messages?.insert(0, msg);
    }

    if (!msg.isMe) {
      unawaited(_syncReadState());
    }

    update(() {});
  }

  // Очистка ресурсов
  void dispose() {
    _messageSub?.cancel();
    _editedSub?.cancel();
    _connectedSub?.cancel();
    scrollController.dispose();
    textController.dispose();
  }
}
