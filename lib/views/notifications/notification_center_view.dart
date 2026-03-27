import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_resolver.dart';
import 'package:nanny_client/view_models/notifications/notification_center_vm.dart';
import 'package:nanny_components/base_views/views/direct.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
import 'package:nanny_client/views/pages/balance.dart';
import 'package:nanny_client/views/pages/graph.dart';
import 'package:nanny_client/views/pages/transactions/transactions_history_view.dart';
import 'package:nanny_client/views/rating/driver_rating_view.dart';
import 'package:nanny_core/models/from_api/notification_item.dart' as api;

/// B-014 TASK-B14: Центр уведомлений (клиент)
class NotificationCenterView extends StatefulWidget {
  const NotificationCenterView({super.key});

  @override
  State<NotificationCenterView> createState() => _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<NotificationCenterView> {
  late NotificationCenterVM vm;
  late Future<bool> _loadFuture;

  @override
  void initState() {
    super.initState();
    vm = NotificationCenterVM(context: context, update: setState);
    _loadFuture = vm.loadRequest;
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _reload();
    setState(() => _loadFuture = future);
    await future;
  }

  Future<bool> _reload() async {
    return vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'Уведомления',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
        actions: [
          if (vm.unreadCount > 0)
            TextButton(
              onPressed: vm.markAllAsRead,
              child: Text(
                'Прочитать все',
                style: AutonannyTypography.labelM(
                  color: context.autonannyColors.actionPrimary,
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: context.autonannyColors.actionPrimary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AutonannySpacing.xl),
                child: AutonannyErrorState(
                  title: 'Не удалось загрузить уведомления',
                  description: snapshot.error.toString(),
                ),
              ),
            );
          }

          if (snapshot.data != true && vm.filteredNotifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AutonannySpacing.xl),
                child: AutonannyErrorState(
                  title: 'Не удалось загрузить уведомления',
                  description: vm.errorMessage ?? 'Попробуйте обновить экран позже.',
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AutonannySpacing.lg,
                  AutonannySpacing.sm,
                  AutonannySpacing.lg,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vm.filters.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AutonannySpacing.sm),
                      itemBuilder: (_, i) {
                        final filter = vm.filters[i];
                        return _FilterChip(
                          label: filter['label']!,
                          isSelected: vm.selectedFilter == filter['key'],
                          onTap: () => vm.setFilter(filter['key']!),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AutonannySpacing.md),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: vm.filteredNotifications.isEmpty
                      ? const Center(
                          child: AutonannyEmptyState(
                            title: 'Нет уведомлений',
                            description:
                                'Новые события по поездкам, оплатам и системе появятся здесь.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AutonannySpacing.lg,
                            0,
                            AutonannySpacing.lg,
                            AutonannySpacing.xxl,
                          ),
                          itemCount: vm.filteredNotifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AutonannySpacing.sm),
                          itemBuilder: (_, i) =>
                              _buildCard(vm.filteredNotifications[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(api.NotificationItem item) {
    return NotificationItem(
      data: item.notificationItemData(
        timeLabel: _formatDate(item.createdAt),
      ),
      onTap: () => _openNotification(item),
    );
  }

  Future<void> _openNotification(api.NotificationItem item) async {
    vm.markAsRead(item.id);

    final target = item.payload?['target']?.toString();
    final resolvedTarget = target ?? _fallbackTarget(item.type);
    final scheduleId = _readIntPayload(
      item.payload?['schedule_id'] ?? item.payload?['id_schedule'],
    );
    final orderId = _readIntPayload(
      item.payload?['order_id'] ?? item.payload?['id_order'],
    );
    final chatId = _readIntPayload(
      item.payload?['chat_id'] ?? item.payload?['id_chat'],
    );

    switch (resolvedTarget) {
      case 'rating_request':
        if (orderId == null) {
          _showInfoMessage('Данные для оценки поездки недоступны.');
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DriverRatingView(
              orderId: orderId,
              driverName: item.payload?['driver_name']?.toString(),
              driverPhoto: item.payload?['driver_photo']?.toString(),
            ),
          ),
        );
        return;
      case 'trip':
      case 'active_trip':
        await _openActiveTrip(orderId);
        return;
      case 'contracts':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GraphView(
              persistState: false,
              initialScheduleId: scheduleId,
              openInitialScheduleDetails: scheduleId != null,
            ),
          ),
        );
        return;
      case 'balance':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BalanceView(persistState: false),
          ),
        );
        return;
      case 'wallet_operation':
        final searchQuery =
            item.payload?['search_query']?.toString() ??
                _buildWalletSearchQuery(
                  scheduleId: scheduleId,
                  orderId: orderId,
                );
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionsHistoryView(
              initialTransactionType:
                  item.payload?['transaction_type']?.toString(),
              initialSearchQuery: searchQuery,
            ),
          ),
        );
        return;
      case 'chat':
        if (chatId == null) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DirectView(
              idChat: chatId,
              name: item.payload?['chat_name']?.toString(),
            ),
          ),
        );
        return;
      default:
        return;
    }
  }

  Future<void> _openActiveTrip(int? expectedOrderId) async {
    final activeTrip = await ActiveTripResolver.resolveCurrentActiveTrip();
    if (!mounted) {
      return;
    }
    if (activeTrip == null || activeTrip.token.isEmpty) {
      _showInfoMessage('Активная поездка уже завершена или недоступна.');
      return;
    }
    if (expectedOrderId != null &&
        activeTrip.orderId != null &&
        activeTrip.orderId != expectedOrderId) {
      _showInfoMessage('Эта поездка уже завершена или больше не активна.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveTripScreen(token: activeTrip.token),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int? _readIntPayload(dynamic rawValue) {
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

  String? _fallbackTarget(String type) {
    switch (type) {
      case 'payment':
        return 'wallet_operation';
      case 'message':
        return 'chat';
      case 'order':
        return 'contracts';
      default:
        return null;
    }
  }

  String? _buildWalletSearchQuery({
    required int? scheduleId,
    required int? orderId,
  }) {
    if (orderId != null) {
      return '#$orderId';
    }
    if (scheduleId != null) {
      return '#$scheduleId';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} д назад';
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final components = context.autonannyComponents;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brFull,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.md,
            vertical: AutonannySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? null : colors.surfaceSecondary,
            gradient: isSelected ? components.primaryActionGradient : null,
            borderRadius: AutonannyRadii.brFull,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : colors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AutonannyTypography.labelM(
                color: isSelected ? colors.textInverse : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
