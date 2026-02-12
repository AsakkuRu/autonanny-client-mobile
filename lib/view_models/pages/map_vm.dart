import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_client/views/map/drive_order.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/nanny_core.dart';

class MapVM extends ViewModelBase {
  MapVM({
    required super.context, 
    required super.update,
  }) {  
    initLoad = initialLoad();

    NannyMapGlobals.markers.addListener(() {
      update(() {});
    });
    NannyMapGlobals.routes.addListener(() {
      update(() {});
    });
  }

  late GoogleMapController mapController;
  late final Future<LatLng> initLoad;
  ScrollController? scrollController; 
  late final StreamSubscription<Position> locChange;

  Position? lastLoc; 
  late Marker curPos;
  final ValueNotifier< Set<Marker> > mapMarkers = NannyMapGlobals.markers;
  String curLocName = "Не определено";

  late Widget _panel;
  Widget get panel => _panel;

  void setPanelView(Widget view) => update(() {
    _panel = view;
  });

  void onMapCreated(GoogleMapController controller) => mapController = controller;

  Future<LatLng> initialLoad() async {
    const defaultLocation = LatLng(55.751244, 37.618423); // Москва
    
    try {
      // Проверяем и запрашиваем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // Если разрешения не даны - используем дефолтную позицию
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        curLocName = 'Москва (разрешите доступ к геолокации)';
        
        _panel = const ErrorView(
          errorText: 'Для использования карты необходимо\n'
            'разрешить доступ к геолокации в настройках'
        );
        
        return defaultLocation;
      }

      // Проверяем включена ли геолокация
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        curLocName = 'Москва (включите геолокацию)';
        _panel = const ErrorView(
          errorText: 'Для использования карты необходимо\n'
            'включить геолокацию в настройках устройства'
        );
        return defaultLocation;
      }

      // Получаем текущую позицию с таймаутом
      Position loc;
      try {
        loc = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        var lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          loc = lastKnown;
        } else {
          try {
            loc = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            ).timeout(const Duration(seconds: 10));
          } catch (_) {
            curLocName = 'Москва (не удалось определить позицию)';
            _panel = const ErrorView(
              errorText: 'Не удалось определить ваше местоположение.\n'
                'Проверьте настройки геолокации.'
            );
            return defaultLocation;
          }
        }
      }
      
      curPos = Marker(
        markerId: NannyConsts.curPosId,
        icon: NannyConsts.curPosIcon,
        anchor: const Offset(.5, .5),
        position: NannyMapUtils.position2LatLng(loc),
      );

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      locChange = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position loc) {
        mapMarkers.value.remove(curPos);

        lastLoc ??= loc;
        var newLoc = NannyMapUtils.filterMovement(
          NannyMapUtils.position2LatLng(loc), 
          NannyMapUtils.position2LatLng(lastLoc!),
        );
        curPos = curPos.copyWith(positionParam: newLoc);
        mapMarkers.value.add(curPos);
        if(context.mounted) update(() {});
      });

      var geocodeData = await GoogleMapApi.reverseGeocode(loc: NannyMapUtils.position2LatLng(loc));

      if(geocodeData.success) {
        var formatedAddress = NannyMapUtils.filterGeocodeData(geocodeData.response!);
        curLocName = formatedAddress.simplifiedAddress;

        _panel = DriveOrderView(
          controller: scrollController,
          initAddress: formatedAddress.address,
        );
      }
      else {
        curLocName = 'Адрес не определён';
        _panel = const ErrorView(
          errorText: 'Не удалось определить адрес.\n'
            'Попробуйте перезапустить приложение.'
        );
      }

      return NannyMapUtils.position2LatLng(loc);
    } catch (e) {
      Logger().e('Map initialLoad error: $e');
      curLocName = 'Москва';
      _panel = const ErrorView(
        errorText: 'Произошла ошибка при загрузке карты.\n'
          'Попробуйте перезапустить приложение.'
      );
      return defaultLocation;
    }
  }
}