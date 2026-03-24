import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/widgets/map/full_screen_map_address_picker.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_core.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late ActiveTripVM vm;
  bool _isQrDialogOpen = false;

  @override
  void initState() {
    super.initState();
    vm = ActiveTripVM(
      context: context,
      update: setState,
      initialToken: widget.token,
      onTripStarted: () {
        if (_isQrDialogOpen && mounted) {
          Navigator.of(context).pop();
          _isQrDialogOpen = false;
        }
      },
    );
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
      completeView: (context, _) {
        return Scaffold(
          backgroundColor: NDT.neutral100,
          body: Stack(
            children: [
              _LiveTripMap(vm: vm),
              Positioned(
                left: 16,
                top: MediaQuery.of(context).padding.top + 12,
                child: _BackToAppButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 12,
                child: _SosButton(onPressed: _showSosDialog),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TripSheet(
                  vm: vm,
                  onCancelPressed: _showCancelDialog,
                  onChangeRoutePressed: _showChangeRouteSheet,
                  onDonePressed: () => Navigator.of(context).pop(),
                  onShowQRPressed: _showMeetingCodeQR,
                ),
              ),
            ],
          ),
        );
      },
      errorView: (context, error) => ErrorView(errorText: error.toString()),
    );
  }

  Future<void> _showSosDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Вызов SOS', style: NDT.h2.copyWith(color: NDT.neutral900)),
              const SizedBox(height: 8),
              Text(
                'Будет отправлен сигнал администратору и экстренным контактам.',
                style: NDT.bodyM.copyWith(color: NDT.neutral500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              NdPrimaryButton(
                label: 'Подтвердить SOS',
                onTap: () async {
                  Navigator.of(context).pop();
                  await vm.confirmSos();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена — все хорошо'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMeetingCodeQR() async {
    if (vm.isBusy) return;
    final data = await vm.fetchMeetingCodeForTrip();
    if (!mounted) return;
    if (data == null) {
      NannyDialogs.showMessageBox(
        context,
        'Код недоступен',
        'Водитель ещё не сгенерировал код. Попросите водителя нажать «Включить режим ожидания» в приложении.',
      );
      return;
    }
    final meetingCode = data['meeting_code'] as String?;
    final orderId = data['order_id'] as int?;
    final scheduleRoadId = data['schedule_road_id'] as int?;
    final verificationScope = data['verification_scope'] as String? ?? 'order';
    if (meetingCode == null || meetingCode.isEmpty) {
      NannyDialogs.showMessageBox(
        context,
        'Код недоступен',
        'Водитель ещё не сгенерировал код. Попросите водителя нажать «Включить режим ожидания» в приложении.',
      );
      return;
    }
    final String qrData;
    if (verificationScope == 'schedule' && scheduleRoadId != null) {
      qrData = 'schedule:$scheduleRoadId:$meetingCode';
    } else if (orderId != null) {
      qrData = 'order:$orderId:$meetingCode';
    } else {
      NannyDialogs.showMessageBox(
        context,
        'Код недоступен',
        'Не удалось определить тип поездки для верификации.',
      );
      return;
    }
    _isQrDialogOpen = true;
    await DriverQRDialog.show(
      context,
      driverName: 'Водитель',
      qrData: qrData,
      meetingCodePin: meetingCode,
    );
    if (mounted) _isQrDialogOpen = false;
  }

  Future<void> _showCancelDialog() async {
    final approve = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отмена поездки'),
        // FIX-007: предупреждение о штрафе если водитель уже прибыл
        content: Text(
          vm.isArrived
              ? 'Водитель уже прибыл и ожидает. При отмене будет удержан штраф 50% от стоимости поездки.'
              : 'Подтвердите отмену поездки.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Не отменять'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
    if (approve != true) return;
    final cancelled = await vm.cancelSearchOrTrip();
    if (cancelled && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showChangeRouteSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Изменить маршрут', style: NDT.h2),
              const SizedBox(height: 16),
              NdPrimaryButton(
                label: 'Поиск по адресу',
                onTap: () => Navigator.of(ctx).pop('search'),
              ),
              const SizedBox(height: 12),
              SizedBox(
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

    if (choice == null || !mounted) return;

    AddressData? selected;
    if (choice == 'map') {
      selected = await Navigator.of(context).push<AddressData>(
        MaterialPageRoute(
          builder: (_) => const FullScreenMapAddressPicker(),
        ),
      );
    } else {
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
      if (result != null) {
        final location = result.geometry?.location;
        if (location != null) {
          selected = AddressData(
            address: NannyMapUtils.buildStreetAddress(result),
            location: location,
          );
        }
      }
    }

    if (selected == null || !mounted) return;

    final ok = await vm.submitRouteChange(
      vm.buildRouteChangePayload(selected),
    );
    if (!mounted) return;
    NannyDialogs.showMessageBox(
      context,
      ok ? 'Готово' : 'Ошибка',
      ok
          ? 'Изменение маршрута отправлено водителю.'
          : 'Не удалось отправить изменение маршрута.',
    );
  }
}

class _LiveTripMap extends StatefulWidget {
  const _LiveTripMap({required this.vm});

  final ActiveTripVM vm;

  @override
  State<_LiveTripMap> createState() => _LiveTripMapState();
}

class _LiveTripMapState extends State<_LiveTripMap> {
  GoogleMapController? _controller;
  LatLng? _lastAnimatedDriver;

  @override
  void didUpdateWidget(covariant _LiveTripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAnimateToDriver();
  }

  void _maybeAnimateToDriver() {
    final driver = _driverLatLng();
    if (driver == null || _controller == null) return;
    if (_lastAnimatedDriver != null &&
        (_lastAnimatedDriver!.latitude - driver.latitude).abs() < 0.0001 &&
        (_lastAnimatedDriver!.longitude - driver.longitude).abs() < 0.0001) {
      return;
    }
    _lastAnimatedDriver = driver;
    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: driver, zoom: 15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _resolveCenter();
    final markers = _buildMarkers();
    final bottomPanelHeight = MediaQuery.of(context).size.height * 0.42;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: mapCenter, zoom: 14),
          onMapCreated: (c) {
            _controller = c;
            _maybeAnimateToDriver();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: markers,
          polylines: widget.vm.routePolylines,
          padding: EdgeInsets.only(bottom: bottomPanelHeight),
        ),
        if (widget.vm.etaMinutes != null)
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: NDT.primary,
                borderRadius: NDT.brMd,
              ),
              child: Text(
                '${widget.vm.etaMinutes} мин',
                style: NDT.h3.copyWith(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).padding.top + 66,
          child: GestureDetector(
            onTap: () async {
              final driver = _driverLatLng();
              if (driver != null) {
                await _controller?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: driver, zoom: 15),
                  ),
                );
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded, color: NDT.primary),
            ),
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers() {
    final result = <Marker>{};

    // Show nearby available drivers during search.
    if (widget.vm.isSearching && widget.vm.nearbyDrivers.isNotEmpty) {
      for (final driver in widget.vm.nearbyDrivers) {
        final lat = _toDouble(driver['latitude'] ?? driver['lat']);
        final lon = _toDouble(driver['longitude'] ?? driver['lon']);
        final id = driver['id_driver'] ?? driver['id'] ?? '${lat}_$lon';
        if (lat == null || lon == null) continue;
        result.add(
          Marker(
            markerId: MarkerId('nearby_driver_$id'),
            position: LatLng(lat, lon),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            infoWindow: const InfoWindow(title: 'Доступный водитель'),
          ),
        );
      }
    }

    final driver = _driverLatLng();
    if (driver != null) {
      result.add(
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: driver,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Водитель'),
        ),
      );
    }

    final routePoints = _routePoints();
    for (var i = 0; i < routePoints.length; i++) {
      final point = routePoints[i];
      final markerHue = i == 0
          ? BitmapDescriptor.hueBlue
          : i == routePoints.length - 1
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueOrange;
      final markerTitle = i == 0
          ? 'Откуда'
          : i == routePoints.length - 1
              ? 'Куда'
              : 'Промежуточная точка $i';
      result.add(
        Marker(
          markerId: MarkerId('route_point_$i'),
          position: point.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          infoWindow: InfoWindow(title: markerTitle, snippet: point.label),
        ),
      );
    }
    return result;
  }

  LatLng _resolveCenter() {
    final driver = _driverLatLng();
    if (driver != null) return driver;
    final routePoints = _routePoints();
    if (routePoints.isNotEmpty) {
      return routePoints.first.position;
    }
    return const LatLng(55.751244, 37.618423);
  }

  List<_RouteDisplayPoint> _routePoints() =>
      _buildRouteDisplayPoints(widget.vm.addresses);

  LatLng? _driverLatLng() {
    final lat = _toDouble(widget.vm.driverLocation?['lat']);
    final lon = _toDouble(widget.vm.driverLocation?['lon']);
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _TripSheet extends StatelessWidget {
  const _TripSheet({
    required this.vm,
    required this.onCancelPressed,
    required this.onChangeRoutePressed,
    required this.onDonePressed,
    required this.onShowQRPressed,
  });

  final ActiveTripVM vm;
  final VoidCallback onCancelPressed;
  final VoidCallback onChangeRoutePressed;
  final VoidCallback onDonePressed;
  final VoidCallback onShowQRPressed;

  @override
  Widget build(BuildContext context) {
    final route = _routeLabel(vm.addresses);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 14),
            Text(vm.statusText, style: NDT.h3),
            const SizedBox(height: 6),
            Text(
              route,
              style: NDT.bodyS.copyWith(color: NDT.neutral500),
            ),
            const SizedBox(height: 12),
            _statusBlocks(),
            if (vm.noDriversFound) ...[
              Text(
                'В вашем районе сейчас нет доступных водителей.',
                style: NDT.bodyM.copyWith(color: NDT.neutral500),
              ),
              const SizedBox(height: 12),
            ],
            if (vm.connectionTimedOut) ...[
              Text(
                'Проблемы соединения. Сессия сохраняется, идет переподключение.',
                style: NDT.bodyM.copyWith(color: NDT.neutral500),
              ),
              const SizedBox(height: 12),
            ],
            // FIX-008: при статусе 2 (водитель отменил) — показываем сообщение и кнопку «Закрыть»
            if (vm.statusId == 2) ...[
              Text(
                'Водитель отменил поездку. Вы можете заказать нового водителя.',
                style: NDT.bodyM.copyWith(color: NDT.neutral500),
              ),
              const SizedBox(height: 12),
              NdPrimaryButton(label: 'Закрыть', onTap: onDonePressed),
            ] else if (vm.isFinished) ...[
              Text(
                'Поездка завершена. Оцените поездку в истории.',
                style: NDT.bodyM.copyWith(color: NDT.neutral500),
              ),
              const SizedBox(height: 12),
              NdPrimaryButton(label: 'Готово', onTap: onDonePressed),
            ] else ...[
              if (vm.isArrived) const SizedBox(height: 24),
              Row(
                children: [
                  if (!vm.isInProgress) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: vm.isBusy ? null : onCancelPressed,
                        child: const Text('Отменить'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // FIX-011: скрываем «Изменить маршрут» когда водитель прибыл (statusId 15)
                  if (vm.statusId != 15)
                    Expanded(
                      child: NdPrimaryButton(
                        label: 'Изменить маршрут',
                        onTap: vm.isBusy ? null : onChangeRoutePressed,
                      ),
                    ),
                ],
              ),
              if (vm.routeChangeStatus.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Статус изменения: ${vm.routeChangeStatus}',
                  style: NDT.bodyS.copyWith(color: NDT.neutral500),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBlocks() {
    if (vm.isSearching) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NDT.neutral100,
            borderRadius: NDT.brMd,
          ),
          child: Text(
            'Ищем ближайшего водителя. Обычно это занимает до 2 минут.',
            style: NDT.bodyS.copyWith(color: NDT.neutral500),
          ),
        ),
      );
    }

    if (vm.isEnRoute) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: _metricCard('До прибытия',
                  vm.etaMinutes != null ? '${vm.etaMinutes} мин' : '—'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard('Статус', 'Едет к вам'),
            ),
          ],
        ),
      );
    }

    if (vm.isArrived) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x14F59E0B),
                borderRadius: NDT.brMd,
                border: Border.all(color: const Color(0x44F59E0B)),
              ),
              child: Text(
                'Водитель прибыл и ожидает у подъезда',
                style: NDT.bodyM.copyWith(color: const Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Покажите QR-код или PIN водителю для верификации. Без подтверждения водитель не сможет начать поездку («Ребёнок в машине»).',
              style: NDT.bodyS.copyWith(color: NDT.neutral500),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: NdPrimaryButton(
                label: 'Показать QR-код',
                onTap: vm.isBusy ? null : onShowQRPressed,
              ),
            ),
          ],
        ),
      );
    }

    if (vm.isInProgress) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: _metricCard('До точки',
                  vm.etaMinutes != null ? '${vm.etaMinutes} мин' : '—'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard('Статус', 'В пути'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _metricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NDT.primary100,
        borderRadius: NDT.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: NDT.caption.copyWith(color: NDT.neutral500)),
          const SizedBox(height: 4),
          Text(value, style: NDT.h3.copyWith(color: NDT.primary)),
        ],
      ),
    );
  }

  String _routeLabel(List<Map<String, dynamic>> addresses) {
    final labels = _buildRouteDisplayPoints(addresses)
        .map((point) => point.label)
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) return 'Маршрут уточняется';
    return labels.join(' → ');
  }
}

class _RouteDisplayPoint {
  const _RouteDisplayPoint({
    required this.label,
    required this.position,
  });

  final String label;
  final LatLng position;
}

List<_RouteDisplayPoint> _buildRouteDisplayPoints(
  List<Map<String, dynamic>> addresses,
) {
  if (addresses.isEmpty) return const [];

  final points = <_RouteDisplayPoint>[];
  final first = addresses.first;
  final firstLabel = (first['from_address'] ?? first['from'] ?? '').toString();
  final firstLat = _routeValueToDouble(first['from_lat']);
  final firstLon = _routeValueToDouble(first['from_lon']);
  if (firstLabel.isNotEmpty && firstLat != null && firstLon != null) {
    points.add(
      _RouteDisplayPoint(
        label: firstLabel,
        position: LatLng(firstLat, firstLon),
      ),
    );
  }

  for (final segment in addresses) {
    final label = (segment['to_address'] ?? segment['to'] ?? '').toString();
    final lat = _routeValueToDouble(segment['to_lat']);
    final lon = _routeValueToDouble(segment['to_lon']);
    if (label.isEmpty || lat == null || lon == null) continue;
    points.add(
      _RouteDisplayPoint(
        label: label,
        position: LatLng(lat, lon),
      ),
    );
  }

  return points;
}

double? _routeValueToDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: NDT.danger,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66EF4444),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _BackToAppButton extends StatelessWidget {
  const _BackToAppButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: NDT.neutral0,
          borderRadius: BorderRadius.circular(12),
          boxShadow: NDT.cardShadow,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: NDT.neutral900,
        ),
      ),
    );
  }
}

class ActiveTripRestoreCoordinator {
  static Future<ActiveTripSessionData?> resolveSession() async {
    return ActiveTripSessionStore.load();
  }
}
