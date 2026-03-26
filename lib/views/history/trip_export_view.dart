import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/history/trip_export_vm.dart';

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
    final colors = context.autonannyColors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AutonannyAppBar(
        title: 'Экспорт поездок',
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: AutonannyIcon(
            AutonannyIcons.chevronLeft,
            color: colors.textPrimary,
          ),
        ),
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
            AutonannyButton(
              label: vm.isLoading ? 'Загрузка...' : 'Загрузить поездки',
              isLoading: vm.isLoading,
              leading: vm.isLoading
                  ? null
                  : const AutonannyIcon(
                      AutonannyIcons.search,
                      color: Colors.white,
                    ),
              onPressed: vm.isLoading ? null : vm.loadTrips,
            ),
            const SizedBox(height: 24),
            if (vm.trips.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Найдено: ${vm.trips.length} поездок',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Итого: ${vm.trips.where((t) => t.isCompleted && t.price != null).fold<double>(0, (s, t) => s + t.price!).toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.actionPrimary,
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
                        color: colors.surfaceElevated,
                        borderRadius: AutonannyRadii.brLg,
                        boxShadow: AutonannyShadows.card,
                      ),
                      child: ListTile(
                        leading: Icon(
                          trip.isCompleted ? Icons.check_circle : Icons.cancel,
                          color: trip.isCompleted
                              ? colors.statusSuccess
                              : colors.statusDanger,
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
              AutonannyButton(
                label: vm.isExporting
                    ? 'Формирование PDF...'
                    : 'Экспортировать PDF',
                isLoading: vm.isExporting,
                variant: AutonannyButtonVariant.secondary,
                leading: vm.isExporting
                    ? null
                    : AutonannyIcon(
                        AutonannyIcons.document,
                        color: colors.actionPrimary,
                      ),
                onPressed: vm.isExporting ? null : vm.exportPdf,
              ),
            ] else if (!vm.isLoading) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: colors.borderStrong,
                      ),
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
                            ?.copyWith(color: colors.textTertiary),
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
    final colors = context.autonannyColors;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(
          color: date != null ? colors.actionPrimary : colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: date != null ? colors.actionPrimary : colors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              date != null ? '${date.day}.${date.month}.${date.year}' : label,
              style: TextStyle(
                color: date != null ? colors.textPrimary : colors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
