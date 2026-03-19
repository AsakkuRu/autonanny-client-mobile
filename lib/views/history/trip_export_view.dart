import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/history/trip_export_vm.dart';
import 'package:nanny_components/nanny_components.dart';

class TripExportView extends StatefulWidget {
  const TripExportView({super.key});

  @override
  State<TripExportView> createState() => _TripExportViewState();
}

class _TripExportViewState extends State<TripExportView> {
  late TripExportVM vm;

  @override
  void initState() {
    super.initState();
    vm = TripExportVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        title: 'Экспорт поездок',
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите период',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _dateButton(
                    label: 'Начало',
                    date: vm.startDate,
                    onTap: vm.selectStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateButton(
                    label: 'Конец',
                    date: vm.endDate,
                    onTap: vm.selectEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: vm.isLoading ? null : vm.loadTrips,
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  vm.isLoading ? 'Загрузка...' : 'Загрузить поездки',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NannyTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (vm.trips.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Найдено: ${vm.trips.length} поездок',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Итого: ${vm.trips.where((t) => t.isCompleted && t.price != null).fold<double>(0, (s, t) => s + t.price!).toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NannyTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: vm.trips.length,
                  itemBuilder: (context, index) {
                    final trip = vm.trips[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: NannyTheme.shadow.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          trip.isCompleted
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: trip.isCompleted
                              ? NannyTheme.success
                              : NannyTheme.danger,
                        ),
                        title: Text(
                          '${trip.addressFrom} → ${trip.addressTo}',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${trip.date.day}.${trip.date.month}.${trip.date.year} • ${trip.statusText}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: trip.price != null
                            ? Text(
                                '${trip.price!.toStringAsFixed(0)} ₽',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: vm.isExporting ? null : vm.exportPdf,
                  icon: vm.isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf,
                          color: Colors.white),
                  label: Text(
                    vm.isExporting
                        ? 'Формирование PDF...'
                        : 'Экспортировать PDF',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ] else if (!vm.isLoading) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf,
                          size: 64, color: NannyTheme.neutral300),
                      const SizedBox(height: 16),
                      Text(
                        'Выберите период и загрузите поездки',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Затем экспортируйте в PDF',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: NannyTheme.neutral500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(
          color: date != null ? NannyTheme.primary : NannyTheme.neutral200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: date != null ? NannyTheme.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              date != null ? '${date.day}.${date.month}.${date.year}' : label,
              style: TextStyle(
                color: date != null ? Colors.black : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
