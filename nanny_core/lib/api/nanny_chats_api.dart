import 'package:nanny_core/api/api_models/messages_request.dart';
import 'package:nanny_core/api/api_models/search_query_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/models/from_api/chat.dart';
import 'package:nanny_core/models/from_api/direct_chat.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyChatsApi {
  static Future<ApiResponse<ChatsData>> getChats(SearchQueryRequest request) async {
    return RequestBuilder<ChatsData>().create(
      dioRequest: DioRequest.dio.post("/chats/get_chats", data: request.toJson()),
      onSuccess: (response) => ChatsData.fromJson(response.data),
    );
  }
  static Future<ApiResponse<Chat>> getChat(int id) async {
    var data = <String, dynamic> {
      "id": id,
    };
    return RequestBuilder<Chat>().create(
      dioRequest: DioRequest.dio.post("/chats/get_chat", data: data),
      onSuccess: (response) => Chat.fromJson(response.data),
    );
  }
  static Future<ApiResponse<DirectChat>> getMessages(MessagesRequest request) async {
    return RequestBuilder<DirectChat>().create(
      dioRequest: DioRequest.dio.post("/chats/get_messages", data: request.toJson()),
      onSuccess: (response) => DirectChat.fromJson(response.data),
    );
  }

  // FE-MVP-010: Создание/получение чата с водителем по расписанию
  static Future<ApiResponse<int>> createDriverChat(int scheduleId) async {
    return RequestBuilder<int>().create(
      dioRequest: DioRequest.dio.post("/users/create_driver_chat/$scheduleId"),
      onSuccess: (response) => response.data['chat_id'] as int,
      errorCodeMsgs: {
        404: "Расписание не найдено или водитель еще не назначен",
        403: "Нет доступа к этому расписанию"
      },
    );
  }

  // C-050: Создание/получение чата с техподдержкой
  static Future<ApiResponse<int>> createSupportChat() async {
    return RequestBuilder<int>().create(
      dioRequest: DioRequest.dio.post("/support/create_chat"),
      onSuccess: (response) => response.data['chat_id'] as int,
      errorCodeMsgs: {
        500: "Не удалось создать чат с поддержкой",
      },
    );
  }

  // C-050: Получение истории чата с техподдержкой
  static Future<ApiResponse<DirectChat>> getSupportMessages({
    int? lastMessageId,
    int limit = 50,
  }) async {
    return RequestBuilder<DirectChat>().create(
      dioRequest: DioRequest.dio.get(
        "/support/messages",
        queryParameters: {
          if (lastMessageId != null) 'last_id': lastMessageId,
          'limit': limit,
        },
      ),
      onSuccess: (response) => DirectChat.fromJson(response.data),
    );
  }
}