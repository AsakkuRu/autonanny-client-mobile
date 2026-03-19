import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_core/api/web_sockets/nanny_web_socket.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyGlobals {
  static DateTime? lastSmsSend;
  static late String phone;

  static NannyWebSocket chatsSocket = ChatsSocket();
  static Future<void> initChatSocket() async => chatsSocket = await chatsSocket.connect();
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static BuildContext get currentContext => navKey.currentContext!;

  /// Событие переключения на вкладку «Расписание». Вызывать при выборе этой вкладки.
  static final StreamController<void> scheduleTabSelectedController =
      StreamController<void>.broadcast();
}