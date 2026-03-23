import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class DioRequest {
  static late final Dio dio;
  static String _authToken = "";
  static String get authToken => _authToken;
  static late Timer tokenReloader;
  static void init({bool useOldUrl = false}) {
    dio = Dio(BaseOptions(
      baseUrl: useOldUrl ? NannyConsts.baseUrlOld : NannyConsts.baseUrl,
      headers: {"Content-Type": "application/json"},
      validateStatus: (status) => status != null,
    ));

    dio.interceptors.add(ErrorInterceptor());
  }

  static void initDebugLogs() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        Logger().d(
            "Sending request to ${options.path} with data:\n${options.data.toString()}");

        handler.next(options);
      },
      onResponse: (response, handler) {
        Logger().d(
            "Got response from ${response.requestOptions.path} with data:\n${response.data.toString()}");

        handler.next(response);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          deleteToken();
          NannyAuthApi.reloadAccess().then((v) async {
            if (v.success && v.response != null) {
              var token = v.response!;
              updateToken(token);
              handler.resolve(await dio.fetch(e.requestOptions));
            }
          });
        }
        Logger().e("Got error on path ${e.requestOptions.path} "
            "with error code ${e.response?.statusCode ?? "NO ERROR CODE"} "
            "and message ${e.message != null ? "\"${e.message}\"" : "NO MESSAGE"} "
            "with data:\n${e.requestOptions.data}\n"
            "and response body: ${e.response?.data.toString()}");

        handler.next(e);
      },
    ));
  }

  static void updateToken(String token) {
    dio.options.headers.removeWhere((key, value) => key == "Authorization");
    dio.options.headers.addAll({"Authorization": "Bearer $token"});
    _authToken = token;
  }

  static void setupTokenReloader() {
    tokenReloader = Timer.periodic(const Duration(minutes: 14), (_) async {
      String token;

      var reload = await NannyAuthApi.reloadAccess();
      if (reload.response != null) {
        token = reload.response!;
      } else {
        deleteToken();
        var loginData = await NannyStorage.getLoginData();
        if (loginData == null)
          throw Exception(
              "Unhandled token reload error! How did you got here?");

        var login = await NannyAuthApi.login(
          LoginRequest(
              login: loginData.login,
              password: loginData.password,
              fbid: "Пятисотый"),
        );
        token = login.response!;
      }

      updateToken(token);
      Logger().w("Reloaded token");
    });
    Logger().w("Token reloader inited!");
  }

  static void stopTokenReloader() => tokenReloader.cancel();
  static void deleteToken() =>
      dio.options.headers.removeWhere((key, value) => key == "Authorization");

  static Future<bool> handleRequest(
      BuildContext context, Future<ApiResponse> request) async {
    var result = await request;

    if (!result.success) {
      if (!context.mounted) return false;
      LoadScreen.showLoad(context, false);
      NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      return false;
    }

    return true;
  }

  static Future<RequestResult<T>> handle<T>(
      BuildContext context, Future<ApiResponse<T>> request) async {
    LoadScreen.showLoad(context, true);

    var response = await request;
    var result = RequestResult(response);

    if (!result.success) {
      if (!context.mounted) return RequestResult(response);
      LoadScreen.showLoad(context, false);
      NannyDialogs.showMessageBox(context, "Ошибка", response.errorMessage);
      return result;
    }

    if (context.mounted) LoadScreen.showLoad(context, false);
    return result;
  }
}

class RequestResult<T> {
  RequestResult(ApiResponse<T> response) {
    success = response.success;
    data = response.response;
    errorMessage = response.errorMessage;
    statusCode = response.statusCode;
  }

  late bool success;
  T? data;
  late String errorMessage;
  late int statusCode;
}

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode;
    if (status != 200) {
      throw DioException.badResponse(
        statusCode: status!,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    super.onResponse(response, handler);
  }
}
