import 'package:nanny_core/api/api_models/check_code_request.dart';
import 'package:nanny_core/api/api_models/verify_pass_reset_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyAuthApi {
  static Future<ApiResponse<String>> login(LoginRequest request) async {
    return RequestBuilder<String>().create(
        dioRequest: DioRequest.dio.post("/auth/login", data: request.toJson()),
        onSuccess: (response) => response.data['token'],
        errorCodeMsgs: {
          405: "Пользователь не подтверждён!",
          406: "Пользователь не найден!",
        },
        defaultErrorMsg: "Неверный логин или пароль!");
  }

  static Future<ApiResponse<String>> reloadAccess() async {
    return RequestBuilder<String>().create(
      dioRequest: DioRequest.dio.post("/auth/reload_access"),
      onSuccess: (response) => response.data['token'],
    );
  }

  static Future<ApiResponse<String>> updatePushToken(String fbid) async {
    return RequestBuilder<String>().create(
      dioRequest: DioRequest.dio.post(
        "/auth/update_push_token",
        data: {"fbid": fbid},
      ),
      onSuccess: (response) => response.data['token'],
    );
  }

  static Future<ApiResponse<String>> logout() async {
    return RequestBuilder<String>().create(
      dioRequest: DioRequest.dio.post("/auth/logout"),
    );
  }

  static Future<ApiResponse> getRegCode(String phone) async {
    var data = <String, dynamic>{"phone": phone};
    return RequestBuilder().create(
        dioRequest:
            DioRequest.dio.post("/auth/get_registration_code", data: data),
        errorCodeMsgs: {404: "Пользователь с таким телефоном уже создан!"});
  }

  static Future<ApiResponse> checkRegCode(CheckCodeRequest request) async {
    return RequestBuilder().create(
        dioRequest: DioRequest.dio
            .post("/auth/check_registration_code", data: request.toJson()),
        errorCodeMsgs: {404: "Неверный код!"});
  }

  static Future<ApiResponse> getResetCode(String phone) async {
    var data = <String, dynamic>{"phone": phone};
    return RequestBuilder().create(
        dioRequest: DioRequest.dio.post("/auth/reset-password", data: data),
        errorCodeMsgs: {404: "Пользователя с таким телефоном не существует!"});
  }

  static Future<ApiResponse> checkResetCode(CheckCodeRequest request) async {
    return RequestBuilder().create(
        dioRequest: DioRequest.dio
            .post("/auth/check-reset-password", data: request.toJson()),
        errorCodeMsgs: {404: "Неверный код!"});
  }

  static Future<ApiResponse> verifyResetPassword(
      VerifyPassResetRequest request) async {
    return RequestBuilder().create(
        dioRequest: DioRequest.dio
            .post("/auth/verify-reset-password", data: request.toJson()),
        errorCodeMsgs: {
          404: "Неверный номер телефона!",
          406: "Пользователь не найден!",
        });
  }

  static Future<ApiResponse> regParent(RegParentRequest request) async {
    return RequestBuilder().create(
        dioRequest: DioRequest.dio
            .post("/auth/register_parent", data: request.toJson()),
        errorCodeMsgs: {404: "Неверный номер телефона!"});
  }

  static Future<ApiResponse> regDriver(DriverUserData request) async {
    return RequestBuilder().create(
        dioRequest: DioRequest.dio
            .post("/auth/register_driver", data: request.toJson()),
        errorCodeMsgs: {404: "Неверный номер телефона!"});
  }

  static Future<ApiResponse> setPinCode(String code) async {
    var data = <String, dynamic>{
      "code": Md5Converter.convert(code),
    };
    return RequestBuilder().create(
      dioRequest:
          DioRequest.dio.post("/auth/new_mobile_authentication", data: data),
    );
  }

  static Future<ApiResponse> checkPinCode(String code) async {
    var data = <String, dynamic>{
      "code": Md5Converter.convert(code),
    };
    return RequestBuilder().create(
      dioRequest:
          DioRequest.dio.post("/auth/check_mobile_authentication", data: data),
      errorCodeMsgs: {
        404: "Неверный пин-код!",
        401:
            "Пин-код для этого пользователя не задан или произошла ошибка авторизации",
      },
    );
  }
}
