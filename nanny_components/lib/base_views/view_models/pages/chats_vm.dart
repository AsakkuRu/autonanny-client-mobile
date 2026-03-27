import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/views/driver_info.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/search_query_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/nanny_core.dart';

class ChatsVM extends ViewModelBase {
  ChatsVM({
    required super.context,
    required super.update,
    this.updateList,
    this.onReturnFromChat,
    this.buildDriverRatingView,
  }) {
    unawaited(_bindRealtimeUpdates());
  }

  FocusNode node = FocusNode();
  VoidCallback? updateList;

  /// Вызывается после возврата из чата (для сброса бейджа непрочитанных в нижнем баре)
  VoidCallback? onReturnFromChat;
  Widget Function(int driverId)? buildDriverRatingView;
  bool chatsSelected = false;
  String query = "";

  StreamSubscription<Map<String, dynamic>>? sub;
  StreamSubscription<void>? _localRefreshSub;
  bool _refreshingFromRealtime = false;

  Future<void> _bindRealtimeUpdates() async {
    await sub?.cancel();
    await _localRefreshSub?.cancel();
    final socket = UnifiedSocket.instance ?? await UnifiedSocket.connect();
    sub = socket.events.listen((msg) {
      final event = msg['event']?.toString();
      if (event == 'connected') {
        unawaited(_refreshFromRealtime());
        return;
      }
      if (event == 'chat.message_created' ||
          event == 'chat.message_edited' ||
          event == 'chat.unread_changed' ||
          event == 'contract.responses.updated') {
        updateList?.call();
      }
    });
    _localRefreshSub =
        NannyGlobals.chatUnreadRefreshController.stream.listen((_) {
      updateList?.call();
    });
  }

  Future<void> _refreshFromRealtime() async {
    if (_refreshingFromRealtime) return;
    _refreshingFromRealtime = true;
    try {
      updateList?.call();
    } finally {
      _refreshingFromRealtime = false;
    }
  }

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
    sub?.cancel();
    _localRefreshSub?.cancel();
  }

  void checkScheduleRequest(ScheduleResponsesData data) async {
    await navigateToView(DriverInfoView(
      id: data.idDriver,
      viewingOrder: true,
      scheduleData: data,
      onOpenRating: buildDriverRatingView == null
          ? null
          : () => navigateToView(buildDriverRatingView!(data.idDriver)),
    ));

    update(() {});
  }
}
