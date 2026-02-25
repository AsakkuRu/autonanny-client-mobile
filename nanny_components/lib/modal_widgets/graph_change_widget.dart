import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/modal_widgets/base_modal.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/nanny_search_delegate.dart';
import 'package:time_range_picker/time_range_picker.dart';

class GraphChangeWidget extends StatefulWidget {
  const GraphChangeWidget(this.road, this.scheduleId, {super.key});

  final int scheduleId;
  final Road road;

  @override
  State<StatefulWidget> createState() => _GraphChangeState();
}

//евдокии бершанской 402
//энергетиков 4 краснодар
class _GraphChangeState extends State<GraphChangeWidget> {
  late Road road = widget.road;
  late var title = road.title;
  late var from = road.addresses.isNotEmpty
      ? road.addresses[0].fromAddress.address
      : '(Адрес)';
  late var to = road.addresses.isNotEmpty
      ? road.addresses[0].toAddress.address
      : '(Адрес)';

  String get startTime => road.startTime.formatTime();
  late String selectedStartAddress = from;
  late String selectedEndAddress = to;
  late String calculatedAmount = '${road.amount?.toStringAsFixed(2)} ₽';
  GeocodeResult? startAddress;
  GeocodeResult? endAddress;
  TimeOfDay? startTimeOn;
  TimeOfDay? endTimeOn;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        cancelBtn(),
        Expanded(
            child: Text('Изменить график',
                style: NannyTextStyles.nw70018, textAlign: TextAlign.center)),
        saveBtn()
      ]),
      const SizedBox(height: 16),
      innerContainer(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              BaseBottomSheet.showChangeNameGraph(title).then((v) {
                title = v;
                setState(() {});
              });
            },
            child: Text(title,
                style: NannyTextStyles.nw40018.copyWith(color: Colors.black))),
        const Divider(),
        CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => chooseAddress(from: true),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Row(children: [
                    Text('От куда',
                        style: NannyTextStyles.nw40018
                            .copyWith(color: Colors.black)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(selectedStartAddress,
                            maxLines: null,
                            style: NannyTextStyles.nw40018
                                .copyWith(fontSize: 12, color: Colors.grey)))
                  ])),
                  const Icon(Icons.mode_edit_outline_rounded,
                      color: NannyTheme.primary, size: 20)
                ])),
        const Divider(),
        CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => chooseAddress(from: false),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Row(children: [
                    Text('Куда',
                        style: NannyTextStyles.nw40018
                            .copyWith(color: Colors.black)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(selectedEndAddress,
                            maxLines: null,
                            style: NannyTextStyles.nw40018
                                .copyWith(fontSize: 12, color: Colors.grey)))
                  ])),
                  const Icon(Icons.mode_edit_outline_rounded,
                      color: NannyTheme.primary, size: 20)
                ]))
      ])),
      const SizedBox(height: 20),
      CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            chooseTime();
          },
          child: innerContainer(
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Время',
                style: NannyTextStyles.nw40018.copyWith(color: Colors.black)),
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: NannyTheme.lightGreen),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  startTime,
                  style: NannyTextStyles.nw40018
                      .copyWith(fontSize: 16, color: Colors.black),
                ))
          ]))),
      // const SizedBox(height: 20),
      // innerContainer(
      //     Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      //   Text('Добавить новый маршрут', style: NannyTextStyles.nw40018),
      // ])),
      const SizedBox(height: 20),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
          child: Row(children: [
            Image.asset(
                'packages/nanny_components/assets/images/map/map_marker_user.png',
                height: 20,
                width: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(selectedStartAddress, maxLines: null))
          ])),
      const Divider(),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
          child: Row(children: [
            Image.asset(
                'packages/nanny_components/assets/images/map/map_marker_loc.png',
                height: 20,
                width: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(selectedEndAddress, maxLines: null))
          ])),
      const SizedBox(height: 20),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Стоимость',
                style: NannyTextStyles.nw60024.copyWith(fontSize: 18)),
            Text(calculatedAmount,
                maxLines: null,
                style: NannyTextStyles.nw70018.copyWith(fontSize: 25))
          ]))
    ]);
  }

  Future<void> updateAddresses() async {}

  Widget saveBtn() {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: save,
        child: Text('Готово',
            style: NannyTextStyles.nw60024.copyWith(fontSize: 16)));
  }

  Widget innerContainer(Widget child) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ]),
        child: child);
  }

  Widget cancelBtn() {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: Navigator.of(context).pop,
        child: Text('Отмена',
            style: NannyTextStyles.nw60024.copyWith(fontSize: 16)));
  }

  Future<void> chooseAddress({required bool from}) async {
    var address = await showSearch(
      context: context,
      delegate: NannySearchDelegate(
        onSearch: (query) => GoogleMapApi.geocode(address: query),
        onResponse: (response) => response.response?.geocodeResults,
        tileBuilder: (data, close) =>
            ListTile(title: Text(data.formattedAddress), onTap: close),
      ),
    );

    if (address == null) return;

    if (from) {
      startAddress = address;
      selectedStartAddress = address.formattedAddress;
    } else {
      endAddress = address;
      selectedEndAddress = address.formattedAddress;
    }
    setState(() {});
  }

  void chooseTime() async {
    TimeRange? time = await showTimeRangePicker(
      context: context,
      disabledTime: TimeRange(
          startTime: const TimeOfDay(hour: 20, minute: 0),
          endTime: const TimeOfDay(hour: 5, minute: 0)),
      minDuration: const Duration(hours: 1),
      interval: const Duration(minutes: 15),
      barrierDismissible: false,
      snap: true,
      ticks: 24,
      labels: [
        ClockLabel(angle: 0, text: "18"),
        ClockLabel(angle: 0.525, text: "20"),
        ClockLabel(angle: 1.05, text: "22"),
        ClockLabel(angle: 1.575, text: "0"),
        ClockLabel(angle: 2.1, text: "2"),
        ClockLabel(angle: 2.625, text: "4"),
        ClockLabel(angle: 3.15, text: "6"),
        ClockLabel(angle: 3.675, text: "8"),
        ClockLabel(angle: 4.2, text: "10"),
        ClockLabel(angle: 4.725, text: "12"),
        ClockLabel(angle: 5.25, text: "14"),
        ClockLabel(angle: 5.775, text: "16"),
      ],
      fromText: "От",
      toText: "До",
      strokeColor: NannyTheme.primary,
      handlerColor: NannyTheme.primary,
    );

    if (time == null) return;
    if (!context.mounted) return;
    startTimeOn = time.startTime;
    endTimeOn = time.endTime;
    road = road.copyWith(endTime: endTimeOn, startTime: startTimeOn);
    setState(() {});
  }

  Future<void> save() async {
    var roadUp = road.copyWith(
        title: title,
        startTime: startTimeOn,
        endTime: endTimeOn,
        addresses: [
          DriveAddress(
              fromAddress: AddressData(
                  address: selectedStartAddress,
                  location: startAddress?.geometry?.location ??
                      road.addresses[0].fromAddress.location),
              toAddress: AddressData(
                  address: selectedEndAddress,
                  location: endAddress?.geometry?.location ??
                      road.addresses[0].toAddress.location)),
        ]);
    NannyOrdersApi.updateScheduleRoadById(roadUp)
        .then((v) => Navigator.of(context).pop(roadUp));
  }
}
