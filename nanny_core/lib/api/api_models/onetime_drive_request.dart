import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/nanny_core.dart';

class OnetimeDriveRequest implements NannyBaseRequest {
    OnetimeDriveRequest({
        required this.myLocation,
        required this.addresses,
        required this.price,
        required this.distance,
        required this.duration,
        required this.description,
        required this.typeDrive,
        required this.idTariff,
        required this.otherParametrs,
    });

    final Position? myLocation;
    final List<DriveAddress> addresses;
    final int price;
    final int distance;
    final int duration;
    final String description;
    final int typeDrive;
    final int idTariff;
    final List<Map<String, dynamic>> otherParametrs;

    // factory OnetimeDriveRequest.fromJson(Map<String, dynamic> json){ 
    //     return OnetimeDriveRequest(
    //         myLocation: json["my_location"] == null ? null : Location.fromJson(json["my_location"]),
    //         addresses: json["addresses"] == null ? [] : List<DriveAddress>.from(json["addresses"]!.map((x) => DriveAddress.fromJson(x))),
    //         price: json["price"] ?? 0,
    //         distance: json["distance"] ?? 0,
    //         duration: json["duration"] ?? 0,
    //         description: json["description"] ?? "",
    //         typeDrive: json["typeDrive"] ?? 0,
    //         idTariff: json["idTariff"] ?? 0,
    //         otherParametrs: json["other_parametrs"] == null ? [] : List<dynamic>.from(json["other_parametrs"]!.map((x) => x)),
    //     );
    // }

    @override
    Map<String, dynamic> toJson() => {
        "my_location": myLocation != null ? {
          "latitude": myLocation!.latitude,
          "longitude": myLocation!.longitude
        } : {"latitude": 0, "longitude": 0},
        "addresses": addresses.map((x) => x.toJson()).toList(),
        "price": price,
        "distance": distance,
        "duration": duration,
        "description": description,
        "type_drive": typeDrive,
        "idTariff": idTariff,
        "other_parametrs": otherParametrs,
    };
}

/*
{
	"my_location": {
		"latitude": 0,
		"longitude": 0
	},
	"addresses": [
		{
			"from_address": {
				"address": "string",
				"location": {
					"latitude": 0,
					"longitude": 0
				}
			},
			"to_address": {
				"address": "string",
				"location": {
					"latitude": 0,
					"longitude": 0
				}
			}
		}
	],
	"price": 0,
	"distance": 0,
	"duration": 0,
	"description": "string",
	"typeDrive": 0,
	"idTariff": 0,
	"other_parametrs": []
}*/