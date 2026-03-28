import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanny_client/l10n/app_localizations.dart';
import 'package:nanny_client/view_models/map/edit_route_vm.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';

class EditRouteView extends StatefulWidget {
  final int orderId;
  final List<AddressData> currentAddresses;

  const EditRouteView({
    super.key,
    required this.orderId,
    required this.currentAddresses,
  });

  @override
  State<EditRouteView> createState() => _EditRouteViewState();
}

class _EditRouteViewState extends State<EditRouteView> {
  late EditRouteVM vm;

  @override
  void initState() {
    super.initState();
    vm = EditRouteVM(
      context: context,
      update: setState,
      orderId: widget.orderId,
      initialAddresses: widget.currentAddresses,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'Изменить маршрут',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(
            AutonannyIcons.arrowLeft,
            size: 18,
          ),
          variant: AutonannyIconButtonVariant.ghost,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.lg,
            AutonannySpacing.md,
            AutonannySpacing.lg,
            AutonannySpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            boxShadow: AutonannyShadows.card,
          ),
          child: AutonannyButton(
            label: 'Сохранить изменения',
            isLoading: vm.isSaving,
            onPressed: vm.hasChanges && !vm.isSaving && !vm.isRecalculatingPrice
                ? vm.saveChanges
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.lg,
            AutonannySpacing.sm,
            AutonannySpacing.lg,
            AutonannySpacing.xl,
          ),
          children: [
            _buildAddAddressRow(),
            const SizedBox(height: AutonannySpacing.xl),
            Text(
              'Текущий маршрут',
              style: AutonannyTypography.h3(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AutonannySpacing.md),
            ...vm.addresses.asMap().entries.map((entry) {
              final index = entry.key;
              final address = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
                child: _buildAddressCard(index, address),
              );
            }),
            if (vm.isRecalculatingPrice) ...[
              const SizedBox(height: AutonannySpacing.lg),
              const AutonannyInlineBanner(
                title: 'Пересчитываем стоимость',
                message:
                    'Проверяем новый маршрут и обновляем стоимость поездки.',
                tone: AutonannyBannerTone.info,
                leading: AutonannyIcon(
                  AutonannyIcons.timer,
                  size: 18,
                ),
              ),
            ] else if (vm.pricePreviewError case final error?) ...[
              const SizedBox(height: AutonannySpacing.lg),
              AutonannyInlineBanner(
                title: 'Не удалось пересчитать стоимость',
                message: error,
                tone: AutonannyBannerTone.danger,
                leading: const AutonannyIcon(
                  AutonannyIcons.error,
                  size: 18,
                ),
              ),
            ] else if (vm.priceChange != null) ...[
              const SizedBox(height: AutonannySpacing.lg),
              AutonannyInlineBanner(
                title: 'Изменение стоимости',
                message: _priceChangeMessage(),
                tone: AutonannyBannerTone.warning,
                leading: const AutonannyIcon(
                  AutonannyIcons.info,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddAddressRow() {
    final colors = context.autonannyColors;

    return Row(
      children: [
        Expanded(
          child: AutonannyCard(
            onTap: vm.addAddress,
            child: Row(
              children: [
                AutonannyIcon(
                  AutonannyIcons.search,
                  size: 18,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: AutonannySpacing.sm),
                Expanded(
                  child: Text(
                    'Добавить или изменить адрес',
                    style: AutonannyTypography.bodyM(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (vm.hasChanges) ...[
          const SizedBox(width: AutonannySpacing.sm),
          AutonannyButton(
            label: 'Сбросить',
            expand: false,
            size: AutonannyButtonSize.medium,
            variant: AutonannyButtonVariant.secondary,
            onPressed: vm.resetChanges,
          ),
        ],
      ],
    );
  }

  Widget _buildAddressCard(int index, AddressData address) {
    final colors = context.autonannyColors;
    final isFirst = index == 0;
    final isLast = index == vm.addresses.length - 1;
    final l10n = AppLocalizations.of(context);

    final markerColor = isFirst
        ? colors.actionPrimary
        : (isLast ? colors.statusDanger : colors.textTertiary);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: markerColor,
                borderRadius: AutonannyRadii.brFull,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 42,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: AutonannyRadii.brFull,
                ),
              ),
          ],
        ),
        const SizedBox(width: AutonannySpacing.md),
        Expanded(
          child: AutonannyCard(
            padding: const EdgeInsets.all(AutonannySpacing.md),
            onTap: () => vm.editAddress(index),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFirst
                            ? (l10n?.from ?? 'Откуда')
                            : (isLast
                                ? (l10n?.to ?? 'Куда')
                                : 'Промежуточная остановка ${index + 1}'),
                        style: AutonannyTypography.labelM(
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AutonannySpacing.xs),
                      Text(
                        address.address,
                        style: AutonannyTypography.bodyM(
                          color: colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AutonannySpacing.sm),
                AutonannyIcon(
                  AutonannyIcons.edit,
                  size: 16,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (!isFirst && !isLast) ...[
          const SizedBox(width: AutonannySpacing.sm),
          AutonannyIconButton(
            icon: AutonannyIcon(
              AutonannyIcons.close,
              size: 16,
              color: colors.statusDanger,
            ),
            variant: AutonannyIconButtonVariant.ghost,
            size: 42,
            onPressed: () => vm.removeAddress(index),
          ),
        ] else
          const SizedBox(width: 42),
      ],
    );
  }

  String _priceChangeMessage() {
    final formatter = NumberFormat('#,##0.00', 'ru_RU');
    final delta = vm.priceChange!;
    final total = vm.nextTotalPrice;

    final deltaLabel = delta > 0
        ? '+${delta.toStringAsFixed(0)} ₽'
        : '${delta.toStringAsFixed(0)} ₽';
    final totalLabel =
        total == null ? null : 'Новая стоимость: ${formatter.format(total)} ₽';

    if (totalLabel == null) {
      return 'Изменение стоимости: $deltaLabel';
    }

    return 'Изменение стоимости: $deltaLabel. $totalLabel';
  }
}
