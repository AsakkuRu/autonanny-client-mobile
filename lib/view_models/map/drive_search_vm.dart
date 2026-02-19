import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/web_sockets/drive_search_socket.dart';
import 'package:nanny_core/api/web_sockets/nanny_web_socket.dart';
import 'package:nanny_core/nanny_core.dart';

class DriveSearchVM extends ViewModelBase {
  DriveSearchVM({
    required super.context,
    required super.update,
    required this.token,
  });

  final String token;
  late final NannyWebSocket socket;
  StreamSubscription? _subscription;

  // Состояние поиска
  String statusText = 'Поиск водителя...';
  bool isSearching = true;
  bool driverFound = false;
  int? orderId;
  int? driverId;
  int? chatId;
  Map<String, dynamic>? driverLocation;

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    socket.dispose();
  }

  void cancelSearch() {
    socket.send(jsonEncode({'status': 3}));
    Navigator.pop(context);
  }

  void _handleMessage(dynamic rawEvent) {
    try {
      final data = rawEvent is String ? jsonDecode(rawEvent) : rawEvent;
      if (data is! Map) return;

      Logger().i('DriveSearch event: $data');

      // Заказ создан — получаем order_id
      if (data.containsKey('order_id')) {
        orderId = data['order_id'];
      }

      // Водитель найден (статус 13)
      if (data.containsKey('id_status') && data['id_status'] == 13) {
        driverId = data['id_driver'];
        driverFound = true;
        isSearching = false;
        statusText = 'Водитель найден! Ожидайте прибытия.';
      }

      // Чат создан
      if (data.containsKey('id_chat')) {
        chatId = data['id_chat'];
      }

      // Обновление координат водителя
      if (data.containsKey('lat') && data.containsKey('lon')) {
        driverLocation = {
          'lat': data['lat'],
          'lon': data['lon'],
          if (data.containsKey('duration')) 'duration': data['duration'],
        };
      }

      // Обновление статуса заказа
      if (data.containsKey('status') && data['status'] is int) {
        final status = data['status'] as int;
        switch (status) {
          case 2:
            statusText = 'Водитель отменил заказ. Ищем другого...';
            driverFound = false;
            isSearching = true;
            break;
          case 3:
            statusText = 'Заказ отменён';
            isSearching = false;
            break;
          case 5:
            statusText = 'Водитель в пути к вам';
            break;
          case 7:
            statusText = 'Водитель на месте';
            break;
          case 11:
            statusText = 'Поездка завершена';
            isSearching = false;
            break;
          case 13:
            statusText = 'Водитель найден!';
            driverFound = true;
            isSearching = false;
            break;
          case 14:
            statusText = 'Поездка началась';
            break;
          case 15:
            statusText = 'Водитель прибыл на конечную точку';
            break;
        }
      }

      // Информация о заказе
      if (data.containsKey('order') && data['order'] is Map) {
        orderId = data['order']['id'];
      }

      // Сообщение об отмене
      if (data.containsKey('message') && data['message'] == 'Order cancelled') {
        statusText = 'Заказ отменён';
        isSearching = false;
      }

      update(() {});
    } catch (e) {
      Logger().e('DriveSearch parse error: $e');
    }
  }

  @override
  Future<bool> loadPage() async {
    socket = await DriveSearchSocket(token).connect();
    Logger().i('Driver search connected with token $token');

    _subscription = socket.stream.listen(
      _handleMessage,
      onError: (error) {
        Logger().e('DriveSearch socket error: $error');
        statusText = 'Ошибка подключения';
        isSearching = false;
        update(() {});
      },
      onDone: () {
        Logger().w('DriveSearch socket closed');
        if (isSearching) {
          statusText = 'Соединение потеряно';
          isSearching = false;
          update(() {});
        }
      },
    );

    return true;
  }
}
