import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/map/shared_ride_vm.dart';

class SharedRideView extends StatefulWidget {
  const SharedRideView({super.key});

  @override
  State<SharedRideView> createState() => _SharedRideViewState();
}

class _SharedRideViewState extends State<SharedRideView> {
  late SharedRideVM vm;

  @override
  void initState() {
    super.initState();
    vm = SharedRideVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: 'Совместные поездки',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(
            AutonannyIcons.arrowLeft,
            size: 18,
          ),
          variant: AutonannyIconButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      header: const AutonannyInlineBanner(
        title: 'Как это работает',
        message:
            'Совместная поездка позволяет разделить стоимость с другим родителем на похожем маршруте.',
        tone: AutonannyBannerTone.info,
        leading: AutonannyIcon(
          AutonannyIcons.info,
          size: 18,
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
              vm.options.isEmpty) {
            return const AutonannyLoadingState(
              label: 'Загружаем совместные поездки',
            );
          }

          if (snapshot.hasError || vm.error != null) {
            return _buildErrorState(vm.error ?? 'Не удалось загрузить поездки');
          }

          if (vm.isEmpty) {
            return const AutonannyEmptyState(
              title: 'Нет подходящих совместных поездок',
              description:
                  'Мы автоматически найдём родителей с похожими маршрутами и предложим объединить поездки.',
              icon: AutonannyIcon(
                AutonannyIcons.group,
                size: 40,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.refresh,
            color: context.autonannyColors.actionPrimary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AutonannySpacing.xl),
              itemCount: vm.options.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
                child: _buildOptionCard(vm.options[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return AutonannyErrorState(
      title: 'Не удалось загрузить поездки',
      description: error,
      actionLabel: 'Повторить',
      onAction: vm.refresh,
    );
  }

  Widget _buildOptionCard(SharedRideOption option) {
    final colors = context.autonannyColors;
    final match = _matchSeverity(option.matchPercent);

    return AutonannyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutonannyAvatar(
                initials:
                    option.parentName.isNotEmpty ? option.parentName[0] : 'Р',
                size: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.parentName,
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      '${option.childName}, ${option.childAge} лет',
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AutonannyStatusChip(
                label: '${option.matchPercent}% совпадение',
                variant: match,
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.lg),
          _routeRow(
            icon: AutonannyIcons.myLocation,
            text: option.addressFrom,
            color: colors.actionPrimary,
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(
              width: 2,
              height: 18,
              color: colors.borderSubtle,
            ),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          _routeRow(
            icon: AutonannyIcons.location,
            text: option.addressTo,
            color: colors.statusDanger,
          ),
          const SizedBox(height: AutonannySpacing.md),
          Row(
            children: [
              AutonannyIcon(
                AutonannyIcons.timer,
                size: 14,
                color: colors.textTertiary,
              ),
              const SizedBox(width: AutonannySpacing.xs),
              Text(
                'Отправление: ${option.time}',
                style: AutonannyTypography.bodyS(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Container(
            height: 1,
            color: colors.borderSubtle,
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${option.sharedPrice.toStringAsFixed(0)} ₽',
                      style: AutonannyTypography.h2(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Wrap(
                      spacing: AutonannySpacing.sm,
                      runSpacing: AutonannySpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${option.originalPrice.toStringAsFixed(0)} ₽',
                          style: AutonannyTypography.bodyS(
                            color: colors.textTertiary,
                          ).copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AutonannySpacing.sm,
                            vertical: AutonannySpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.statusSuccessSurface,
                            borderRadius: AutonannyRadii.brMd,
                          ),
                          child: Text(
                            '-${option.savings.toStringAsFixed(0)} ₽',
                            style: AutonannyTypography.labelM(
                              color: colors.statusSuccess,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              AutonannyButton(
                label: 'Присоединиться',
                expand: false,
                isLoading: vm.isRequesting,
                onPressed:
                    vm.isRequesting ? null : () => vm.requestSharedRide(option),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeRow({
    required AutonannyIconAsset icon,
    required String text,
    required Color color,
  }) {
    final colors = context.autonannyColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: AutonannyIcon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: AutonannySpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AutonannyTypography.bodyM(
              color: colors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  AutonannyStatusVariant _matchSeverity(int percent) {
    if (percent >= 85) return AutonannyStatusVariant.success;
    if (percent >= 70) return AutonannyStatusVariant.warning;
    return AutonannyStatusVariant.danger;
  }
}
