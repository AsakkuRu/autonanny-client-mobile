// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:math';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_resolver.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/onetime_drive_request.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';
import 'package:nanny_core/nanny_core.dart';

class DriveOrderVM extends ViewModelBase {
  DriveOrderVM({
    required super.context,
    required super.update,
    required this.initAddress,
  }) {
    var curLoc = LocationService.curLoc;
    if (curLoc == null) {
      _initLocation();
    } else {
      update(() {
        addresses = [
          AddressData(
            address: NannyMapUtils.simplifyAddress(
              initAddress.formattedAddress,
            ),
            location: initAddress.geometry?.location ??
                NannyMapUtils.position2LatLng(curLoc!),
          ),
        ];
      });
      _syncMarkersWithAddresses();
    }

    _mapTapSub = NannyMapGlobals.onMapTap.listen(_onMapTap);
  }

  StreamSubscription<LatLng>? _mapTapSub;
  Timer? _priceDebounce;

  final GeocodeResult initAddress;
  List<AddressData> addresses = [];
  double distance = 0;
  double duration = 0;
  // Индекс выбранного адреса для уточнения точки на карте (-1 = добавить новый)
  int selectedAddressIndex = -1;

  ValueNotifier<Set<Marker>> markers = NannyMapGlobals.markers;

  void _syncMarkersWithAddresses() {
    final currentMarkers = markers.value;
    final currentPosMarkers = currentMarkers
        .where((m) => m.markerId == NannyConsts.curPosId)
        .toList();

    final updatedMarkers = <Marker>{...currentPosMarkers};

    for (final address in addresses) {
      updatedMarkers.add(
        Marker(
          markerId: MarkerId(address.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            HSLColor.fromColor(NannyTheme.primary).hue,
          ),
          position: address.location,
        ),
      );
    }

    markers.value = updatedMarkers;
    markers.notifyListeners();
  }

  Future<void> _initLocation() async {
    try {
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position v = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LocationService.curLoc = v;
      print('current location $v');

      update(() {
        addresses = [
          AddressData(
            address: initAddress.formattedAddress,
            location: initAddress.geometry?.location ??
                NannyMapUtils.position2LatLng(v),
          ),
        ];
      });
      _syncMarkersWithAddresses();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void selectAddress(int index) {
    update(() {
      selectedAddressIndex = index;
    });
  }

  void _onMapTap(LatLng latLng) async {
    if (!context.mounted) return;
    LoadScreen.showLoad(context, true);

    var geocodeData = await GoogleMapApi.reverseGeocode(loc: latLng);

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (!geocodeData.success || geocodeData.response == null) return;

    var formatted = NannyMapUtils.filterGeocodeData(geocodeData.response!);
    final newAddress = AddressData(
      address:
          NannyMapUtils.simplifyAddress(formatted.address.formattedAddress),
      location: latLng,
    );

    // Если выбран конкретный адрес — уточняем его точку
    if (selectedAddressIndex >= 0 && selectedAddressIndex < addresses.length) {
      final oldAddress = addresses[selectedAddressIndex];
      onChange(oldAddress, newAddress);
      update(() {
        selectedAddressIndex = -1;
      });
    } else if (addresses.length < 2) {
      // Автоматически добавляем второй адрес (конечную точку)
      onAdd(newAddress);
    } else {
      // Если уже есть 2+ адреса — обновляем последний (конечную точку)
      final oldAddress = addresses.last;
      onChange(oldAddress, newAddress);
    }
  }

  List<DriveTariff> tariffs = [];
  DriveTariff? selectedTariff;
  List<OtherParametr> additionalParams = [];
  final Set<String> _selectedAdditionalParamKeys = {};

  bool get validDrive => addresses.length > 1 && selectedTariff != null;

  bool isAdditionalParamSelected(OtherParametr param) =>
      _selectedAdditionalParamKeys.contains(_additionalParamKey(param));

  void toggleAdditionalParam(OtherParametr param) {
    final key = _additionalParamKey(param);
    if (_selectedAdditionalParamKeys.contains(key)) {
      _selectedAdditionalParamKeys.remove(key);
    } else {
      _selectedAdditionalParamKeys.add(key);
    }
    update(() {});
  }

  void calculatePrices() {
    // Debounce: отменяем предыдущий запрос, чтобы не спамить API
    _priceDebounce?.cancel();
    _priceDebounce = Timer(const Duration(milliseconds: 500), () {
      _doCalculatePrices();
    });
  }

  Future<void> _doCalculatePrices() async {
    if (addresses.length < 2) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    try {
      NannyMapGlobals.routes.value.clear();
      distance = 0;
      duration = 0;

      for (int i = 0; i < addresses.length - 1; i++) {
        var origin = addresses[i].location;
        var dest = addresses[i + 1].location;

        var polyRes = await PolylinePoints().getRouteBetweenCoordinates(
          NannyConsts.mapKey,
          PointLatLng(origin.latitude, origin.longitude),
          PointLatLng(dest.latitude, dest.longitude),
        );

        distance += SphericalUtils.computeDistanceBetween(
            Point(origin.longitude, origin.latitude),
            Point(dest.longitude, dest.latitude));
        duration += (polyRes.durationValue ?? 0);

        var route = await RouteManager.calculateRoute(
            origin: origin, destination: dest, id: 'route_$i');

        if (route == null) continue;

        NannyMapGlobals.routes.value.add(route);
      }

      NannyMapGlobals.routes.notifyListeners();
      if (!context.mounted) return;

      distance /= 1000;
      duration /= 60;

      if (distance <= 0 || duration <= 0) {
        if (context.mounted) LoadScreen.showLoad(context, false);
        return;
      }

      var res = await DioRequest.handle(context,
          NannyOrdersApi.getOnetimePrices(duration.ceil(), distance.ceil()));

      if (!res.success || res.data == null) return;

      var priceTars = res.data!;
      for (var tar in tariffs) {
        var tariff = priceTars.where((e) => e.id == tar.id).firstOrNull;
        if (tariff == null) continue;

        tar.amount = tariff.amount ?? tar.amount;
      }

      if (context.mounted) LoadScreen.showLoad(context, false);
      update(() {});
    } catch (e) {
      Logger().e('calculatePrices error: $e');
      if (context.mounted) LoadScreen.showLoad(context, false);
    }
  }

  void onAdd(AddressData address) {
    addresses.add(address);
    _syncMarkersWithAddresses();
    calculatePrices();
    update(() {});
  }

  void onChange(AddressData oldAd, AddressData newAd) {
    int index = addresses.indexOf(oldAd);
    addresses.removeAt(index);
    addresses.insert(index, newAd);
    _syncMarkersWithAddresses();
    calculatePrices();
    update(() {});
  }

  void onDelete(AddressData address) {
    addresses.remove(address);
    _syncMarkersWithAddresses();
    calculatePrices();
    update(() {});
  }

  void searchForDrivers() async {
    if (await _redirectToActiveTripIfNeeded()) return;

    if (addresses.length < 2) {
      NannyDialogs.showMessageBox(
          context, 'Ошибка', 'Укажите минимум 2 адреса');
      return;
    }
    if (selectedTariff == null) {
      NannyDialogs.showMessageBox(context, 'Ошибка', 'Выберите тариф');
      return;
    }
    if (LocationService.curLoc == null) {
      NannyDialogs.showMessageBox(
          context, 'Ошибка', 'Не удалось определить ваше местоположение');
      return;
    }

    List<DriveAddress> driveAddresses = [];
    for (int i = 0; i < addresses.length - 1; i++) {
      driveAddresses.add(
          DriveAddress(fromAddress: addresses[i], toAddress: addresses[i + 1]));
    }

    try {
      var res = await DioRequest.handle(
          context,
          NannyOrdersApi.startOnetimeOrder(OnetimeDriveRequest(
              myLocation: LocationService.curLoc,
              addresses: driveAddresses,
              price: (selectedTariff!.amount ?? 0).toInt(),
              distance: distance.ceil(),
              duration: duration.ceil(),
              description: '',
              typeDrive: DriveType.oneWay.id,
              idTariff: selectedTariff!.id,
              otherParametrs: selectedAdditionalParamsPayload)));

      if (!res.success || res.data == null) {
        if (res.errorMessage == 'У вас уже есть активная поездка') {
          await _redirectToActiveTripIfNeeded();
        }
        return;
      }

      if (!context.mounted) return;
      await ActiveTripSessionStore.save(
        ActiveTripSessionData(
          token: res.data!,
          statusId: 4,
        ),
      );
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ActiveTripScreen(token: res.data!)));
    } catch (e) {
      Logger().e('searchForDrivers error: $e');
      if (context.mounted) {
        NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Не удалось создать заказ: $e');
      }
    }
  }

  Future<bool> _redirectToActiveTripIfNeeded() async {
    final activeTrip = await ActiveTripResolver.resolveCurrentActiveTrip();
    if (activeTrip == null || !context.mounted) return false;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Активная поездка'),
        content: const Text(
          'У вас уже есть активная поездка. Перейти к ней вместо создания новой?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('К поездке'),
          ),
        ],
      ),
    );

    if (shouldOpen == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveTripScreen(token: activeTrip.token),
        ),
      );
    }

    return true;
  }

  void selectTariff(DriveTariff tariff) {
    selectedTariff = tariff;
    update(() {});
  }

  @override
  Future<bool> loadPage() async {
    var res = await NannyStaticDataApi.getTariffs();

    if (!res.success) return false;
    tariffs = res.response!;

    final paramsRes = await NannyStaticDataApi.getOtherParams();
    if (paramsRes.success && paramsRes.response != null) {
      additionalParams = paramsRes.response!;
    }

    return true;
  }

  List<Map<String, dynamic>> get selectedAdditionalParamsPayload =>
      additionalParams
          .where(isAdditionalParamSelected)
          .map((param) => param.toGraphJson(1))
          .toList(growable: false);

  String _additionalParamKey(OtherParametr param) =>
      '${param.id ?? param.title}';

  @override
  void dispose() {
    _mapTapSub?.cancel();
    _priceDebounce?.cancel();
  }
}
