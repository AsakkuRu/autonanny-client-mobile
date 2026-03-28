import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_client/view_models/pages/map_vm.dart';
import 'package:nanny_components/widgets/map_viewer.dart';
import 'package:nanny_core/nanny_core.dart';

class ClientMapView extends StatefulWidget {
  final bool persistState;

  const ClientMapView({
    super.key,
    required this.persistState,
  });

  @override
  State<ClientMapView> createState() => _ClientMapViewState();
}

class _ClientMapViewState extends State<ClientMapView>
    with AutomaticKeepAliveClientMixin {
  late MapVM vm;

  @override
  void initState() {
    super.initState();
    vm = MapVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    return Scaffold(
      body: FutureBuilder<LatLng>(
        future: vm.initLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(label: 'Загружаем карту');
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return AutonannyErrorState(
              title: 'Не удалось загрузить карту',
              description: snapshot.error?.toString() ??
                  'Попробуйте перезапустить приложение.',
            );
          }

          final data = snapshot.data!;

          return MapViewer(
            onPosPressed: () => vm.mapController,
            body: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: data,
                zoom: 15,
              ),
              onMapCreated: vm.onMapCreated,
              onTap: (latLng) => NannyMapGlobals.mapTapController.add(latLng),
              markers: NannyMapGlobals.markers.value,
              polylines: NannyMapGlobals.routes.value,
            ),
            onPanelBuild: (sc) => vm.scrollController,
            panel: Navigator(
              initialRoute: '/',
              onGenerateRoute: onGen,
            ),
            currentLocName: vm.curLocName,
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;

  Route? onGen(RouteSettings settings) {
    if (settings.name == '/') {
      return MaterialPageRoute(builder: (context) => vm.panel);
    }

    return null;
  }
}
