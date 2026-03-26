import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_resolver.dart';
import 'package:nanny_client/view_models/pages/map_vm.dart';
import 'package:nanny_client/views/new_main/new_client_main_panel.dart';
import 'package:nanny_client/views/new_main/new_client_main_vm.dart';
import 'package:nanny_components/widgets/map_viewer.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_core.dart';

/// Главный экран нового дизайна с картой.
/// Переиспользует [MapViewer] + логику карты из [MapVM].
/// Заменяет [ClientMapView] при включённом фиче-флаге.
class NewClientMapView extends StatefulWidget {
  const NewClientMapView({super.key});

  @override
  State<NewClientMapView> createState() => _NewClientMapViewState();
}

class _NewClientMapViewState extends State<NewClientMapView> {
  late MapVM _mapVm;
  bool _active = true;

  void _safeSetState(VoidCallback fn) {
    if (_active && mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _mapVm = MapVM(context: context, update: _safeSetState);
  }

  @override
  void dispose() {
    _active = false;
    try {
      _mapVm.locChange.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<LatLng>(
        future: _mapVm.initLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(
              label: 'Подготавливаем карту...',
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return AutonannyErrorState(
              title: 'Не удалось открыть карту',
              description: snapshot.error?.toString() ??
                  'Попробуйте перезапустить экран или проверить подключение.',
            );
          }

          return _MapBody(
            mapVm: _mapVm,
            initialPos: snapshot.data!,
          );
        },
      ),
    );
  }
}

// ─── Тело с картой ───────────────────────────────────────────────────────────

class _MapBody extends StatefulWidget {
  final MapVM mapVm;
  final LatLng initialPos;

  const _MapBody({required this.mapVm, required this.initialPos});

  @override
  State<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<_MapBody> {
  NewClientMainVM? _mainVm;
  bool _active = true;
  bool _restoreChecked = false;
  // Сохраняем Future чтобы FutureBuilder не пересоздавал его при каждом rebuild
  late final Future<GeocodeResult?> _geocodeFuture;

  void _safeSetState(VoidCallback fn) {
    if (_active && mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _geocodeFuture = _resolveCurrentGeocode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryRestoreActiveTrip();
    });
  }

  @override
  void dispose() {
    _active = false;
    _mainVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<Marker>>(
      valueListenable: widget.mapVm.mapMarkers,
      builder: (context, markers, _) {
        return ValueListenableBuilder<Set<Polyline>>(
          valueListenable: NannyMapGlobals.routes,
          builder: (context, routes, _) {
            // Верхняя панель с приветствием и кнопками перекрывает часть карты.
            // Фиксированное top padding + динамическое bottom padding по высоте
            // сдвижной панели дают центр по видимой области карты.
            final topPadding = MediaQuery.of(context).padding.top + 72.0;

            return MapViewer(
              body: const SizedBox.shrink(),
              bodyBuilder: (panelHeight) => GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.initialPos,
                  zoom: 14,
                ),
                markers: markers,
                polylines: routes,
                onMapCreated: widget.mapVm.onMapCreated,
                onTap: (latLng) => NannyMapGlobals.mapTapController.add(latLng),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                padding: EdgeInsets.only(
                  top: topPadding,
                  bottom: panelHeight,
                ),
              ),
              panel: _buildPanelWidget(),
              currentLocName: widget.mapVm.curLocName,
              minExtent: 0.12,
              maxExtent: 0.67,
              initialExtent: 1.0,
              adaptToContent: true,
              onPosPressed: () => widget.mapVm.mapController,
            );
          },
        );
      },
    );
  }

  Widget _buildPanelWidget() {
    if (_mainVm != null) {
      return NewClientMainPanel(vm: _mainVm!);
    }

    return FutureBuilder<GeocodeResult?>(
      future: _geocodeFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AutonannySpacing.xxl),
            child: AutonannyLoadingState(
              label: 'Определяем текущий адрес...',
            ),
          );
        }
        if (snap.data == null) {
          return const AutonannyErrorState(
            title: 'Не удалось определить адрес',
            description:
                'Проверьте подключение к интернету и настройки геолокации.',
          );
        }
        _mainVm = NewClientMainVM(
          context: context,
          update: _safeSetState,
          initAddress: snap.data!,
        );
        return NewClientMainPanel(vm: _mainVm!);
      },
    );
  }

  Future<GeocodeResult?> _resolveCurrentGeocode() async {
    try {
      final curLoc = LocationService.curLoc;
      if (curLoc == null) return null;
      final res = await GoogleMapApi.reverseGeocode(
          loc: NannyMapUtils.position2LatLng(curLoc));
      if (res.success && res.response != null) {
        return NannyMapUtils.filterGeocodeData(res.response!).address;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _tryRestoreActiveTrip() async {
    if (!_active || !mounted || _restoreChecked) return;
    _restoreChecked = true;
    await ActiveTripResolver.resolveCurrentActiveTrip();
    _restoreChecked = false;
  }
}
