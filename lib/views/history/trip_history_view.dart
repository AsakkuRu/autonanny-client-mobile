import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanny_client/view_models/history/trip_history_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';

class TripHistoryView extends StatefulWidget {
  const TripHistoryView({super.key});

  @override
  State<TripHistoryView> createState() => _TripHistoryViewState();
}

class _TripHistoryViewState extends State<TripHistoryView> {
  late TripHistoryVM vm;

  @override
  void initState() {
    super.initState();
    vm = TripHistoryVM(context: context, update: setState);
    vm.loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        title: 'История поездок',
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.trips.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.filteredTrips.length,
                    itemBuilder: (context, index) {
                      return _buildTripCard(vm.filteredTrips[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vm.showFilterDialog,
        icon: Badge(
          isLabelVisible: vm.hasActiveFilters,
          child: const Icon(Icons.filter_list),
        ),
        label: const Text('Фильтры'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: NannyTheme.neutral300),
          const SizedBox(height: 16),
          Text(
            'Нет поездок',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ваши завершённые поездки\nбудут отображаться здесь',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NannyTheme.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripHistory trip) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'ru');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => vm.showTripDetails(trip),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Дата и статус
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(trip.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: NannyTheme.neutral500,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trip.isCompleted
                          ? NannyTheme.success.withOpacity(0.1)
                          : NannyTheme.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trip.statusText,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: trip.isCompleted
                                    ? NannyTheme.successText
                                    : NannyTheme.danger,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Маршрут
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.circle,
                          size: 10, color: NannyTheme.primary),
                      Container(
                        width: 2,
                        height: 24,
                        color: NannyTheme.neutral200,
                      ),
                      const Icon(Icons.location_on,
                          size: 14, color: NannyTheme.danger),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.addressFrom.isNotEmpty
                              ? trip.addressFrom
                              : 'Адрес отправления не указан',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          trip.addressTo.isNotEmpty
                              ? trip.addressTo
                              : 'Адрес назначения не указан',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Водитель и цена
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (trip.driverName != null)
                    Row(
                      children: [
                        ProfileImage(
                          url: trip.driverPhoto ?? '',
                          radius: 24,
                          showOnlineDot: false,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trip.driverName!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (trip.rating != null) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star,
                              size: 14, color: Color(0xFFFFA726)),
                          const SizedBox(width: 2),
                          Text(
                            trip.rating.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: NannyTheme.neutral600,
                                ),
                          ),
                        ],
                      ],
                    )
                  else
                    const SizedBox(),
                  if (trip.price != null)
                    Text(
                      '${trip.price!.toStringAsFixed(0)} ₽',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
