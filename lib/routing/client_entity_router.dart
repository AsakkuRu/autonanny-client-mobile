import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_resolver.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
import 'package:nanny_client/views/notifications/notification_center_view.dart';
import 'package:nanny_client/views/pages/balance.dart';
import 'package:nanny_client/views/pages/contracts_view.dart';
import 'package:nanny_client/views/pages/transactions/transactions_history_view.dart';
import 'package:nanny_client/views/rating/driver_rating_view.dart';
import 'package:nanny_client/views/support/faq_view.dart';
import 'package:nanny_client/views/support/support_chat_view.dart';
import 'package:nanny_components/base_views/views/direct.dart';

class ContractsRouteArgs {
  const ContractsRouteArgs({
    this.contractId,
    this.openInitialContractDetails = false,
  });

  final int? contractId;
  final bool openInitialContractDetails;
}

class ClientEntityRouter {
  static const String notificationsRoute = '/notifications';
  static const String contractsRoute = '/contracts';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case notificationsRoute:
        return MaterialPageRoute<void>(
          builder: (_) => const NotificationCenterView(),
          settings: settings,
        );
      case contractsRoute:
        final args = settings.arguments is ContractsRouteArgs
            ? settings.arguments as ContractsRouteArgs
            : const ContractsRouteArgs();
        return MaterialPageRoute<void>(
          builder: (_) => ContractsView(
            persistState: false,
            initialContractId: args.contractId,
            openInitialContractDetails: args.openInitialContractDetails,
          ),
          settings: settings,
        );
      default:
        return null;
    }
  }

  static Future<void> openContracts(
    BuildContext context, {
    int? contractId,
  }) {
    return Navigator.of(context).pushNamed(
      contractsRoute,
      arguments: ContractsRouteArgs(contractId: contractId),
    );
  }

  static Future<void> openContractDetails(
    BuildContext context, {
    int? contractId,
  }) {
    return Navigator.of(context).pushNamed(
      contractsRoute,
      arguments: ContractsRouteArgs(
        contractId: contractId,
        openInitialContractDetails: contractId != null,
      ),
    );
  }

  static Future<bool> openEntity(
    BuildContext context, {
    Map<String, dynamic>? payload,
    String? target,
    String? type,
  }) async {
    final safePayload = payload ?? const <String, dynamic>{};
    final resolvedTarget = normalizeTarget(
      target ?? safePayload['target']?.toString(),
      type: type,
    );
    final contractId = readContractId(safePayload);
    final orderId = readInt(
      safePayload['order_id'] ?? safePayload['id_order'],
    );
    final chatId = readInt(
      safePayload['chat_id'] ?? safePayload['id_chat'] ?? safePayload['id'],
    );

    if ((type == 'weekly_payment_failed' ||
            type == 'contract_resumed' ||
            type == 'contract_suspended') &&
        contractId != null) {
      await openContractDetails(context, contractId: contractId);
      return true;
    }

    switch (resolvedTarget) {
      case 'contract':
        await openContractDetails(context, contractId: contractId);
        return true;
      case 'contract_schedule':
        await openContracts(context, contractId: contractId);
        return true;
      case 'trip':
        return _openActiveTrip(context, orderId);
      case 'wallet_operation':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionsHistoryView(
              initialTransactionType:
                  safePayload['transaction_type']?.toString() ?? 'payment',
              initialSearchQuery: buildWalletSearchQuery(
                contractId: contractId,
                orderId: orderId,
                explicitSearchQuery: safePayload['search_query']?.toString(),
              ),
            ),
          ),
        );
        return true;
      case 'chat':
        if (chatId == null) {
          return false;
        }
        if (DirectView.activeChatId == chatId) {
          return true;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DirectView(
              idChat: chatId,
              name: resolveChatDisplayName(safePayload),
            ),
          ),
        );
        return true;
      case 'rating_request':
        if (orderId == null) {
          return false;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DriverRatingView(
              orderId: orderId,
              driverName: safePayload['driver_name']?.toString(),
              driverPhoto: safePayload['driver_photo']?.toString(),
            ),
          ),
        );
        return true;
      case 'balance':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BalanceView(persistState: false),
          ),
        );
        return true;
      case 'support_chat':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SupportChatView(),
          ),
        );
        return true;
      case 'faq':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FaqView(),
          ),
        );
        return true;
      default:
        return false;
    }
  }

  static Future<bool> handleUri(BuildContext context, Uri uri) async {
    final params = uri.queryParameters.map(
      (key, value) => MapEntry(key, value),
    );
    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    final isWebLikeScheme = uri.scheme == 'http' || uri.scheme == 'https';
    final hasHostEntity = !isWebLikeScheme && uri.host.isNotEmpty;
    if (!hasHostEntity && segments.isEmpty) {
      return false;
    }

    final entity = (hasHostEntity ? uri.host : segments.first).toLowerCase();
    final idFromPath = hasHostEntity
        ? (segments.isNotEmpty ? segments.first : null)
        : (segments.length > 1 ? segments[1] : null);

    switch (entity) {
      case 'contract':
      case 'contracts':
        return openEntity(
          context,
          payload: {
            ...params,
            'contract_id':
                params['contract_id'] ?? params['schedule_id'] ?? idFromPath,
          },
          target: 'contract',
          type: params['type'],
        );
      case 'contract_schedule':
        return openEntity(
          context,
          payload: {
            ...params,
            'contract_id':
                params['contract_id'] ?? params['schedule_id'] ?? idFromPath,
          },
          target: 'contract_schedule',
          type: params['type'],
        );
      case 'trip':
      case 'active_trip':
        return openEntity(
          context,
          payload: {
            ...params,
            'order_id': params['order_id'] ?? idFromPath,
          },
          target: 'trip',
          type: params['type'],
        );
      case 'chat':
        return openEntity(
          context,
          payload: {
            ...params,
            'chat_id': params['chat_id'] ?? idFromPath,
          },
          target: 'chat',
          type: params['type'],
        );
      case 'wallet_operation':
        return openEntity(
          context,
          payload: {
            ...params,
            'contract_id': params['contract_id'] ?? params['schedule_id'],
            'order_id': params['order_id'],
            'search_query': params['search_query'],
            'transaction_type': params['transaction_type'],
          },
          target: 'wallet_operation',
          type: params['type'],
        );
      case 'rating_request':
        return openEntity(
          context,
          payload: {
            ...params,
            'order_id': params['order_id'] ?? idFromPath,
            'driver_name': params['driver_name'],
            'driver_photo': params['driver_photo'],
          },
          target: 'rating_request',
          type: params['type'],
        );
      case 'balance':
        return openEntity(
          context,
          payload: params,
          target: 'balance',
          type: params['type'],
        );
      default:
        return false;
    }
  }

  static String? normalizeTarget(String? target, {String? type}) {
    switch (target) {
      case 'contract':
        return 'contract';
      case 'contract_schedule':
        return 'contract_schedule';
      case 'contracts':
        return 'contract';
      case 'trip':
      case 'active_trip':
        return 'trip';
      case 'chat':
        return 'chat';
      case 'wallet_operation':
        return 'wallet_operation';
      case 'rating_request':
        return 'rating_request';
      case 'balance':
        return 'balance';
      case 'support_chat':
        return 'support_chat';
      case 'faq':
        return 'faq';
      default:
        return fallbackTarget(type);
    }
  }

  static String? fallbackTarget(String? type) {
    switch (type) {
      case 'payment':
      case 'weekly_payment_success':
      case 'weekly_payment_failed':
        return 'wallet_operation';
      case 'message':
      case 'chat.message_created':
      case 'new_chat':
        return 'chat';
      case 'order':
      case 'trip_status':
      case 'trip_status_update':
      case 'active_trip':
      case 'trip.assigned':
      case 'trip.cancelled':
      case 'order.expired':
      case 'route.change_requested':
      case 'route.change_result':
      case 'route_deviation':
        return 'trip';
      case 'contract_resumed':
      case 'contract_suspended':
        return 'contract';
      case 'rating_request':
        return 'rating_request';
      case 'trip':
        return 'trip';
      default:
        return null;
    }
  }

  static int? readContractId(Map<String, dynamic> payload) {
    return readInt(
      payload['contract_id'] ??
          payload['schedule_id'] ??
          payload['id_schedule'],
    );
  }

  static String? resolveChatDisplayName(Map<String, dynamic> payload) {
    for (final rawValue in [
      payload['chat_name'],
      payload['driver_name'],
      payload['client_name'],
      payload['username'],
      payload['name'],
    ]) {
      final value = rawValue?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static int? readInt(dynamic rawValue) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is String) {
      return int.tryParse(rawValue);
    }
    return null;
  }

  static String? buildWalletSearchQuery({
    required int? contractId,
    required int? orderId,
    String? explicitSearchQuery,
  }) {
    if (explicitSearchQuery != null && explicitSearchQuery.isNotEmpty) {
      return explicitSearchQuery;
    }
    if (orderId != null) {
      return '#$orderId';
    }
    if (contractId != null) {
      return '#$contractId';
    }
    return null;
  }

  static Future<bool> _openActiveTrip(
    BuildContext context,
    int? expectedOrderId,
  ) async {
    final activeTrip = await ActiveTripResolver.resolveCurrentActiveTrip();
    if (!context.mounted) {
      return false;
    }
    if (activeTrip == null || activeTrip.token.isEmpty) {
      _showInfoMessage(
          context, 'Активная поездка уже завершена или недоступна.');
      return true;
    }
    if (expectedOrderId != null &&
        activeTrip.orderId != null &&
        activeTrip.orderId != expectedOrderId) {
      _showInfoMessage(
        context,
        'Эта поездка уже завершена или больше не активна.',
      );
      return true;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveTripScreen(token: activeTrip.token),
      ),
    );
    return true;
  }

  static void _showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
