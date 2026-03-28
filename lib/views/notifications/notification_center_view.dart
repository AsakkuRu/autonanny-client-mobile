import 'package:flutter/material.dart';
import 'package:nanny_client/routing/client_entity_router.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/notifications/notification_center_vm.dart';
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
                  description:
                      vm.errorMessage ?? 'Попробуйте обновить экран позже.',
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
    final opened = await ClientEntityRouter.openEntity(
      context,
      payload: item.payload,
      target: item.payload?['target']?.toString(),
      type: item.type,
    );
    if (!opened && mounted) {
      await _showInfoSheet(
        title: 'Переход пока недоступен',
        message: 'Данные уведомления пока нельзя открыть напрямую.',
      );
    }
  }

  Future<void> _showInfoSheet({
    required String title,
    required String message,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = sheetContext.autonannyColors;
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AutonannySpacing.xl,
                AutonannySpacing.lg,
                AutonannySpacing.xl,
                AutonannySpacing.xl +
                    MediaQuery.of(sheetContext).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textTertiary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: AutonannySpacing.lg),
                  Text(
                    title,
                    style: AutonannyTypography.h3(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AutonannySpacing.lg),
                  AutonannyInlineBanner(
                    title: title,
                    message: message,
                    tone: AutonannyBannerTone.warning,
                    leading: const AutonannyIcon(AutonannyIcons.info),
                  ),
                  const SizedBox(height: AutonannySpacing.lg),
                  AutonannyButton(
                    label: 'Понятно',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
              color: isSelected ? Colors.transparent : colors.borderSubtle,
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
