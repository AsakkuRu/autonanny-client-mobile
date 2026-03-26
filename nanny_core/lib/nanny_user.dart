import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyUser {
  static Future<bool> get isLoggedIn async =>
      userInfo != null && (await NannyUsersApi.getMe()).success;

  static UserInfo? userInfo;

  static Future<ApiResponse> login(LoginRequest request) async {
    var login = await NannyAuthApi.login(request);
    if (!login.success) return login;

    DioRequest.updateToken(login.response!);
    DioRequest.setupTokenReloader();

    return getMe();
  }

  static Future<bool> oauthLogin(String token, BuildContext context) async {
    DioRequest.updateToken(token);
    DioRequest.setupTokenReloader();

    if (!(await getMe()).success) {
      throw Exception("Login error! No user info");
    }

    for (var p in NannyConsts.availablePaths) {
      for (var r in userInfo!.role) {
        if (p.userType == r) {
          // if(!data.haveSetPincode) return FirstPinSet(nextView: p.path);
          // return PinLoginView(nextView: p.path, logoutView: defaultView);

          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => p.path));
          return true;
        }
      }
    }

    // throw Exception("Как ты вообще сюда попал?");
    return false;
  }

  static Future<ApiResponse<UserInfo>> getMe() async {
    var getMe = await NannyUsersApi.getMe();

    if (getMe.success) userInfo = getMe.response;

    return getMe;
  }

  static Future<ApiResponse> logout() async {
    var logout = await NannyAuthApi.logout();
    if (!logout.success) return logout;

    DioRequest.deleteToken();
    DioRequest.stopTokenReloader();
    NannyStorage.removeLoginData();

    return logout;
  }

  static Future<Widget> autoLogin(
      {required List<LoginPath> paths, required Widget defaultView}) async {
    await NannyStorage.ready;
    var data = await NannyStorage.getLoginData();

    if (data == null) return defaultView;

    var loginResult = await login(
      LoginRequest(
        login: data.login,
        password: data.password,
        fbid: await PushTokenSync.getTokenOrEmpty(),
      ),
    );

    // var me = await getMe();

    // if(!me.success) return defaultView;

    if (!loginResult.success) return defaultView;
    var me = loginResult.response as UserInfo;

    for (var p in paths) {
      for (var r in userInfo!.role) {
        if (p.userType == r) {
          if (!me.hasAuth) return FirstPinSet(nextView: p.path);
          return PinLoginView(nextView: p.path, logoutView: defaultView);
        }
      }
    }

    return defaultView;
  }

  // static UserInfo<Driver> asDriver() {
  //   userInfo = userInfo as UserInfo<Driver>;
  //   userInfo!.roleData = Driver.fromJson(userInfo!.jsonData);

  //   return userInfo as UserInfo<Driver>;
  // }
}

/*
{
	"surname": "string",
	"name": "string",
	"inn": "string",
	"photo_path": "string",
	"video_path": "string",
	"date_reg": "string"
}
*/
