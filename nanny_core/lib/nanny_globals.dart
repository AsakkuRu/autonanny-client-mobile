import 'dart:async';

import 'package:flutter/material.dart';

class NannyGlobals {
  static DateTime? lastSmsSend;
  static late String phone;

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static BuildContext get currentContext => navKey.currentContext!;

  /// Событие переключения на вкладку «Расписание». Вызывать при выборе этой вкладки.
  static final StreamController<void> scheduleTabSelectedController =
      StreamController<void>.broadcast();
}
