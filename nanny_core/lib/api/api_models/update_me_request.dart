import 'package:nanny_core/api/api_models/base_models/base_request.dart';
import 'package:nanny_core/md5_converter.dart';

class UpdateMeRequest implements NannyBaseRequest {
  UpdateMeRequest(
      {this.lastName,
      this.firstName,
      this.photoPath,
      this.email,
      this.address,
      String? password,
      this.inn}) {
    if (password != null) {
      this.password = Md5Converter.convert(password);
    } else {
      this.password = null;
    }
  }

  final String? lastName;
  final String? firstName;
  final String? photoPath;
  final String? email;
  final String? address;
  late final String? password;
  final int? inn;

  @override
  Map<String, dynamic> toJson() => {
        "surname": lastName,
        "name": firstName,
        "photo_path": photoPath,
        "email": email,
        "address": address,
        "password": password,
        "inn": inn,
      };
}
