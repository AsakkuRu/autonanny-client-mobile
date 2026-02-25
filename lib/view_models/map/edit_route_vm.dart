import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/nanny_core.dart';

class EditRouteVM {
  EditRouteVM({
    required this.context,
    required this.update,
    required this.orderId,
    required this.initialAddresses,
  }) {
    addresses = List.from(initialAddresses);
  }

  final BuildContext context;
  final void Function(void Function()) update;
  final int orderId;
  final List<AddressData> initialAddresses;

  List<AddressData> addresses = [];
  double? priceChange;
  bool isSaving = false;

  bool get hasChanges {
    if (addresses.length != initialAddresses.length) return true;
    for (int i = 0; i < addresses.length; i++) {
      if (addresses[i].address != initialAddresses[i].address) return true;
    }
    return false;
  }

  void resetChanges() {
    update(() {
      addresses = List.from(initialAddresses);
      priceChange = null;
    });
  }

  Future<void> addAddress() async {
    final address = await showSearch(
      context: context,
      delegate: NannySearchDelegate(
        onSearch: (query) => GoogleMapApi.geocode(address: query),
        onResponse: (response) => response.response?.geocodeResults,
        tileBuilder: (data, close) => ListTile(
          title: Text(data.formattedAddress),
          onTap: close,
        ),
      ),
    );

    if (address == null) return;
    final location = address.geometry?.location;
    if (location == null) return;

    update(() {
      addresses.insert(
        addresses.length - 1,
        AddressData(
          address: NannyMapUtils.simplifyAddress(address.formattedAddress),
          location: location,
        ),
      );
    });

    _recalculatePrice();
  }

  Future<void> editAddress(int index) async {
    final address = await showSearch(
      context: context,
      delegate: NannySearchDelegate(
        onSearch: (query) => GoogleMapApi.geocode(address: query),
        onResponse: (response) => response.response?.geocodeResults,
        tileBuilder: (data, close) => ListTile(
          title: Text(data.formattedAddress),
          onTap: close,
        ),
      ),
    );

    if (address == null) return;
    final location = address.geometry?.location;
    if (location == null) return;

    update(() {
      addresses[index] = AddressData(
        address: NannyMapUtils.simplifyAddress(address.formattedAddress),
        location: location,
      );
    });

    _recalculatePrice();
  }

  void removeAddress(int index) {
    if (index == 0 || index == addresses.length - 1) return;

    update(() {
      addresses.removeAt(index);
    });

    _recalculatePrice();
  }

  void _recalculatePrice() {
    // TODO: Call API to recalculate price based on new route
    // For now, estimate based on address count change
    final addressDiff = addresses.length - initialAddresses.length;
    update(() {
      priceChange = addressDiff * 100.0; // Placeholder: 100₽ per additional stop
    });
  }

  Future<void> saveChanges() async {
    if (!hasChanges) return;

    final confirmed = await NannyDialogs.confirmAction(
      context,
      priceChange != null && priceChange! > 0
          ? 'Стоимость поездки увеличится на ${priceChange!.toStringAsFixed(0)} ₽. Продолжить?'
          : 'Сохранить изменения маршрута?',
    );

    if (!confirmed) return;

    update(() {
      isSaving = true;
    });

    final addressesData = addresses
        .map((a) => {
              'address': a.address,
              'lat': a.location.latitude,
              'lng': a.location.longitude,
            })
        .toList();

    final result = await NannyOrdersApi.updateOrderRoute(
      orderId: orderId,
      addresses: addressesData,
    );

    update(() {
      isSaving = false;
    });

    if (!context.mounted) return;

    if (result.success) {
      NannyDialogs.showMessageBox(
        context,
        'Успех',
        'Маршрут обновлён. Водитель получит уведомление.',
      ).then((_) {
        if (context.mounted) Navigator.pop(context, addresses);
      });
    } else {
      NannyDialogs.showMessageBox(
        context,
        'Ошибка',
        result.errorMessage,
      );
    }
  }
}
