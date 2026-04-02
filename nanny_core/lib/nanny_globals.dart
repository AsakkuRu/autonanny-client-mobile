import 'dart:async';

import 'package:flutter/material.dart';

class NannyGlobals {
  static DateTime? lastSmsSend;
  static late String phone;

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static BuildContext get currentContext => navKey.currentContext!;

  /// Событие переключения на вкладку «Расписание». Вызывать при выборе этой вкладки.
  static final StreamController<void> scheduleTabSelectedController =
      StreamController<void>.broadcast();

  /// Локальный сигнал для refresh unread-бейджей после read-sync в чате.
  static final StreamController<void> chatUnreadRefreshController =
      StreamController<void>.broadcast();

  /// Обновить краткий список детей на главном экране («Кто едет») после возврата
  /// с другой вкладки — данные могли измениться в профиле.
  static final StreamController<void> mainScreenChildrenRefreshController =
      StreamController<void>.broadcast();
}
