import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_core.dart';

enum UiSdkAddressPickMethod {
  search,
  map,
}

Future<UiSdkAddressPickMethod?> showUiSdkAddressPickMethodSheet(
  BuildContext context, {
  String title = 'Как выбрать адрес',
  String? subtitle,
}) {
  return showModalBottomSheet<UiSdkAddressPickMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AddressPickMethodSheet(
      title: title,
      subtitle: subtitle,
      onSearchTap: () =>
          Navigator.of(sheetContext).pop(UiSdkAddressPickMethod.search),
      onMapTap: () =>
          Navigator.of(sheetContext).pop(UiSdkAddressPickMethod.map),
    ),
  );
}

Future<AddressData?> showUiSdkAddressSearchPicker(BuildContext context) async {
  final result = await showSearch<GeocodeResult?>(
    context: context,
    delegate: NannySearchDelegate(
      onSearch: (query) => GoogleMapApi.geocode(address: query),
      onResponse: (response) => response.response?.geocodeResults,
      tileBuilder: (data, close) => ListTile(
        title: Text(NannyMapUtils.buildStreetAddress(data)),
        onTap: close,
      ),
    ),
  );

  if (result == null) {
    return null;
  }

  final location = result.geometry?.location;
  if (location == null) {
    return null;
  }

  return AddressData(
    address: NannyMapUtils.buildStreetAddress(result),
    location: location,
  );
}

Future<AddressData?> showUiSdkAddressPicker(BuildContext context) {
  return Navigator.of(context).push<AddressData>(
    MaterialPageRoute(
      builder: (_) => const _UiSdkMapAddressPickerScreen(),
    ),
  );
}

Future<AddressData?> showUiSdkAddressSearchOrMapPicker(
  BuildContext context, {
  String title = 'Как выбрать адрес',
  String? subtitle,
}) async {
  final method = await showUiSdkAddressPickMethodSheet(
    context,
    title: title,
    subtitle: subtitle,
  );

  if (!context.mounted || method == null) {
    return null;
  }

  return switch (method) {
    UiSdkAddressPickMethod.search => showUiSdkAddressSearchPicker(context),
    UiSdkAddressPickMethod.map => showUiSdkAddressPicker(context),
  };
}

class _UiSdkMapAddressPickerScreen extends StatefulWidget {
  const _UiSdkMapAddressPickerScreen();

  @override
  State<_UiSdkMapAddressPickerScreen> createState() =>
      _UiSdkMapAddressPickerScreenState();
}

class _UiSdkMapAddressPickerScreenState
    extends State<_UiSdkMapAddressPickerScreen> {
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _loading = false;
  late final LatLng _initialCenter;

  @override
  void initState() {
    super.initState();
    final loc = LocationService.curLoc;
    _initialCenter = loc != null
        ? LatLng(loc.latitude, loc.longitude)
        : const LatLng(55.75, 37.62);
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _selectedAddress = null;
      _loading = true;
    });

    final geocodeData = await GoogleMapApi.reverseGeocode(loc: position);
    if (!mounted) {
      return;
    }

    setState(() => _loading = false);

    if (!geocodeData.success || geocodeData.response == null) {
      setState(() {
        _selectedAddress = 'Не удалось определить адрес';
      });
      return;
    }

    final formatted = NannyMapUtils.filterGeocodeData(geocodeData.response!);
    setState(() {
      _selectedAddress = NannyMapUtils.simplifyAddress(
        formatted.address.formattedAddress,
      );
    });
  }

  void _confirm() {
    final location = _selectedLocation;
    final address = _selectedAddress;
    if (location == null || address == null) {
      return;
    }

    Navigator.of(context).pop(
      AddressData(
        address: address,
        location: location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AddressPickerScreen(
      map: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialCenter,
          zoom: 14,
        ),
        onTap: _onMapTap,
        myLocationEnabled: true,
        markers: _selectedLocation == null
            ? const <Marker>{}
            : {
                Marker(
                  markerId: const MarkerId('picked-address'),
                  position: _selectedLocation!,
                ),
              },
      ),
      selectedAddress: _selectedAddress,
      isLoading: _loading,
      onClose: () => Navigator.of(context).maybePop(),
      onConfirm: _confirm,
    );
  }
}
