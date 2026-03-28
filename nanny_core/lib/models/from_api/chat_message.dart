class ChatMessage {
  ChatMessage({
    this.id,
    required this.idChat,
    required this.msg,
    required this.msgType,
    required this.timestampSend,
    this.isMe = false,
    this.edited = false,
  });

  final int? id;
  final int idChat;
  final String msg;
  int msgType;
  final double timestampSend;
  final bool isMe;
  final bool edited;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final timestampSend = (json["timestamp_send"] as num?)?.toDouble() ??
        (() {
          final rawDatetime = json["datetime"]?.toString();
          if (rawDatetime == null || rawDatetime.isEmpty) {
            return 0.0;
          }

          final parsed = DateTime.tryParse(rawDatetime);
          if (parsed == null) {
            return 0.0;
          }

          return parsed.millisecondsSinceEpoch / 1000;
        })();

    final isFromSupport = json["is_from_support"];

    return ChatMessage(
      id: json["id"],
      idChat: json["id_chat"] ?? json["chat_id"] ?? 0,
      msg: json["msg"] ?? json["message"] ?? "",
      msgType: json["msgType"] ?? json["msg_type"] ?? 0,
      timestampSend: timestampSend,
      isMe: json["isMe"] ?? (isFromSupport is bool ? !isFromSupport : false),
      edited: json["edited"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "id_chat": idChat,
        "msg": msg,
        "msgType": msgType,
        "isMe": isMe,
        "edited": edited,
      };

  ChatMessage copyWith({
    int? id,
    int? idChat,
    String? msg,
    int? msgType,
    double? timestampSend,
    bool? isMe,
    bool? edited,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      idChat: idChat ?? this.idChat,
      msg: msg ?? this.msg,
      msgType: msgType ?? this.msgType,
      timestampSend: timestampSend ?? this.timestampSend,
      isMe: isMe ?? this.isMe,
      edited: edited ?? this.edited,
    );
  }
}
