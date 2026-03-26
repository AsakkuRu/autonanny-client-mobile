import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_client/views/rating/driver_rating_details_view.dart';
import 'package:nanny_client/views/support/complaint_view.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';

class TripHistoryVM extends ViewModelBase {
  TripHistoryVM({
    required super.context,
    required super.update,
  });

  List<TripHistory> trips = [];
  List<TripHistory> filteredTrips = [];
  bool isLoading = true;

  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String? filterStatus;

  bool get hasActiveFilters =>
      filterStartDate != null || filterEndDate != null || filterStatus != null;

  @override
  Future<bool> loadPage() async {
    update(() => isLoading = true);

    final result = await NannyOrdersApi.getTripHistory(
      startDate: filterStartDate,
      endDate: filterEndDate,
      status: filterStatus,
    );

    if (result.success && result.response != null) {
      trips = result.response!;
      filteredTrips = List.from(trips);
      filteredTrips.sort((a, b) => b.date.compareTo(a.date));
    } else {
      trips = [];
      filteredTrips = [];
    }

    update(() => isLoading = false);
    return true;
  }

  Future<void> refresh() async {
    await loadPage();
  }

  void showFilterDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        startDate: filterStartDate,
        endDate: filterEndDate,
        status: filterStatus,
      ),
    );

    if (result != null) {
      filterStartDate = result['startDate'];
      filterEndDate = result['endDate'];
      filterStatus = result['status'];
      await loadPage();
    }
  }

  void showTripDetails(TripHistory trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TripDetailsSheet(trip: trip),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;

  const _FilterSheet({this.startDate, this.endDate, this.status});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  DateTime? startDate;
  DateTime? endDate;
  String? status;

  @override
  void initState() {
    super.initState();
    startDate = widget.startDate;
    endDate = widget.endDate;
    status = widget.status;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Фильтры',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    startDate = null;
                    endDate = null;
                    status = null;
                  });
                },
                child: const Text('Сбросить'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Период', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectDate(true),
                  child: Text(
                    startDate != null
                        ? '${startDate!.day}.${startDate!.month}.${startDate!.year}'
                        : 'От',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectDate(false),
                  child: Text(
                    endDate != null
                        ? '${endDate!.day}.${endDate!.month}.${endDate!.year}'
                        : 'До',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Статус', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _statusChip('Все', null),
              _statusChip('Завершённые', 'completed'),
              _statusChip('Отменённые', 'cancelled'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'startDate': startDate,
                  'endDate': endDate,
                  'status': status,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.autonannyColors.actionPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Применить',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String? value) {
    final isSelected = status == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => status = value),
      selectedColor: context.autonannyColors.actionPrimary.withValues(
        alpha: 0.16,
      ),
      checkmarkColor: context.autonannyColors.actionPrimary,
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          startDate = date;
        } else {
          endDate = date;
        }
      });
    }
  }
}

class _TripDetailsSheet extends StatelessWidget {
  final TripHistory trip;

  const _TripDetailsSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Детали поездки',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow('Дата',
              '${trip.date.day}.${trip.date.month}.${trip.date.year} ${trip.date.hour}:${trip.date.minute.toString().padLeft(2, '0')}'),
          _detailRow('Откуда', trip.addressFrom),
          _detailRow('Куда', trip.addressTo),
          if (trip.driverName != null) _detailRow('Водитель', trip.driverName!),
          if (trip.price != null)
            _detailRow('Стоимость', '${trip.price!.toStringAsFixed(0)} ₽'),
          if (trip.durationMinutes != null)
            _detailRow('Время в пути', '${trip.durationMinutes} мин'),
          if (trip.distanceKm != null)
            _detailRow(
                'Расстояние', '${trip.distanceKm!.toStringAsFixed(1)} км'),
          _detailRow('Статус', trip.statusText),
          if (trip.rating != null)
            _detailRow('Ваша оценка', '⭐ ${trip.rating}'),
          const SizedBox(height: 16),
          if (trip.driverId != null && trip.isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverRatingDetailsView(
                        driverId: trip.driverId!,
                        driverName: trip.driverName ?? 'Водитель',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.star_outline),
                label: const Text('Рейтинг водителя'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: context.autonannyColors.actionPrimary,
                  ),
                  foregroundColor: context.autonannyColors.actionPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplaintView(
                        orderId: trip.id,
                        driverId: trip.driverId,
                        driverName: trip.driverName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Подать жалобу'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Colors.orange),
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
