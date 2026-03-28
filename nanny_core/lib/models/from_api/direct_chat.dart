import 'package:nanny_core/models/from_api/chat_message.dart';

class DirectChat {
  DirectChat({
    required this.idChat,
    required this.messages,
    required this.total,
  });

  final int idChat;
  final List<ChatMessage> messages;
  final int total;

  factory DirectChat.fromJson(Map<String, dynamic> json) {
    return DirectChat(
      idChat: json["id_chat"] ?? json["chat_id"] ?? 0,
      messages: json["messages"] == null
          ? []
          : List<ChatMessage>.from(
              json["messages"]!.map((x) => ChatMessage.fromJson(x))),
      total: json["total"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        "id_chat": idChat,
        "messages": messages.map((x) => x.toJson()).toList(),
        "total": total,
      };
}

/*
{
	"id_chat": 1,
	"messages": [
		{
			"msg": "string",
			"msgType": 0,
			"timestamp_send": 0,
			"isMe": true
		}
	],
	"total": 0
}*/
