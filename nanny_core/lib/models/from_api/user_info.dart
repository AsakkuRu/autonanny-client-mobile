import 'package:nanny_core/models/from_api/roles/referal_data.dart';
import 'package:nanny_core/nanny_core.dart';

class UserInfo<T> {
  UserInfo({
    required this.surname,
    required this.name,
    required this.phone,
    required this.role,
    // required this.inn,
    required this.photoPath,
    required this.videoPath,
    this.chatToken = "",
    this.dateReg = "",
    this.jsonData = const {},
    this.roleData,
    this.id = 0,
    this.status = UserStatus.unrecognized,
    this.isActive = false,
    this.hasAuth = false,
  });

  final int id;
  final String chatToken;

  final String surname;
  final String name;
  final String phone;
  final List<UserType> role;
  // final String inn;
  final String photoPath;
  final String videoPath;
  final String dateReg;

  final UserStatus status;
  final bool isActive;
  final bool hasAuth;

  T? roleData;

  final Map<String, dynamic> jsonData;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    List<UserType> userTypes = [];
    List<String> roles = [];

    if (json['role'] != null) {
      for (var role in json['role']) {
        if (role is String) {
          roles.add(role);
        } else if (role is int) {
          final userType = UserType.fromId(role);
          if (userType != null) {
            roles.add(userType.name);
          }
        }
      }
    }

    userTypes = UserType.values.where((e) => roles.contains(e.name)).toList();

    String photo = json["photo_path"] ?? "";
    photo = photo
        .replaceAll("https://77.232.137.74:5000/api/v1.0", NannyConsts.baseUrl)
        .replaceAll("http://188.225.76.45:8000/api/v1.0", NannyConsts.baseUrl);

    return UserInfo(
      id: json["id"] ?? json["id_user_referal"] ?? 0,
      chatToken: json["token"] ?? "",
      surname: json["surname"] ?? "",
      name: json["name"] ?? "",
      phone: (json["phone"] as String?)?.replaceAll("+", "") ?? "",
      role: userTypes,
      // inn: json["inn"] ?? "",
      photoPath: photo,
      videoPath: json["video_path"] ?? "",
      dateReg: json["date_reg"] ?? json["datetime_create"] ?? "",
      status: UserStatus.values.firstWhere((e) => e.name == json["status"],
          orElse: () => UserStatus.unrecognized),
      isActive: json['isActive'] ?? false,
      hasAuth: json["hasAuth"] ?? false,
      jsonData: json,
    );
  }

  factory UserInfo.createDriverRegForm() => UserInfo(
        surname: "",
        name: "",
        phone: "",
        role: [UserType.driver],
        // inn: "",
        photoPath: "",
        videoPath: "",
      );

  Map<String, dynamic> toJson() => {
        "surname": surname,
        "name": name,
        "phone": phone,
        // "inn": inn,
        "photo_path": photoPath,
        "video_path": videoPath,
        "date_reg": dateReg,
      };

  UserInfo<E> copyWith<E>(
      {int? id,
      String? surname,
      String? name,
      String? phone,
      List<UserType>? role,
      // String? inn,
      String? photoPath,
      String? videoPath,
      String? dateReg,
      UserStatus? status,
      bool? isActive,
      E? roleData,
      Map<String, dynamic>? getMeJson}) {
    return UserInfo<E>(
      id: id ?? this.id,
      chatToken: this.chatToken,
      surname: surname ?? this.surname,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      // inn: inn ?? this.inn,
      photoPath: photoPath ?? this.photoPath,
      videoPath: videoPath ?? this.videoPath,
      dateReg: dateReg ?? this.dateReg,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      roleData: roleData ?? this.roleData as E,
      jsonData: getMeJson ?? this.jsonData,
    );
  }

  UserInfo<Driver> asDriver() {
    return copyWith<Driver>(
      roleData: Driver.fromJson(jsonData),
    );
  }

  UserInfo<Partner> asPartner() {
    return copyWith<Partner>(roleData: Partner.fromJson(jsonData));
  }

  UserInfo<Referal> asReferal() {
    return copyWith<Referal>(roleData: Referal.fromJson(jsonData));
  }
}
