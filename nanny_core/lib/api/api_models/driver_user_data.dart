import 'package:nanny_core/nanny_core.dart';

class DriverUserData implements NannyBaseRequest {
  DriverUserData.createRegForm() {
    driverData = Driver.createRegForm();
    userData = UserInfo.createDriverRegForm();
  }

  DriverUserData({
    required this.driverData,
    required this.userData,
  });

  late Driver driverData;
  late UserInfo userData;
  String password = "";

  @override
  Map<String, dynamic> toJson() {
    var driverJson = driverData.toJson();
    var userJson = userData.toJson();

    Map<String, dynamic> json = {};
    json.addAll(driverJson);
    json.addAll(userJson);
    json.addAll({
      "password": password,
    });
    json.removeWhere((key, value) => value == null);

    json.removeWhere((key, value) => key == "photo_path");
    json.addAll({
      "photoUrl": userData.photoPath,
    });

    json.removeWhere((key, value) => key == "video_path");
    json.addAll({
      "videoUrl": userData.videoPath,
    });

    return json;
  }
}

class DriverUserTextData {
  DriverUserTextData({required this.userData, required this.carDataText});

  UserInfo<Driver> userData;
  final CarDataText carDataText;

  DriverUserTextData.fromJson(Map<String, dynamic> json)
      : userData = UserInfo.fromJson(json),
        carDataText = CarDataText.fromJson(
          Map<String, dynamic>.from(json["carData"] as Map? ?? const {}),
        );
}
