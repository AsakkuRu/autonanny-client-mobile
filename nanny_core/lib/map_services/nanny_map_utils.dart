import 'dart:math';

import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyMapUtils {
  static Point position2Point(Position pos) =>
      Point(pos.longitude, pos.latitude);
  static Point latLng2Point(LatLng loc) => Point(loc.longitude, loc.latitude);
  static LatLng point2LatLng(Point p) => LatLng(p.y.toDouble(), p.x.toDouble());
  static List<Point> polyline2Points(Polyline route) =>
      route.points.map((e) => Point(e.longitude, e.latitude)).toList();

  static LatLng position2LatLng(Position pos) =>
      LatLng(pos.latitude, pos.longitude);

  static LatLng filterMovement(LatLng curPos, LatLng lastPos,
      {double k = 0.5}) {
    assert(k <= 1 && k >= 0);

    double lat = simpleKalmanFilter(k, curPos.latitude, lastPos.latitude);
    double lng = simpleKalmanFilter(k, curPos.longitude, lastPos.longitude);

    return LatLng(lat, lng);
  }

  static GeocodeFormatResult filterGeocodeData(GeocodeData data) {
    final address = _selectBestAddressResult(data.geocodeResults);
    final formattedAddress = buildStreetAddress(address);

    return GeocodeFormatResult(
      address: address,
      simplifiedAddress: formattedAddress,
    );
  }

  static GeocodeResult _selectBestAddressResult(List<GeocodeResult> results) {
    if (results.isEmpty) {
      return _emptyGeocodeResult();
    }

    for (final result in results) {
      if (result.types.contains(AddressType.streetAddress)) {
        return result;
      }
    }

    for (final result in results) {
      if (_isStreetLike(result) && !_isPointOfInterest(result)) {
        return result;
      }
    }

    for (final result in results) {
      if (!_isPointOfInterest(result)) {
        return result;
      }
    }

    return results.first;
  }

  static bool _isStreetLike(GeocodeResult result) {
    final hasRoute = result.addressComponents.any(
      (component) => component.types.contains(AddressType.route),
    );
    final hasStreetNumber = result.addressComponents.any(
      (component) => component.types.contains(AddressType.streetNumber),
    );
    return hasRoute &&
        (hasStreetNumber ||
            result.types.contains(AddressType.premise) ||
            result.types.contains(AddressType.subpremise));
  }

  static bool _isPointOfInterest(GeocodeResult result) {
    return result.types.contains(AddressType.pointOfInterest);
  }

  static GeocodeResult _emptyGeocodeResult() {
    return GeocodeResult(
      addressComponents: [],
      formattedAddress: '',
      geometry: null,
      placeId: '',
      plusCode: null,
      types: [],
    );
  }

  /// Формируем человекочитаемый адрес по компонентам:
  /// улица + дом (+ город), без названий POI («памятник», «кафе» и т.п.).
  static String buildStreetAddress(GeocodeResult result) {
    String? street;
    String? house;
    String? city;

    for (final c in result.addressComponents) {
      if (c.types.contains(AddressType.route)) {
        street ??= c.longName;
      }
      if (c.types.contains(AddressType.streetNumber)) {
        house ??= c.longName;
      }
      if (c.types.contains(AddressType.locality) ||
          c.types.contains(AddressType.adminArea2) ||
          c.types.contains(AddressType.adminArea1)) {
        city ??= c.longName;
      }
    }

    final parts = <String>[];
    if (street != null) parts.add(street);
    if (house != null) parts.add(house);
    if (city != null) parts.add(city);

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return simplifyAddress(result.formattedAddress);
  }

  static String simplifyAddress(String address) {
    List<String> addressParts = address.split(', ');

    if (addressParts.isEmpty) return address;

    if (addressParts.length > 2) {
      return "${addressParts[0]}, ${addressParts[1]}, ${addressParts[2]}";
    }
    if (addressParts.length > 1) {
      return "${addressParts[0]}, ${addressParts[1]}";
    }

    return addressParts.first;
  }

  /// [k] 0 <= n <= 1
  static double simpleKalmanFilter(
      double k, double curValue, double lastValue) {
    assert(k <= 1 && k >= 0);

    return k * curValue + (1 - k) * lastValue;
  }
}

/// Result of [NannyMapUtils.filterGeocodeData]
class GeocodeFormatResult {
  GeocodeFormatResult({required this.address, required this.simplifiedAddress});

  final GeocodeResult address;
  final String simplifiedAddress;
}
