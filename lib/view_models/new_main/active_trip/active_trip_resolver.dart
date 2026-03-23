import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';

class ActiveTripResolver {
  static Future<ActiveTripSessionData?> resolveCurrentActiveTrip() async {
    final cached = await ActiveTripSessionStore.load();
    final res = await NannyOrdersApi.getCurrentOrder();

    if (!res.success || res.response == null) {
      return cached;
    }

    final body = res.response!.data;
    final activeOrder = _selectActiveOrder(
      body is Map ? body['orders'] : null,
      preferredToken: cached?.token,
      preferredOrderId: cached?.orderId,
    );

    if (activeOrder == null) {
      await ActiveTripSessionStore.clear();
      return null;
    }

    final token = activeOrder['token']?.toString();
    if (token == null || token.isEmpty) {
      await ActiveTripSessionStore.clear();
      return null;
    }

    final session = ActiveTripSessionData(
      token: token,
      orderId: _toInt(activeOrder['id_order']),
      statusId: _toInt(activeOrder['id_status']),
      chatId: _toInt(activeOrder['id_chat']),
    );
    await ActiveTripSessionStore.save(session);
    return session;
  }

  static Map<String, dynamic>? _selectActiveOrder(
    dynamic rawOrders, {
    String? preferredToken,
    int? preferredOrderId,
  }) {
    if (rawOrders is! List) return null;

    final activeOrders = rawOrders.whereType<Map>().map((raw) {
      return Map<String, dynamic>.from(raw);
    }).where((order) {
      final statusId = _toInt(order['id_status']);
      return statusId != null &&
          statusId != 2 &&
          statusId != 3 &&
          statusId != 11;
    }).toList(growable: false);

    if (activeOrders.isEmpty) return null;

    if (preferredOrderId != null) {
      for (final order in activeOrders) {
        if (_toInt(order['id_order']) == preferredOrderId) {
          return order;
        }
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

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
