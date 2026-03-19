import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/map_services/nanny_map_utils.dart';

class LocationService {
  static Position? curLoc;
  static StreamSubscription<Position>? _locSub;
  static GeocodeFormatResult? lastLocationInfo;

  static Future<void> initBackgroundLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

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

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      curLoc = position;
    });
  }

  static Future<GeocodeFormatResult?> getLocationInfo(LatLng latLng) async {
    var data = await GoogleMapApi.reverseGeocode(loc: latLng);

    if (!data.success) return null;
    return NannyMapUtils.filterGeocodeData(data.response!);
  }

  static Future<void> initLocInfo() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      lastLocationInfo = await getLocationInfo(
        LatLng(position.latitude, position.longitude),
      );
    } catch (_) {
      // игнорируем ошибки геолокации, просто не задаём bias
    }
  }

  static void dispose() {
    _locSub?.cancel();
  }
}