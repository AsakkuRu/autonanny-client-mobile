import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/models/address_view_data.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/widgets/map/address_pick_choice.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:time_range_picker/time_range_picker.dart';

class RouteSheetVM extends ViewModelBase {
  final NannyWeekday weekday;
  final Road? road;
  final int? tariffId;
  final List<NannyWeekday>? allSelectedWeekdays;

  bool applyToAllSelectedDays;
  late NannyWeekday selectedWeekdayForRoute;

  RouteSheetVM({
    required super.context,
    required super.update,
    required this.weekday,
    this.road,
    this.tariffId,
    this.allSelectedWeekdays,
    bool applyToAllDaysDefault = true,
  }) : applyToAllSelectedDays = applyToAllDaysDefault {
    // Заполняем roadName, если есть в schedule
    roadName = road?.title ?? "";
    nameController.text = roadName;

    // Заполняем время, если оно есть в schedule
    if (road?.startTime != null && road?.endTime != null) {
      timeRange = TimeRange(
        startTime: TimeOfDay(
            hour: road!.startTime.hour, minute: road!.startTime.minute),
        endTime:
            TimeOfDay(hour: road!.endTime.hour, minute: road!.endTime.minute),
      );
    }

    isRoundTrip = road?.typeDrive.contains(DriveType.roundTrip) ?? false;

    // Заполняем адреса, если они есть в schedule
    if (road?.addresses != null && road!.addresses.isNotEmpty) {
      addressFrom = GeocodeResult(
        formattedAddress: road!.addresses.first.fromAddress.address,
        geometry:
            Geometry(location: road!.addresses.first.fromAddress.location),
        addressComponents: [],
        placeId: '',
        plusCode: null,
        types: [],
      );
      addressTo = GeocodeResult(
        formattedAddress: road!.addresses.last.toAddress.address,
        geometry: Geometry(location: road!.addresses.last.toAddress.location),
        addressComponents: [],
        placeId: '',
        plusCode: null,
        types: [],
      );

      fromController.text =
          NannyMapUtils.simplifyAddress(addressFrom!.formattedAddress);
      toController.text =
          NannyMapUtils.simplifyAddress(addressTo!.formattedAddress);

      // Заполнение адресов промежуточных точек с проверкой на наличие промежуточных точек
      addresses = road!.addresses.length > 1
          ? road!.addresses
              .skip(1) // Пропускаем первый адрес
              .map(
              (e) {
                var a = AddressViewData(
                  address: GeocodeResult(
                    formattedAddress: e.fromAddress.address,
                    geometry: Geometry(location: e.fromAddress.location),
                    addressComponents: [],
                    placeId: '',
                    plusCode: null,
                    types: [],
                  ),
                  controller:
                      TextEditingController(text: e.fromAddress.address),
                );
                return a;
              },
            ).toList()
          : []; // Если промежуточных адресов нет, возвращаем пустой список
    }

    selectedWeekdayForRoute = road?.weekDay ?? weekday;

    update(() {});
    _scheduleEstimate();
  }

  String roadName = "";
  GeocodeResult? addressFrom;
  double? estimatedPrice;
  bool estimatedLoading = false;
  List<AddressViewData> addresses = [];
  GeocodeResult? addressTo;
  TimeRange? timeRange;
  bool isRoundTrip = false;
  // TimeOfDay? start;
  // TimeOfDay? end;

  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  // TextEditingController timeFromController = TextEditingController();
  // TextEditingController timeToController = TextEditingController();

  void chooseAddress({required bool from}) async {
    var address = await showAddressPickChoice(context);

    if (address == null) return;

    if (from) {
      addressFrom = address;
      fromController.text =
          NannyMapUtils.simplifyAddress(address.formattedAddress);
    } else {
      addressTo = address;
      toController.text =
          NannyMapUtils.simplifyAddress(address.formattedAddress);
    }

    update(() {});
    _scheduleEstimate();
  }

  void chooseAddtionAddress(AddressViewData data) async {
    var address = await showAddressPickChoice(context);

    if (address == null) return;

    data.address = address;
    data.controller.text =
        NannyMapUtils.simplifyAddress(address.formattedAddress);

    update(() {});
    _scheduleEstimate();
  }

  void removeAddress(AddressViewData data) {
    addresses.remove(data);

    update(() {});
    _scheduleEstimate();
  }

  List<Map<String, dynamic>>? _buildAddressesJson() {
    final driveAddresses = _buildDriveAddresses();
    if (driveAddresses == null) return null;
    return driveAddresses.map((e) => e.toJson()).toList(growable: false);
  }

  void _scheduleEstimate() {
    Future.microtask(() => fetchEstimate());
  }

  Future<void> fetchEstimate() async {
    if (tariffId == null) return;
    final addrs = _buildAddressesJson();
    if (addrs == null || addrs.isEmpty) {
      estimatedPrice = null;
      update(() {});
      return;
    }
    estimatedLoading = true;
    estimatedPrice = null;
    update(() {});
    final result = await NannyOrdersApi.estimateScheduleRoadPrice(
      idTariff: tariffId!,
      addresses: addrs,
    );
    if (!context.mounted) return;
    estimatedLoading = false;
    estimatedPrice = result.success ? result.response : null;
    update(() {});
  }

  void addAddress() {
    addresses.add(AddressViewData(controller: TextEditingController()));

    update(() {});
  }

  void chooseTime() async {
    final initial = timeRange ?? _defaultTimeRange();
    TimeRange? time = await showModalBottomSheet<TimeRange>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (sheetContext) {
        var start = _timeOfDayToDateTime(initial.startTime);
        var end = _timeOfDayToDateTime(initial.endTime);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isValid = _isEndAfterStart(start, end);
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: NDT.neutral200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Время поездки', style: NDT.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Укажите интервал, в который должна начаться поездка. Начало и конец выбираются отдельно.',
                      style: NDT.bodyS.copyWith(color: NDT.neutral500),
                    ),
                    const SizedBox(height: 20),
                    _TimeWheelCard(
                      label: 'От',
                      value: _formatDateTime(start),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        minuteInterval: 15,
                        use24hFormat: true,
                        initialDateTime: start,
                        onDateTimeChanged: (value) {
                          setModalState(() => start = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TimeWheelCard(
                      label: 'До',
                      value: _formatDateTime(end),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        minuteInterval: 15,
                        use24hFormat: true,
                        initialDateTime: end,
                        onDateTimeChanged: (value) {
                          setModalState(() => end = value);
                        },
                      ),
                    ),
                    if (!isValid) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: NDT.brMd,
                        ),
                        child: Text(
                          'Время "До" должно быть позже времени "От".',
                          style: NDT.bodyS.copyWith(color: NDT.warning),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NdPrimaryButton(
                            label: 'Готово',
                            onTap: isValid
                                ? () => Navigator.of(sheetContext).pop(
                                      TimeRange(
                                        startTime: TimeOfDay(
                                          hour: start.hour,
                                          minute: start.minute,
                                        ),
                                        endTime: TimeOfDay(
                                          hour: end.hour,
                                          minute: end.minute,
                                        ),
                                      ),
                                    )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (time == null) return;
    if (!context.mounted) return;

    timeRange = time;
    update(() {});
  }

  void cancel() => Navigator.pop(context);
  void confirm() async {
    if (roadName.isEmpty ||
        fromController.text.isEmpty ||
        toController.text.isEmpty ||
        timeRange == null ||
        addresses.any((e) => e.address == null)) {
      NannyDialogs.showMessageBox(context, "Ошибка", "Заполните форму!");
      return;
    }

    // LoadScreen.showLoad(context, true);

    // var balance = NannyUsersApi.getMoney();
    // bool success = await DioRequest.handleRequest(
    //   context,
    //   balance
    // );

    // if(!success) return;
    // var result = await balance;
    // if(!context.mounted) return;

    // if(result.response!.balance < 1000) {
    //   LoadScreen.showLoad(context, false);
    //   await NannyDialogs.showMessageBox(context, "Ошибка!", "На счете недостаточно средств!");
    //   // ignore: use_build_context_synchronously
    //   Navigator.pop(context, null);
    //   return;
    // }

    final driveAddresses = _buildDriveAddresses();
    if (driveAddresses == null || driveAddresses.isEmpty) {
      NannyDialogs.showMessageBox(
          context, "Ошибка", "Проверьте адреса маршрута");
      return;
    }

    final resultRoad = Road(
        id: road?.id,
        weekDay: selectedWeekdayForRoute,
        startTime: timeRange!.startTime,
        endTime: timeRange!.endTime,
        addresses: driveAddresses,
        title: roadName,
        typeDrive: [
          isRoundTrip ? DriveType.roundTrip : DriveType.oneWay,
          if (addresses.isNotEmpty) DriveType.withInterPoint
        ]);

    final targetDays = applyToAllSelectedDays
        ? allSelectedWeekdays
        : [selectedWeekdayForRoute];

    Navigator.pop(
      context,
      RouteSheetResult(
        road: resultRoad,
        applyToAllSelectedDays: applyToAllSelectedDays,
        targetWeekdays: targetDays,
      ),
    );
  }
}

extension TimeRangeAdditions on TimeRange {
  String toLocalTimeString() {
    String from = startTime.formatTime();
    String to = endTime.formatTime();

    return "$from - $to";
  }
}

class _TimeWheelCard extends StatelessWidget {
  const _TimeWheelCard({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NDT.neutral50,
        borderRadius: NDT.brXl,
        border: Border.all(color: NDT.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: NDT.bodyM.copyWith(color: NDT.neutral700)),
                Text(value, style: NDT.h3.copyWith(color: NDT.primary)),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: child,
          ),
        ],
      ),
    );
  }
}

extension on RouteSheetVM {
  List<DriveAddress>? _buildDriveAddresses() {
    if (addressFrom == null ||
        addressTo == null ||
        addressFrom!.geometry?.location == null ||
        addressTo!.geometry?.location == null) {
      return null;
    }
    if (addresses.any(
        (e) => e.address == null || e.address!.geometry?.location == null)) {
      return null;
    }

    final orderedStops = <GeocodeResult>[
      addressFrom!,
      ...addresses.map((e) => e.address!),
      addressTo!,
    ];

    if (orderedStops.length < 2) return null;

    final driveAddresses = <DriveAddress>[];
    for (var i = 0; i < orderedStops.length - 1; i++) {
      driveAddresses.add(
        DriveAddress(
          fromAddress: _toAddressData(orderedStops[i]),
          toAddress: _toAddressData(orderedStops[i + 1]),
        ),
      );
    }
    return driveAddresses;
  }

  AddressData _toAddressData(GeocodeResult result) {
    return AddressData(
      address: NannyMapUtils.simplifyAddress(result.formattedAddress),
      location: result.geometry!.location!,
    );
  }

  TimeRange _defaultTimeRange() {
    final roundedStart = _roundQuarterHour(TimeOfDay.now());
    return TimeRange(
      startTime: roundedStart,
      endTime: _plusMinutes(roundedStart, 60),
    );
  }

  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  bool _isEndAfterStart(DateTime start, DateTime end) {
    return end.isAfter(start);
  }

  String _formatDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute).formatTime();
  }

  TimeOfDay _roundQuarterHour(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;
    final rounded = ((totalMinutes + 14) ~/ 15) * 15;
    final normalized = rounded % (24 * 60);
    return TimeOfDay(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }

  TimeOfDay _plusMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final normalized = totalMinutes % (24 * 60);
    return TimeOfDay(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }
}
