import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/views/driver_info.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/search_query_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/nanny_core.dart';

class ChatsVM extends ViewModelBase {
  ChatsVM({
    required super.context,
    required super.update,
    this.updateList,
    this.onReturnFromChat,
  }) {
    sub = NannyGlobals.chatsSocket.stream.listen((msg) => updateList?.call());
  }

  FocusNode node = FocusNode();
  VoidCallback? updateList;
  /// Вызывается после возврата из чата (для сброса бейджа непрочитанных в нижнем баре)
  VoidCallback? onReturnFromChat;
  bool chatsSelected = false;
  String query = "";

  late StreamSubscription sub;

  void chatsSwitch({required bool switchToChats}) => update(() {
        chatsSelected = switchToChats;
        if (node.hasFocus) node.unfocus();
      });

  Future<ApiResponse<ChatsData>> get getChats async =>
      NannyChatsApi.getChats(SearchQueryRequest(
        search: query,
      ));

  Future<ApiResponse<List<ScheduleResponsesData>>> get getRequests async {
    var result = await NannyOrdersApi.getScheduleResponses();

    if (!result.success) return result;

    for (var data in result.response!) {
      var sched = await NannyOrdersApi.getScheduleById(data.idSchedule);
      data.schedule = sched.response;
    }

    return result;
  }

  void chatSearch(String text) {
    query = text;
    updateList?.call();
  }

  void navigateToDirect(ChatElement chat) async {
    await navigateToView(DirectView(idChat: chat.idChat, name: chat.username));
    onReturnFromChat?.call();
    updateList?.call();
  }

  void dispose() {
    sub.cancel();
  }

  void checkScheduleRequest(ScheduleResponsesData data) async {
    await navigateToView(DriverInfoView(
      id: data.idDriver,
      viewingOrder: true,
      scheduleData: data,
    ));

    update(() {});
  }
}
