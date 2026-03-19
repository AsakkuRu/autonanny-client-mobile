import 'dart:io';

import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/base_models/api_response.dart';
import 'package:nanny_core/api/dio_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/map_services/location_service.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';

class GoogleMapApi {
  /// Сначала пробует backend (работает в эмуляторе, где maps.googleapis.com недоступен),
  /// при неудаче — прямой запрос к Google API.
  static Future<ApiResponse<GeocodeData>> reverseGeocode({required LatLng loc, String region = "ru"}) async {
    // 1. Пробуем backend proxy (обходит "Failed host lookup" в Android-эмуляторе)
    final backendRes = await RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.get(
        "maps/reverse_geocode",
        queryParameters: {"lat": loc.latitude, "lng": loc.longitude},
      ),
      onSuccess: (r) => GeocodeData.fromJson(r.data as Map<String, dynamic>),
      defaultErrorMsg: "",
    );
    if (backendRes.success && backendRes.response != null) {
      final data = backendRes.response!;
      if (data.geocodeResults.isNotEmpty) return backendRes;
    }

    // 2. Fallback: прямой запрос к Google (для устройств с доступом в интернет)
    return RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.getUri(
        Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?"
          "latlng=${loc.latitude},${loc.longitude}"
          "&language=ru"
          "&region=$region"
          "&key=${Platform.isAndroid ? NannyConsts.androidMapApiKey : NannyConsts.iosMapApiKey}"
        )
      ),
      onSuccess: (response) => GeocodeData.fromJson(response.data as Map<String, dynamic>),
    );
  }
  static Future<ApiResponse<GeocodeData>> geocode({required String address, String region = "ru"}) async {
    LatLng? northEast, southWest;
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
          .where((c) => c.types.contains(AddressType.locality))
          .toList();
      if (locComponents.isNotEmpty) {
        locality = locComponents.first.shortName;
      }
    }

    // Более узкий bias вокруг текущего города (~20–30 км),
    // и жёсткая привязка по locality, чтобы при вводе «твер»
    // в Москве находилась «Тверская улица», а не город Тверь.
    if (lastLoc != null) {
      const delta = 0.3; // ~20–30 км
      northEast = LatLng(
        lastLoc.latitude + delta,
        lastLoc.longitude + delta,
      );
      southWest = LatLng(
        lastLoc.latitude - delta,
        lastLoc.longitude - delta,
      );
    }

    return RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.getUri(
        Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?"
          "address=${Uri.encodeComponent(address)}"
          "&language=ru"
          "${northEast != null ? "&bounds=${southWest!.latitude},${southWest.longitude}|${northEast.latitude},${northEast.longitude}" : ""}"
          "&region=$region"
          "&components=country:ru${locality.isNotEmpty ? "|locality:${Uri.encodeComponent(locality)}" : ""}"
          "&key=${Platform.isAndroid ? NannyConsts.androidMapApiKey : NannyConsts.iosMapApiKey}"
        )
      ),
      onSuccess: (response) => GeocodeData.fromJson(response.data),
    );
  }
}