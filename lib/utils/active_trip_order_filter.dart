/// Чистая логика выбора «текущего» заказа для баннера активной поездки (unit-тестируемая).

Map<String, dynamic>? selectActiveOrderFromList(
  dynamic rawOrders, {
  String? preferredToken,
  int? preferredOrderId,
}) {
  if (rawOrders is! List) return null;

  int? toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  final activeOrders = rawOrders.whereType<Map>().map((raw) {
    return Map<String, dynamic>.from(raw);
  }).where((order) {
    final statusId = toInt(order['id_status']);
    return statusId != null &&
        statusId != 2 &&
        statusId != 3 &&
        statusId != 11;
  }).toList(growable: false);

  if (activeOrders.isEmpty) return null;

  if (preferredOrderId != null) {
    for (final order in activeOrders) {
      if (toInt(order['id_order']) == preferredOrderId) return order;
    }
  }

  if (preferredToken != null && preferredToken.isNotEmpty) {
    for (final order in activeOrders) {
      final orderToken = order['token']?.toString();
      if (orderToken != null &&
          orderToken.isNotEmpty &&
          orderToken == preferredToken) {
        return order;
      }
    }
  }

  return activeOrders.first;
}

/// События realtime, при которых не показываем баннер по token из пейлоада до refetch.
bool isTerminalTripInvalidationEvent(String? event) {
  return event == 'trip.cancelled' || event == 'order.expired';
}
