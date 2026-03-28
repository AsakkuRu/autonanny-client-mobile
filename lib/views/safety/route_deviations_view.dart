import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:nanny_client/view_models/safety/route_deviations_vm.dart';
import 'package:intl/intl.dart';

class RouteDeviationsView extends StatefulWidget {
  final int? orderId;

  const RouteDeviationsView({super.key, this.orderId});

  @override
  State<RouteDeviationsView> createState() => _RouteDeviationsViewState();
}

class _RouteDeviationsViewState extends State<RouteDeviationsView> {
  late RouteDeviationsVM vm;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    vm = RouteDeviationsVM(
      context: context,
      update: setState,
      filterOrderId: widget.orderId,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      vm.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: 'История отклонений',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(
            AutonannyIcons.arrowLeft,
            size: 18,
          ),
          variant: AutonannyIconButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.lg,
        0,
        AutonannySpacing.lg,
        AutonannySpacing.lg,
      ),
      body: FutureBuilder<bool>(
        future: vm.loadRequest,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              vm.deviations.isEmpty) {
            return const AutonannyLoadingState(
              label: 'Загружаем историю отклонений',
            );
          }

          if (snapshot.hasError || vm.error != null) {
            return _buildErrorState();
          }

          if (vm.deviations.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: vm.refresh,
            color: context.autonannyColors.actionPrimary,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: AutonannySpacing.sm,
                bottom: AutonannySpacing.xl,
              ),
              itemCount: vm.deviations.length + (vm.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == vm.deviations.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AutonannySpacing.lg),
                    child: Center(
                      child: AutonannyLoadingState(label: 'Загружаем ещё'),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
                  child: _buildDeviationCard(vm.deviations[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AutonannyEmptyState(
      title: 'Отклонений не зафиксировано',
      description: 'Все поездки прошли по запланированному маршруту.',
      icon: AutonannyIcon(
        AutonannyIcons.route,
        size: 42,
      ),
    );
  }

  Widget _buildErrorState() {
    return AutonannyErrorState(
      title: 'Не удалось загрузить данные',
      description: vm.error ?? 'Попробуйте повторить запрос ещё раз.',
      actionLabel: 'Повторить',
      onAction: vm.refresh,
    );
  }

  Widget _buildDeviationCard(RouteDeviation deviation) {
    final colors = context.autonannyColors;
    final dateFmt = DateFormat('dd.MM.yyyy, HH:mm');
    final meters = deviation.deviationMeters.toStringAsFixed(0);
    final severity = _severity(deviation.deviationMeters);

    final accentColor = switch (severity.variant) {
      AutonannyStatusVariant.success => colors.statusSuccess,
      AutonannyStatusVariant.warning => colors.statusWarning,
      AutonannyStatusVariant.danger => colors.statusDanger,
      _ => colors.textSecondary,
    };

    final accentSurface = switch (severity.variant) {
      AutonannyStatusVariant.success => colors.statusSuccessSurface,
      AutonannyStatusVariant.warning => colors.statusWarningSurface,
      AutonannyStatusVariant.danger => colors.statusDangerSurface,
      _ => colors.surfaceSecondary,
    };

    return AutonannyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentSurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AutonannyIcon(
                    AutonannyIcons.warning,
                    size: 18,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Отклонение на $meters м',
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      dateFmt.format(deviation.timestamp),
                      style: AutonannyTypography.bodyS(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              AutonannyStatusChip(
                label: severity.label,
                variant: severity.variant,
              ),
            ],
          ),
          if (deviation.description case final description?) ...[
            const SizedBox(height: AutonannySpacing.md),
            Text(
              description,
              style: AutonannyTypography.bodyM(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AutonannySpacing.md),
          Row(
            children: [
              AutonannyIcon(
                AutonannyIcons.document,
                size: 14,
                color: colors.textTertiary,
              ),
              const SizedBox(width: AutonannySpacing.xs),
              Text(
                'Заказ #${deviation.orderId}',
                style: AutonannyTypography.bodyS(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _SeverityInfo _severity(double meters) {
    if (meters >= 1000) {
      return const _SeverityInfo(
        variant: AutonannyStatusVariant.danger,
        label: 'Критичное',
      );
    } else if (meters >= 500) {
      return const _SeverityInfo(
        variant: AutonannyStatusVariant.warning,
        label: 'Значительное',
      );
    } else {
      return const _SeverityInfo(
        variant: AutonannyStatusVariant.success,
        label: 'Незначительное',
      );
    }
  }
}

class _SeverityInfo {
  final AutonannyStatusVariant variant;
  final String label;
  const _SeverityInfo({
    required this.variant,
    required this.label,
  });
}
