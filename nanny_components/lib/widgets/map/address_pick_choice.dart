import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/nanny_search_delegate.dart';

import 'full_screen_map_address_picker.dart';

/// Единый bottom sheet «Поиск по адресу» / «Указать на карте».
/// Возвращает [GeocodeResult] при выборе.
Future<GeocodeResult?> showAddressPickChoice(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(NDT.sp16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NdPrimaryButton(
              label: 'Поиск по адресу',
              onTap: () => Navigator.of(ctx).pop('search'),
            ),
            const SizedBox(height: NDT.sp12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop('map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NDT.primary,
                  side: const BorderSide(color: NDT.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: NDT.brXl,
                  ),
                ),
                child: const Text('Указать на карте'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice == 'map') {
    final result = await Navigator.of(context).push<AddressData>(
      MaterialPageRoute(
        builder: (_) => const FullScreenMapAddressPicker(),
      ),
    );
    if (result == null || !context.mounted) return null;
    return _geocodeResultFromAddressData(result);
  }
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
  return result;
}

GeocodeResult _geocodeResultFromAddressData(AddressData data) {
  return GeocodeResult(
    addressComponents: [],
    formattedAddress: data.address,
    geometry: Geometry(location: data.location),
    placeId: '',
    plusCode: null,
    types: [],
  );
}
