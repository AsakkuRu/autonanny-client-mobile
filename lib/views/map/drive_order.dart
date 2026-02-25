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
        context: context, update: setState, initAddress: widget.initAddress);
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
            child: Column(children: [
              AddressPicker(
                  controller: widget.controller,
                  addresses: vm.addresses,
                  onAdded: vm.onAdd,
                  onAddressChange: vm.onChange,
                  onDelete: vm.onDelete,
                  onSelectForMap: vm.selectAddress,
                  selectedIndex: vm.selectedAddressIndex),
              const SizedBox(height: 20),
              SingleChildScrollView(
                  controller: widget.controller,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 20, left: 10, right: 10),
                      child: Row(
                          children: vm.tariffs
                              .map((e) => true
                                  ? SizedBox(
                                      height: 100,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: ElevatedButton(
                                          onPressed: () => vm.selectTariff(e),
                                          style: vm.selectedTariff == e
                                              ? NannyButtonStyles
                                                  .defaultButtonStyle
                                              : NannyButtonStyles.whiteButton,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Row(
                                              children: [
                                                Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(e.title!),
                                                      Text(
                                                          "${e.amount!.toStringAsFixed(0)} Р",
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal))
                                                    ]),
                                                if (e.photoPath != null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    child: NetImage(
                                                      url: e.photoPath ?? '',
                                                      fitToShortest: false,
                                                    ),
                                                  )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox())
                              .toList()))),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: vm.validDrive ? vm.searchForDrivers : null,
                  child: const Text("Заказать"))
            ]));
      },
      errorView: (context, error) => ErrorView(errorText: error.toString()),
    );
  }
}
