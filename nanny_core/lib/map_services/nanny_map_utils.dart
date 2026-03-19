import 'dart:math';

import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyMapUtils {
  static Point position2Point(Position pos) => Point(pos.longitude, pos.latitude);
  static Point latLng2Point(LatLng loc) => Point(loc.longitude, loc.latitude);
  static LatLng point2LatLng(Point p) =>LatLng(p.y.toDouble(), p.x.toDouble());
  static List<Point> polyline2Points(Polyline route) => route.points
    .map((e) => Point(e.longitude, e.latitude))
    .toList();
  
  static LatLng position2LatLng(Position pos) => LatLng(pos.latitude, pos.longitude);

  static LatLng filterMovement(LatLng curPos, LatLng lastPos, {double k = 0.5}) {
    assert(k <= 1 && k >= 0);

    double lat = simpleKalmanFilter(k, curPos.latitude, lastPos.latitude);
    double lng = simpleKalmanFilter(k, curPos.longitude, lastPos.longitude);

    return LatLng(lat, lng);
  }

  static GeocodeFormatResult filterGeocodeData(GeocodeData data) {
    var addresses = data.geocodeResults.where(
      (e) => e.types.contains(AddressType.streetAddress)
    );

    if (addresses.isEmpty) {
      final fallback = data.geocodeResults.first;
      return GeocodeFormatResult(
        address: fallback,
        simplifiedAddress: buildStreetAddress(fallback),
      );
    }

    final address = addresses.first;
    final formattedAddress = buildStreetAddress(address);

    return GeocodeFormatResult(
      address: address,
      simplifiedAddress: formattedAddress,
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

    // Fallback на старую логику, если что‑то пошло не так.
    return simplifyAddress(result.formattedAddress);
  }

  static String simplifyAddress(String address) {
    List<String> addressParts = address.split(', ');

    if(addressParts.isEmpty) return address;

    if(addressParts.length > 2) { 
      return "${addressParts[0]}, ${addressParts[1]}, ${addressParts[2]}";
    }
    if(addressParts.length > 1) { 
      return "${addressParts[0]}, ${addressParts[1]}";
    }

    return addressParts.first;
  }

  /// [k] 0 <= n <= 1
  static double simpleKalmanFilter(double k, double curValue, double lastValue) {
    assert(k <= 1 && k >= 0);

    return k * curValue + (1 - k) * lastValue;
  }
}

/// Result of [NannyMapUtils.filterGeocodeData]
class GeocodeFormatResult {
  GeocodeFormatResult({
    required this.address,
    required this.simplifiedAddress
  });

  final GeocodeResult address;
  final String simplifiedAddress;
}