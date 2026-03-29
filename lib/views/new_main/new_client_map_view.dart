import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_resolver.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/view_models/pages/map_vm.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
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
  ActiveTripSessionData? _activeTripSession;
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
    if (_activeTripSession != null) {
      return _ActiveTripHomePanel(
        session: _activeTripSession!,
        onOpenTrip: _openActiveTripFromHomePanel,
      );
    }

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
    final activeTrip = await ActiveTripResolver.resolveCurrentActiveTrip();
    if (_active && mounted) {
      setState(() {
        _activeTripSession = activeTrip;
      });
    }
    _restoreChecked = false;
  }

  Future<void> _openActiveTripFromHomePanel() async {
    final session = _activeTripSession;
    if (session == null || session.token.isEmpty || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveTripScreen(token: session.token),
      ),
    );
    await _tryRestoreActiveTrip();
  }
}

class _ActiveTripHomePanel extends StatelessWidget {
  const _ActiveTripHomePanel({
    required this.session,
    required this.onOpenTrip,
  });

  final ActiveTripSessionData session;
  final VoidCallback onOpenTrip;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AutonannySpacing.lg,
        AutonannySpacing.xs,
        AutonannySpacing.lg,
        MediaQuery.of(context).padding.bottom + AutonannySpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AutonannySectionContainer(
            title: 'Поездка уже активна',
            subtitle: _subtitleForStatus(session.statusId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AutonannyInlineBanner(
                  title: 'Откройте текущую поездку',
                  message:
                      'Пока поездка активна, создание нового заказа недоступно.',
                  tone: AutonannyBannerTone.info,
                  leading: AutonannyIcon(AutonannyIcons.route),
                ),
                const SizedBox(height: AutonannySpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AutonannySpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: AutonannyRadii.brMd,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(
                    _statusLabel(session.statusId),
                    style: AutonannyTypography.labelL(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.lg),
                AutonannyButton(
                  label: 'Вернуться к поездке',
                  trailing: const AutonannyIcon(
                    AutonannyIcons.arrowRight,
                    color: Colors.white,
                  ),
                  onPressed: onOpenTrip,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(int? statusId) {
    return switch (statusId) {
      13 || 5 => 'Водитель едет к вам',
      6 || 7 => 'Водитель ожидает вас',
      14 || 15 => 'Поездка уже началась',
      _ => 'Поездка активна',
    };
  }

  String _subtitleForStatus(int? statusId) {
    return switch (statusId) {
      13 || 5 => 'Следите за поездкой и откройте экран активного заказа.',
      6 || 7 => 'Откройте поездку, чтобы пройти встречу и верификацию.',
      14 || 15 => 'Откройте поездку, чтобы видеть маршрут и статусы.',
      _ => 'Откройте текущий заказ вместо создания нового.',
    };
  }
}
