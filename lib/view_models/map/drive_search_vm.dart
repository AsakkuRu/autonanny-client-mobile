import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nanny_client/views/rating/driver_rating_view.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/api/web_sockets/drive_search_socket.dart';
import 'package:nanny_core/api/web_sockets/nanny_web_socket.dart';
import 'package:nanny_core/models/from_api/drive_and_map/tariff_alternative.dart';
import 'package:nanny_core/nanny_core.dart';

export 'package:nanny_core/models/from_api/drive_and_map/tariff_alternative.dart';

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

  // TASK-C6: Альтернативные тарифы при отсутствии водителей
  List<TariffAlternative> alternatives = [];
  bool showAlternatives = false;
  bool isSwitchingTariff = false;

  // TASK-B11: Срочный заказ «На замену»
  bool isUrgentReplacement = false;
  double? urgentMultiplier;
  String? urgentReason;

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
      final decoded = rawEvent is String ? jsonDecode(rawEvent) : rawEvent;
      if (decoded is! Map) return;
      final Map<String, dynamic> data =
          decoded.map((key, value) => MapEntry(key.toString(), value));

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
            _showRatingScreen();
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

      // TASK-C6: Нет водителей — предлагаем альтернативы
      if (data['type'] == 'no_drivers_found' && data.containsKey('alternatives')) {
        _handleNoDriversFound(data);
      }

      // TASK-B11: Срочный заказ — назначен водитель «на замену»
      if (data['is_urgent'] == true) {
        isUrgentReplacement = true;
        urgentMultiplier = (data['urgent_multiplier'] as num?)?.toDouble() ?? 1.5;
        urgentReason = data['urgent_reason'] as String? ?? 'Назначен водитель на замену';
        statusText = 'Назначен водитель на замену (срочно)';
      }

      update(() {});
    } catch (e) {
      Logger().e('DriveSearch parse error: $e');
    }
  }

  // TASK-C6: Обработка отсутствия водителей
  void _handleNoDriversFound(Map<String, dynamic> data) {
    final rawAlternatives = data['alternatives'] as List<dynamic>? ?? [];
    alternatives = rawAlternatives
        .map((e) => TariffAlternative.fromJson(e as Map<String, dynamic>))
        .toList();

    if (alternatives.isNotEmpty) {
      showAlternatives = true;
    }
  }

  Future<void> switchTariff(TariffAlternative alt) async {
    if (orderId == null) return;

    update(() => isSwitchingTariff = true);

    // Mock-first: если API недоступен — эмулируем смену
    final result = await NannyOrdersApi.changeTariff(
      orderId: orderId!,
      newTariffId: alt.tariffId,
    );

    update(() {
      isSwitchingTariff = false;
      showAlternatives = false;
      alternatives = [];
      statusText = 'Поиск водителя класса "${alt.tariffName}"...';
      isSearching = true;
    });

    if (!result.success) {
      // Mock-first: продолжаем поиск даже без реального API
      Logger().w('changeTariff API not available, continuing with mock');
    }
  }

  void dismissAlternatives() {
    update(() => showAlternatives = false);
  }

  void _showRatingScreen() {
    if (orderId == null) return;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverRatingView(
            orderId: orderId!,
          ),
        ),
      );
    });
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
