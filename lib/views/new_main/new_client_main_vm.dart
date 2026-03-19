import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nanny_client/analytics/new_main_screen_analytics.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/onetime_drive_request.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/api/nanny_children_api.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/child_short.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_core.dart';

const int _kMaxChildren = 4;

class NewClientMainVM extends ViewModelBase {
  NewClientMainVM({
    required super.context,
    required super.update,
    required this.initAddress,
  }) {
    var curLoc = LocationService.curLoc;
    if (curLoc != null) {
      addresses = [
        AddressData(
          address: NannyMapUtils.simplifyAddress(
            initAddress.formattedAddress,
          ),
          location: initAddress.geometry?.location ??
              NannyMapUtils.position2LatLng(curLoc),
        ),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncMarkersWithAddresses();
      });
    }
    _mapTapSub = NannyMapGlobals.onMapTap.listen(_onMapTap);
  }

  // ─── Адреса ──────────────────────────────────────────────────────────────

  final GeocodeResult initAddress;
  List<AddressData> addresses = [];
  double distance = 0;
  double duration = 0;

  /// Индекс активного адресного поля (для тапа по карте).
  /// -1 = нет активного поля (тап по карте заменяет последний адрес).
  int selectedAddressIndex = -1;

  ValueNotifier<Set<Marker>> markers = NannyMapGlobals.markers;

  StreamSubscription<LatLng>? _mapTapSub;
  Timer? _priceDebounce;

  // ─────────────────────────────────────────────────────────────────────────

  void _syncMarkersWithAddresses() {
    final currentPosMarkers = markers.value
        .where((m) => m.markerId == NannyConsts.curPosId)
        .toList();
    final updated = <Marker>{...currentPosMarkers};
    for (var i = 0; i < addresses.length; i++) {
      final addr = addresses[i];
      final hue = i == 0
          ? BitmapDescriptor.hueBlue   // ОТКУДА — синий
          : i == addresses.length - 1
              ? BitmapDescriptor.hueRed  // КУДА — красный
              : BitmapDescriptor.hueViolet; // промежуточные
      updated.add(Marker(
        markerId: MarkerId('addr_$i'),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        position: addr.location,
      ));
    }
    markers.value = updated;
    markers.notifyListeners();
  }

  /// Устанавливает активное поле. Тап по карте запишет адрес именно туда.
  void selectAddress(int index) => update(() => selectedAddressIndex = index);

  /// Снимает активность с текущего поля.
  void clearAddressSelection() => update(() => selectedAddressIndex = -1);

  /// Добавляет промежуточную точку (вставляется перед КУДА).
  void insertWaypoint(AddressData addr) {
    if (addresses.length < 2) {
      onAdd(addr);
    } else {
      // Вставить перед последним адресом (КУДА)
      addresses.insert(addresses.length - 1, addr);
      _syncMarkersWithAddresses();
      _schedulePriceCalc();
      update(() {});
    }
  }

  void _onMapTap(LatLng latLng) async {
    if (!context.mounted) return;
    LoadScreen.showLoad(context, true);
    final geocodeData = await GoogleMapApi.reverseGeocode(loc: latLng);
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);
    if (!geocodeData.success || geocodeData.response == null) return;
    final formatted = NannyMapUtils.filterGeocodeData(geocodeData.response!);
    final newAddr = AddressData(
      address: NannyMapUtils.simplifyAddress(
          formatted.address.formattedAddress),
      location: latLng,
    );
    if (selectedAddressIndex >= 0 &&
        selectedAddressIndex < addresses.length) {
      // Заполняем активное поле
      onChange(addresses[selectedAddressIndex], newAddr);
      // Не сбрасываем selectedAddressIndex — пользователь может продолжать корректировать
    } else if (addresses.length < 2) {
      onAdd(newAddr);
    } else {
      // Нет активного поля — обновляем последний адрес (КУДА)
      onChange(addresses.last, newAddr);
    }
  }

  void onAdd(AddressData addr) {
    addresses.add(addr);
    _syncMarkersWithAddresses();
    _schedulePriceCalc();
    update(() {});
  }

  void onChange(AddressData old, AddressData next) {
    final i = addresses.indexOf(old);
    if (i < 0) return;
    addresses
      ..removeAt(i)
      ..insert(i, next);
    _syncMarkersWithAddresses();
    _schedulePriceCalc();
    update(() {});
  }

  void onChangeAtIndex(int index, AddressData next) {
    if (index < 0 || index >= addresses.length) return;
    addresses
      ..removeAt(index)
      ..insert(index, next);
    _syncMarkersWithAddresses();
    _schedulePriceCalc();
    update(() {});
  }

  void onDelete(AddressData addr) {
    addresses.remove(addr);
    if (selectedAddressIndex >= addresses.length) {
      selectedAddressIndex = addresses.length - 1;
    }
    _syncMarkersWithAddresses();
    _schedulePriceCalc();
    update(() {});
  }

  // ─── Тарифы ──────────────────────────────────────────────────────────────

  List<DriveTariff> tariffs = [];
  DriveTariff? selectedTariff;

  void selectTariff(DriveTariff tariff) {
    NewMainScreenAnalytics.tariffSelected(
        tariff.id ?? 0, tariff.title ?? '');
    update(() => selectedTariff = tariff);
  }

  void _schedulePriceCalc() {
    _priceDebounce?.cancel();
    _priceDebounce =
        Timer(const Duration(milliseconds: 500), _doCalculatePrices);
  }

  Future<void> _doCalculatePrices() async {
    if (addresses.length < 2 || !context.mounted) return;
    LoadScreen.showLoad(context, true);
    try {
      NannyMapGlobals.routes.value.clear();
      distance = 0;
      duration = 0;
      for (int i = 0; i < addresses.length - 1; i++) {
        final origin = addresses[i].location;
        final dest = addresses[i + 1].location;
        final polyRes = await PolylinePoints().getRouteBetweenCoordinates(
          NannyConsts.mapKey,
          PointLatLng(origin.latitude, origin.longitude),
          PointLatLng(dest.latitude, dest.longitude),
        );
        distance += SphericalUtils.computeDistanceBetween(
          Point(origin.longitude, origin.latitude),
          Point(dest.longitude, dest.latitude),
        );
        duration += (polyRes.durationValue ?? 0);
        final route = await RouteManager.calculateRoute(
            origin: origin, destination: dest, id: 'route_$i');
        if (route != null) NannyMapGlobals.routes.value.add(route);
      }
      NannyMapGlobals.routes.notifyListeners();
      if (!context.mounted) return;
      distance /= 1000;
      duration /= 60;
      if (distance > 0 && duration > 0) {
        final res = await DioRequest.handle(
            context,
            NannyOrdersApi.getOnetimePrices(
                duration.ceil(), distance.ceil()));
        if (res.success && res.data != null) {
          for (final tar in tariffs) {
            final p = res.data!
                .where((e) => e.id == tar.id)
                .firstOrNull;
            if (p != null) tar.amount = p.amount ?? tar.amount;
          }
        }
      }
    } catch (e) {
      Logger().e('NewClientMainVM._doCalculatePrices: $e');
    } finally {
      if (context.mounted) LoadScreen.showLoad(context, false);
      update(() {});
    }
  }

  // ─── Дети ─────────────────────────────────────────────────────────────────

  List<ChildShort> children = [];
  final Set<int> _selectedChildIds = {};

  List<ChildShort> get selectedChildren =>
      children.where((c) => _selectedChildIds.contains(c.id)).toList();

  bool isChildSelected(ChildShort child) =>
      _selectedChildIds.contains(child.id);

  void toggleChild(ChildShort child, {required void Function(String) showToast}) {
    if (_selectedChildIds.contains(child.id)) {
      _selectedChildIds.remove(child.id);
      NewMainScreenAnalytics.childDeselected(child.id);
      update(() {});
    } else {
      if (_selectedChildIds.length >= _kMaxChildren) {
        NewMainScreenAnalytics.childLimitReached();
        showToast('Можно выбрать не более $_kMaxChildren детей');
        return;
      }
      _selectedChildIds.add(child.id);
      NewMainScreenAnalytics.childSelected(child.id);
      update(() {});
    }
  }

  Future<void> reloadChildren() async {
    final res = await NannyChildrenApi.getChildrenShort();
    if (res.success && res.response != null) {
      children = res.response!;
      // Убираем из выбранных детей, которых больше нет
      final validIds = children.map((c) => c.id).toSet();
      _selectedChildIds.removeWhere((id) => !validIds.contains(id));
      update(() {});
    }
  }

  // ─── Валидация и отправка ─────────────────────────────────────────────────

  bool get canOrder =>
      addresses.length >= 2 && _selectedChildIds.isNotEmpty;

  Future<void> searchForDrivers() async {
    NewMainScreenAnalytics.ctaTapped(
      selectedChildrenCount: _selectedChildIds.length,
      tariffId: selectedTariff?.id,
      addressCount: addresses.length,
    );

    if (addresses.length < 2) {
      _showError('Укажите минимум два адреса');
      return;
    }
    if (_selectedChildIds.isEmpty) {
      _showError('Выберите хотя бы одного ребёнка');
      return;
    }
    if (selectedTariff == null) {
      _showError('Выберите тариф');
      return;
    }
    if (LocationService.curLoc == null) {
      _showError('Не удалось определить ваше местоположение');
      return;
    }

    final driveAddresses = <DriveAddress>[];
    for (int i = 0; i < addresses.length - 1; i++) {
      driveAddresses.add(DriveAddress(
          fromAddress: addresses[i], toAddress: addresses[i + 1]));
    }

    try {
      final res = await DioRequest.handle(
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
          otherParametrs: [],
          childrenIds: _selectedChildIds.toList(),
        )),
      );

      if (!res.success || res.data == null) {
        NewMainScreenAnalytics.orderFailed(res.toString());
        return;
      }
      NewMainScreenAnalytics.orderCreated(res.data!);
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
          builder: (_) => ActiveTripScreen(token: res.data!),
        ),
      );
    } catch (e) {
      Logger().e('NewClientMainVM.searchForDrivers: $e');
      NewMainScreenAnalytics.orderFailed(e.toString());
      if (context.mounted) {
        _showError('Не удалось создать заказ: $e');
      }
    }
  }

  void _showError(String msg) {
    if (context.mounted) {
      NannyDialogs.showMessageBox(context, 'Ошибка', msg);
    }
  }

  // ─── loadPage (вызывается FutureLoader / ViewModelBase) ───────────────────

  @override
  Future<bool> loadPage() async {
    NewMainScreenAnalytics.screenOpened();

    final tariffsRes = await NannyStaticDataApi.getTariffs();
    if (!tariffsRes.success) {
      NewMainScreenAnalytics.loadFailed('tariffs', tariffsRes.toString());
      return false;
    }
    tariffs = tariffsRes.response!;
    if (tariffs.isNotEmpty) selectedTariff = tariffs.first;

    final childrenRes = await NannyChildrenApi.getChildrenShort();
    if (childrenRes.success && childrenRes.response != null) {
      children = childrenRes.response!;
    } else {
      NewMainScreenAnalytics.loadFailed('children', childrenRes.toString());
    }

    return true;
  }

  @override
  void dispose() {
    _mapTapSub?.cancel();
    _priceDebounce?.cancel();
  }
}
