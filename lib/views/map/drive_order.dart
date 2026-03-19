import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/map/drive_order_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';

class DriveOrderView extends StatefulWidget {
  final ScrollController? controller;
  final GeocodeResult initAddress;

  const DriveOrderView({
    super.key,
    required this.controller,
    required this.initAddress,
  });

  @override
  State<DriveOrderView> createState() => _DriveOrderViewState();
}

class _DriveOrderViewState extends State<DriveOrderView> {
  late DriveOrderVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriveOrderVM(
      context: context,
      update: setState,
      initAddress: widget.initAddress,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureLoader(
      future: vm.loadRequest,
      completeView: (context, data) {
        if (!data) {
          return const ErrorView(errorText: "Не удалось загрузить данные");
        }

        return SingleChildScrollView(
          controller: widget.controller,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Куда поедем?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Уточните точки на карте и выберите подходящий тариф',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: NannyTheme.neutral500),
              ),
              const SizedBox(height: 16),

              // Блок адресов
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: NannyTheme.shadow.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            'Адреса',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          if (vm.addresses.length >= 2)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: NannyTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${vm.addresses.length} точки',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: NannyTheme.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    AddressPicker(
                      controller: widget.controller,
                      addresses: vm.addresses,
                      onAdded: vm.onAdd,
                      onAddressChange: vm.onChange,
                      onDelete: vm.onDelete,
                      onSelectForMap: vm.selectAddress,
                      selectedIndex: vm.selectedAddressIndex,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Блок тарифов
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Тариф',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (vm.distance > 0 && vm.duration > 0)
                    Text(
                      '${vm.distance.toStringAsFixed(1)} км · ${vm.duration.toStringAsFixed(0)} мин',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: NannyTheme.neutral500),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (context, index) {
                    final tariff = vm.tariffs[index];
                    final isSelected = vm.selectedTariff == tariff;

                    return GestureDetector(
                      onTap: () => vm.selectTariff(tariff),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        width: 190,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? NannyTheme.primary.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? NannyTheme.primary
                                : NannyTheme.neutral200,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: NannyTheme.primary
                                        .withOpacity(0.14),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tariff.title ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: NannyTheme.neutral900,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(tariff.amount ?? 0).toStringAsFixed(0)} ₽',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Фиксированная стоимость',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: NannyTheme.neutral500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (tariff.photoPath != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, right: 4),
                                child: SizedBox(
                                  width: 52,
                                  height: 40,
                                  child: NetImage(
                                    url: tariff.photoPath ?? '',
                                    fitToShortest: false,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: vm.tariffs.length,
                ),
              ),

              const SizedBox(height: 16),

              // Баннер «Скоро»
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: NannyTheme.neutral50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: NannyTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: NannyTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Скоро появятся подписки и расписания — заказывать станет ещё удобнее.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: NannyTheme.neutral500),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Блок «Кто едет»
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: NannyTheme.neutral100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Кто едет',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Выберите детей на следующем шаге',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: NannyTheme.neutral500),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/children');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NannyTheme.primary,
                        side: const BorderSide(color: NannyTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Добавить',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.validDrive ? vm.searchForDrivers : null,
                  child: const Text('Заказать поездку'),
                ),
              ),
            ],
          ),
        );
      },
      errorView: (context, error) => ErrorView(errorText: error.toString()),
    );
  }
}
