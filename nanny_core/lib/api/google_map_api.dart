import 'dart:io';

import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/base_models/api_response.dart';
import 'package:nanny_core/api/dio_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/map_services/location_service.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';

class GoogleMapApi {
  static Future<ApiResponse<GeocodeData>> reverseGeocode({required LatLng loc, String region = "ru"}) async {
    return RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.getUri(
        Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?"
          "latlng=${loc.latitude},${loc.longitude}"
          "&language=ru"
          "&region=$region"
          "&key=${Platform.isAndroid ? NannyConsts.androidMapApiKey : NannyConsts.iosMapApiKey}"
        )
      ),
      onSuccess: (response) => GeocodeData.fromJson(response.data),
    );
  }
  static Future<ApiResponse<GeocodeData>> geocode({required String address, String region = "ru"}) async {
    LatLng? northEast, southWest;
    final lastLoc = LocationService.lastLocationInfo?.address.geometry?.location;
    if(lastLoc != null) {
      northEast = LatLng(
        lastLoc.latitude + 1.5, 
        lastLoc.longitude + 1.5,
      );
      southWest = LatLng(
        lastLoc.latitude - 1.5,
        lastLoc.longitude - 1.5,
      );
    }

    return RequestBuilder<GeocodeData>().create(
      dioRequest: DioRequest.dio.getUri(
        Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?"
          "address=${Uri.encodeComponent(address)}"
          "&language=ru"
          "${northEast != null ? "&bounds=${southWest!.latitude},${southWest.longitude}|${northEast.latitude},${northEast.longitude}" : ""}"
          "&region=$region"
          "&key=${Platform.isAndroid ? NannyConsts.androidMapApiKey : NannyConsts.iosMapApiKey}"
        )
      ),
      onSuccess: (response) => GeocodeData.fromJson(response.data),
    );
  }
}