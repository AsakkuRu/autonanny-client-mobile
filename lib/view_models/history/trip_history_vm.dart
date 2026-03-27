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
      builder: (ctx) => _TripDetailsSheet(
        trip: trip,
        onRatingSaved: refresh,
      ),
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
  final Future<void> Function()? onRatingSaved;

  const _TripDetailsSheet({
    required this.trip,
    this.onRatingSaved,
  });

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
              child: ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final rated = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => _RateDriverSheet(trip: trip),
                  );

                  if (rated == true) {
                    await onRatingSaved?.call();
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          trip.rating == null
                              ? 'Оценка сохранена.'
                              : 'Оценка обновлена.',
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  trip.rating == null
                      ? Icons.star_rate_rounded
                      : Icons.edit_note_rounded,
                ),
                label: Text(
                  trip.rating == null
                      ? 'Оценить водителя'
                      : 'Изменить оценку',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: context.autonannyColors.actionPrimary,
                  foregroundColor: Colors.white,
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

class _RateDriverSheet extends StatefulWidget {
  const _RateDriverSheet({required this.trip});

  final TripHistory trip;

  @override
  State<_RateDriverSheet> createState() => _RateDriverSheetState();
}

class _RateDriverSheetState extends State<_RateDriverSheet> {
  static const List<String> _criteriaOptions = [
    'Пунктуальность',
    'Безопасное вождение',
    'Вежливость',
    'Чистый автомобиль',
    'Комфортная поездка',
  ];

  final TextEditingController _reviewController = TextEditingController();
  final Set<String> _selectedCriteria = <String>{};
  late int _rating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.trip.rating ?? 0;
    _reviewController.text = widget.trip.ratingReview ?? '';
    _selectedCriteria.addAll(widget.trip.ratingCriteria);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _rating == 0) {
      return;
    }

    setState(() => _saving = true);

    final result = await NannyOrdersApi.rateDriver(
      orderId: widget.trip.id,
      rating: _rating,
      criteria: _selectedCriteria.isEmpty
          ? null
          : _selectedCriteria.toList(growable: false),
      review: _reviewController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.errorMessage.isNotEmpty
              ? result.errorMessage
              : 'Не удалось сохранить оценку.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.trip.driverName?.trim().isNotEmpty == true
        ? widget.trip.driverName!.trim()
        : 'водителя';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Оцените поездку',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ваша оценка поможет другим родителям лучше понимать сильные стороны $driverName.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isSelected = index < _rating;
              return IconButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _rating = index + 1;
                        }),
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? const Color(0xFFF59E0B) : Colors.grey,
                  size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text(
            'Что понравилось',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _criteriaOptions.map((criteria) {
              final selected = _selectedCriteria.contains(criteria);
              return FilterChip(
                label: Text(criteria),
                selected: selected,
                onSelected: _saving
                    ? null
                    : (value) {
                        setState(() {
                          if (value) {
                            _selectedCriteria.add(criteria);
                          } else {
                            _selectedCriteria.remove(criteria);
                          }
                        });
                      },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 16),
          AutonannyTextField(
            controller: _reviewController,
            labelText: 'Комментарий',
            hintText: 'Например: вовремя приехал, аккуратно вёл, ребёнку было комфортно.',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AutonannyButton(
              label: 'Сохранить оценку',
              onPressed: _rating == 0 || _saving ? null : _submit,
              isLoading: _saving,
            ),
          ),
        ],
      ),
    );
  }
}
