import 'dart:io';

import 'package:dio/dio.dart';
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
        "/maps/reverse_geocode",
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

  /// Поиск адреса в UI: один запрос геокодера, без locality и без bounds вокруг GPS
  /// (как раньше по смыслу, но без жёсткого фильтра по городу из профиля).
  static Future<ApiResponse<GeocodeData>> geocodeForAddressSearch(
    String address,
  ) async {
    // UX-ожидание: по "твер" в Москве сначала "Тверская улица", а не город Тверь.
    // Поэтому сначала пробуем с bias (bounds) и locality из reverse-geocode текущей локации.
    // Если результатов нет — постепенно ослабляем фильтры.
    final strict = await geocode(
      address: address,
      region: "ru",
      includeLocalityInComponents: true,
      includeViewportBounds: true,
    );
    if (strict.success &&
        strict.response != null &&
        strict.response!.geocodeResults.isNotEmpty) {
      return strict;
    }

    final semi = await geocode(
      address: address,
      region: "ru",
      includeLocalityInComponents: false,
      includeViewportBounds: true,
    );
    if (semi.success &&
        semi.response != null &&
        semi.response!.geocodeResults.isNotEmpty) {
      return semi;
    }

    return geocode(
      address: address,
      region: "ru",
      includeLocalityInComponents: false,
      includeViewportBounds: false,
    );
  }

  /// Превращает выбранную подсказку (Places autocomplete description)
  /// в конкретный адрес (первый лучший результат геокодинга).
  static Future<GeocodeResult?> geocodeSuggestion(String description) async {
    try {
      final res = await geocodeForAddressSearch(description);
      if (!res.success || res.response == null) return null;
      final results = res.response!.geocodeResults;
      if (results.isEmpty) return null;
      return results.first;
    } catch (_) {
      return null;
    }
  }

  static Future<ApiResponse<GeocodeData>> geocode({
    required String address,
    String region = "ru",
    bool includeLocalityInComponents = false,
    bool includeViewportBounds = true,
  }) async {
    final queryParameters = _buildGeocodeQueryParameters(
      address: address,
      region: region,
      includeLocalityInComponents: includeLocalityInComponents,
      includeViewportBounds: includeViewportBounds,
    );

    final backendRes = await RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.get(
        "/maps/geocode",
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
    int radiusMeters = 30000,
  }) async {
    List<String> _parse(Response response) {
      final raw = response.data as Map<String, dynamic>;
      return (raw["predictions"] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item["description"]?.toString() ?? "")
          .where((value) => value.trim().isNotEmpty)
          .toList(growable: false);
    }

    final lastLocationInfo = LocationService.lastLocationInfo;
    final lastLoc = lastLocationInfo?.address.geometry?.location ??
        (LocationService.curLoc != null
            ? LatLng(
                LocationService.curLoc!.latitude,
                LocationService.curLoc!.longitude,
              )
            : null);
    final locationParam =
        lastLoc != null ? "${lastLoc.latitude},${lastLoc.longitude}" : null;

    // 1) Предпочитаем backend-proxy (полезно когда в эмуляторе проблемы с DNS).
    final viaBackend = await RequestBuilder<List<String>>().create(
      dioRequest: DioRequest.dio.get(
        "/maps/autocomplete",
        queryParameters: {
          "input": input.trim(),
          "region": region,
          "components": "country:ru",
          if (locationParam != null) "location": locationParam,
          if (locationParam != null) "radius": radiusMeters,
        },
      ),
      onSuccess: _parse,
      defaultErrorMsg: "",
    );
    if (viaBackend.success &&
        viaBackend.response != null &&
        viaBackend.response!.isNotEmpty) {
      return viaBackend;
    }

    // 2) Fallback: прямой Google Places Autocomplete (не зависит от has_access).
    return RequestBuilder<List<String>>().create(
      dioRequest: DioRequest.dio.getUri(
        Uri.https(
          "maps.googleapis.com",
          "/maps/api/place/autocomplete/json",
          {
            "input": input.trim(),
            "language": "ru",
            "region": region,
            "components": "country:ru",
            if (locationParam != null) "location": locationParam,
            if (locationParam != null) "radius": radiusMeters.toString(),
            "key": _googleMapsApiKey,
          },
        ),
      ),
      onSuccess: _parse,
      defaultErrorMsg: "",
    );
  }

  static Map<String, String> _buildGeocodeQueryParameters({
    required String address,
    required String region,
    bool includeLocalityInComponents = false,
    bool includeViewportBounds = true,
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

    if (includeViewportBounds && lastLoc != null) {
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
    if (includeLocalityInComponents && locality.isNotEmpty) {
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
