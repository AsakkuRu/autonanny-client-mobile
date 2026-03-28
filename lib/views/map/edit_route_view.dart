import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanny_client/l10n/app_localizations.dart';
import 'package:nanny_client/view_models/map/edit_route_vm.dart';
import 'package:nanny_components/nanny_components.dart';
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
    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        title: 'Изменить маршрут',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: vm.addAddress,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: NannyTheme.neutral50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NannyTheme.neutral200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: NannyTheme.neutral400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Добавить или изменить адрес',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: NannyTheme.neutral400,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (vm.hasChanges) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: vm.resetChanges,
                    child: const Text('Сбросить'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Text(
                  'Текущий маршрут',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...vm.addresses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final address = entry.value;
                  return _buildAddressCard(index, address);
                }),
                if (vm.isRecalculatingPrice) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NannyTheme.neutral50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: NannyTheme.neutral200),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Пересчитываем стоимость нового маршрута...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (vm.pricePreviewError != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NannyTheme.danger.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: NannyTheme.danger.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: NannyTheme.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            vm.pricePreviewError!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (vm.priceChange != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NannyTheme.warning.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: NannyTheme.warning.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: NannyTheme.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Изменение стоимости',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vm.priceChange! > 0
                                    ? '+${vm.priceChange!.toStringAsFixed(0)} ₽'
                                    : '${vm.priceChange!.toStringAsFixed(0)} ₽',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: vm.priceChange! > 0
                                          ? NannyTheme.danger
                                          : NannyTheme.success,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (vm.nextTotalPrice != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Новая стоимость: ${NumberFormat('#,##0.00', 'ru_RU').format(vm.nextTotalPrice)} ₽',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: NannyTheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    vm.hasChanges && !vm.isSaving && !vm.isRecalculatingPrice
                        ? vm.saveChanges
                        : null,
                child: vm.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Сохранить изменения'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(int index, AddressData address) {
    final isFirst = index == 0;
    final isLast = index == vm.addresses.length - 1;
    final l10n = AppLocalizations.of(context);

    final Color dotColor = isFirst
        ? NannyTheme.primary
        : (isLast ? NannyTheme.danger : NannyTheme.neutral400);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: NannyTheme.neutral200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NannyTheme.neutral100),
                boxShadow: [
                  BoxShadow(
                    color: NannyTheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => vm.editAddress(index),
                borderRadius: BorderRadius.circular(16),
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
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: NannyTheme.neutral500,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address.address,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: NannyTheme.neutral400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isFirst && !isLast) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => vm.removeAddress(index),
              icon: const Icon(Icons.close_rounded, color: NannyTheme.danger),
              iconSize: 20,
            ),
          ] else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
