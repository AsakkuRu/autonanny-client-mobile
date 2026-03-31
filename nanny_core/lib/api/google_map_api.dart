import 'dart:io';

import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/base_models/api_response.dart';
import 'package:nanny_core/api/dio_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/map_services/location_service.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';

class GoogleMapApi {
  /// Сначала пробует backend proxy, затем делает прямой запрос к Google.
  static Future<ApiResponse<GeocodeData>> reverseGeocode({
    required LatLng loc,
    String region = "ru",
  }) async {
    final backendRes = await RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.get(
        "maps/reverse_geocode",
        queryParameters: {"lat": loc.latitude, "lng": loc.longitude},
      ),
      onSuccess: (response) => _normalizeGeocodeData(response.data),
      defaultErrorMsg: "",
    );
    if (backendRes.success &&
        backendRes.response != null &&
        backendRes.response!.geocodeResults.isNotEmpty) {
      return backendRes;
    }

    return RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.getUri(
        Uri.https(
          "maps.googleapis.com",
          "/maps/api/geocode/json",
          {
            "latlng": "${loc.latitude},${loc.longitude}",
            "language": "ru",
            "region": region,
            "key": _googleMapsApiKey,
          },
        ),
      ),
      onSuccess: (response) => _normalizeGeocodeData(response.data),
    );
  }

  static Future<ApiResponse<GeocodeData>> geocode({
    required String address,
    String region = "ru",
  }) async {
    final queryParameters = _buildGeocodeQueryParameters(
      address: address,
      region: region,
    );

    final backendRes = await RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.get(
        "maps/geocode",
        queryParameters: queryParameters,
      ),
      onSuccess: (response) => _normalizeGeocodeData(response.data),
      defaultErrorMsg: "",
    );
    if (backendRes.success &&
        backendRes.response != null &&
        backendRes.response!.geocodeResults.isNotEmpty) {
      return backendRes;
    }

    return RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.getUri(
        Uri.https(
          "maps.googleapis.com",
          "/maps/api/geocode/json",
          {
            ...queryParameters,
            "language": "ru",
            "key": _googleMapsApiKey,
          },
        ),
      ),
      onSuccess: (response) => _normalizeGeocodeData(response.data),
    );
  }

  static Future<ApiResponse<List<String>>> autocomplete({
    required String input,
    String region = "ru",
  }) {
    return RequestBuilder<List<String>>().create(
      dioRequest: DioRequest.dio.get(
        "maps/autocomplete",
        queryParameters: {
          "input": input.trim(),
          "region": region,
          "components": "country:ru",
        },
      ),
      onSuccess: (response) {
        final raw = response.data as Map<String, dynamic>;
        final predictions = (raw["predictions"] as List? ?? const [])
            .whereType<Map>()
            .map((item) => item["description"]?.toString() ?? "")
            .where((value) => value.trim().isNotEmpty)
            .toList(growable: false);
        return predictions;
      },
      defaultErrorMsg: "",
    );
  }

  static Map<String, String> _buildGeocodeQueryParameters({
    required String address,
    required String region,
  }) {
    final queryParameters = <String, String>{
      "address": address.trim(),
      "region": region,
    };

    LatLng? northEast;
    LatLng? southWest;
    String locality = "";

    final lastLocationInfo = LocationService.lastLocationInfo;
    final lastLoc = lastLocationInfo?.address.geometry?.location ??
        (LocationService.curLoc != null
            ? LatLng(
                LocationService.curLoc!.latitude,
                LocationService.curLoc!.longitude,
              )
            : null);

    if (lastLocationInfo != null) {
      final locComponents = lastLocationInfo.address.addressComponents
          .where((component) => component.types.contains(AddressType.locality))
          .toList();
      if (locComponents.isNotEmpty) {
        locality = locComponents.first.shortName;
      }
    }

    if (lastLoc != null) {
      const delta = 0.3;
      northEast = LatLng(
        lastLoc.latitude + delta,
        lastLoc.longitude + delta,
      );
      southWest = LatLng(
        lastLoc.latitude - delta,
        lastLoc.longitude - delta,
      );
      queryParameters["bounds"] =
          "${southWest.latitude},${southWest.longitude}|${northEast.latitude},${northEast.longitude}";
    }

    final components = <String>["country:ru"];
    if (locality.isNotEmpty) {
      components.add("locality:$locality");
    }
    queryParameters["components"] = components.join("|");

    return queryParameters;
  }

  static String get _googleMapsApiKey => Platform.isAndroid
      ? NannyConsts.androidMapApiKey
      : NannyConsts.iosMapApiKey;

  static GeocodeData _normalizeGeocodeData(dynamic rawData) {
    final map = rawData as Map<String, dynamic>;
    final normalized = Map<String, dynamic>.from(map);
    final rawResults = (normalized["results"] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    normalized["results"] = _sortResults(rawResults);
    return GeocodeData.fromJson(normalized);
  }

  static List<Map<String, dynamic>> _sortResults(
    List<Map<String, dynamic>> results,
  ) {
    int rank(Map<String, dynamic> item) {
      final types = (item["types"] as List? ?? const [])
          .map((e) => e.toString())
          .toSet();
      if (types.contains("street_address")) return 0;
      if (types.contains("premise") || types.contains("subpremise")) return 1;
      if (types.contains("route")) return 2;
      if (types.contains("plus_code")) return 3;
      if (types.contains("point_of_interest") || types.contains("establishment")) {
        return 4;
      }
      return 5;
    }

    final sorted = List<Map<String, dynamic>>.from(results);
    sorted.sort((a, b) => rank(a).compareTo(rank(b)));
    return sorted;
  }
}
