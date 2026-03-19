import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/nanny_core.dart';

/// Полноэкранный выбор адреса по тапу на карте.
/// Тап по карте ставит маркер и выполняет reverse geocoding.
/// Кнопка «Использовать адрес» возвращает [AddressData].
class FullScreenMapAddressPicker extends StatefulWidget {
  const FullScreenMapAddressPicker({super.key});

  @override
  State<FullScreenMapAddressPicker> createState() =>
      _FullScreenMapAddressPickerState();
}

class _FullScreenMapAddressPickerState extends State<FullScreenMapAddressPicker> {
  GoogleMapController? _controller;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _loading = false;
  late LatLng _initialCenter;

  @override
  void initState() {
    super.initState();
    final loc = LocationService.curLoc;
    _initialCenter = loc != null
        ? LatLng(loc.latitude ?? 55.75, loc.longitude ?? 37.62)
        : const LatLng(55.75, 37.62);
  }

  Future<void> _onMapTap(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _selectedAddress = null;
      _loading = true;
    });
    final geocodeData = await GoogleMapApi.reverseGeocode(loc: pos);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!geocodeData.success || geocodeData.response == null) {
      setState(() => _selectedAddress = 'Не удалось определить адрес');
      return;
    }
    final formatted = NannyMapUtils.filterGeocodeData(geocodeData.response!);
    setState(() {
      _selectedAddress = NannyMapUtils.simplifyAddress(
        formatted.address.formattedAddress,
      );
    });
  }

  void _onUseAddress() {
    if (_selectedLocation != null && _selectedAddress != null) {
      Navigator.of(context).pop(
        AddressData(address: _selectedAddress!, location: _selectedLocation!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Указать на карте'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: 14,
            ),
            onMapCreated: (c) => _controller = c,
            onTap: _onMapTap,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _selectedLocation!,
                    ),
                  }
                : {},
            myLocationEnabled: true,
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(NDT.sp16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: NDT.brLg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _selectedAddress ?? 'Тапните по карте для выбора адреса',
                    style: NDT.bodyM.copyWith(
                      color: _selectedAddress != null
                          ? NDT.neutral900
                          : NDT.neutral500,
                    ),
                  ),
                  if (_selectedAddress != null) ...[
                    const SizedBox(height: NDT.sp12),
                    NdPrimaryButton(
                      label: 'Использовать адрес',
                      onTap: _onUseAddress,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
