import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/view_model_base.dart';
import 'package:nanny_core/api/api_models/messages_request.dart';
import 'package:nanny_core/api/web_sockets/nanny_web_socket.dart';
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
  NannyWebSocket get chat => NannyGlobals.chatsSocket;

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
  late final StreamSubscription sub;

  // Инициализация
  Future<ApiResponse<DirectChat>> _initDirect() async {
    sub = chat.stream.listen(chatStreamCallback);
    return loadMessages();
  }

  // Загрузка сообщений
  Future<ApiResponse<DirectChat>> loadMessages() async {
    if (isLoadingMore || !hasMoreMessages) return ApiResponse.empty();

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
        messages!.addAll(newMessages);
        offset += newMessages.length;
      }
    }

    isLoadingMore = false;
    update(() {});
    return response;
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
  void sendTextMessage() {
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

    _sendMessage(message);

    textController.clear();
    editingMessageId = null;
    isEditingMode = false;
  }

  // Отправка сообщения
  void _sendMessage(ChatMessage msg) {
    print(jsonEncode(msg));
    chat.sink.add(jsonEncode(msg));
  }

  // Прикрепление изображения
  void attachImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickMedia();

    if (file == null || !context.mounted) return;

    LoadScreen.showLoad(context, true);
    var fileUpload = await NannyFilesApi.uploadFiles([file]);

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (!fileUpload.success) return;

    _sendMessage(ChatMessage(
      idChat: idChat,
      msg: fileUpload.response!.paths.first,
      msgType: fileUpload.response!.types.first,
      timestampSend: 0
    ));
  }

  // Обработка входящих сообщений
  void chatStreamCallback(dynamic data) {
    Map<String, dynamic> json = jsonDecode(data);
    // Служебные события (отклики водителей и т.п.) не парсить как сообщения чата
    if (json['event'] == 'schedule_responses_updated') return;
    ChatMessage msg = ChatMessage.fromJson(json);

    final existingMessageIndex = messages?.indexWhere((m) => m.id == msg.id);
    if (existingMessageIndex != null && existingMessageIndex != -1) {
      // Обновить существующее сообщение
      messages?[existingMessageIndex] = msg;
    } else {
      // Добавить новое сообщение
      messages?.insert(0, msg);
    }

    update(() {});
  }

  // Очистка ресурсов
  void dispose() {
    sub.cancel();
    scrollController.dispose();
    textController.dispose();
  }
}
