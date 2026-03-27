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
  static Future<String?>? _tokenRecoveryFuture;
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
      final token = await recoverAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception("Unhandled token reload error! How did you got here?");
      }
      Logger().w("Reloaded token");
    });
    Logger().w("Token reloader inited!");
  }

  static void stopTokenReloader() => tokenReloader.cancel();

  static void deleteToken() {
    dio.options.headers.removeWhere((key, value) => key == "Authorization");
    _authToken = "";
  }

  static Future<String?> recoverAccessToken() async {
    final ongoing = _tokenRecoveryFuture;
    if (ongoing != null) return ongoing;

    final future = _recoverAccessTokenInternal();
    _tokenRecoveryFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_tokenRecoveryFuture, future)) {
        _tokenRecoveryFuture = null;
      }
    }
  }

  static Future<String?> _recoverAccessTokenInternal() async {
    final reloadedToken = await _tryReloadAccessToken();
    if (reloadedToken != null && reloadedToken.isNotEmpty) {
      updateToken(reloadedToken);
      Logger().w("Recovered access token via /auth/reload_access");
      return reloadedToken;
    }

    final loginData = await NannyStorage.getLoginData();
    if (loginData == null) {
      Logger().e("Token recovery failed: no saved login data");
      deleteToken();
      return null;
    }

    try {
      final response = await dio.post(
        "/auth/login",
        data: LoginRequest(
          login: loginData.login,
          password: loginData.password,
          fbid: await PushTokenSync.getTokenOrEmpty(),
        ).toJson(),
        options: Options(extra: {'skipAuthRefresh': true}),
      );

      final token = response.data is Map ? response.data['token'] : null;
      if (response.statusCode == 200 && token is String && token.isNotEmpty) {
        updateToken(token);
        Logger().w("Recovered access token via fallback login");
        return token;
      }
    } catch (e) {
      Logger().e("Fallback login during token recovery failed: $e");
    }

    deleteToken();
    return null;
  }

  static Future<String?> _tryReloadAccessToken() async {
    if (_authToken.isEmpty) return null;

    try {
      final response = await dio.post(
        "/auth/reload_access",
        options: Options(
          headers: {"Authorization": "Bearer $_authToken"},
          extra: {'skipAuthRefresh': true},
        ),
      );

      final token = response.data is Map ? response.data['token'] : null;
      if (response.statusCode == 200 && token is String && token.isNotEmpty) {
        return token;
      }
    } catch (e) {
      Logger().e("reload_access failed during token recovery: $e");
    }

    return null;
  }

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
    final extraAllowed = response.requestOptions.extra['allowStatusCodes'];
    final allowedStatusCodes = <int>{200, 201};
    if (extraAllowed is Iterable) {
      for (final code in extraAllowed) {
        if (code is int) {
          allowedStatusCodes.add(code);
        } else if (code is String) {
          final parsed = int.tryParse(code);
          if (parsed != null) {
            allowedStatusCodes.add(parsed);
          }
        }
      }
    }

    if (status == null || !allowedStatusCodes.contains(status)) {
      throw DioException.badResponse(
        statusCode: status ?? 0,
        requestOptions: response.requestOptions,
        response: response,
      );
    }
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final skipAuthRefresh = err.requestOptions.extra['skipAuthRefresh'] == true;
    final alreadyRetried = err.requestOptions.extra['authRetried'] == true;

    if (statusCode == 401 && !skipAuthRefresh && !alreadyRetried) {
      final token = await DioRequest.recoverAccessToken();
      if (token != null && token.isNotEmpty) {
        final requestOptions = err.requestOptions;
        requestOptions.headers =
            Map<String, dynamic>.from(requestOptions.headers)
              ..['Authorization'] = 'Bearer $token';
        requestOptions.extra = Map<String, dynamic>.from(requestOptions.extra)
          ..['authRetried'] = true;

        try {
          final response = await DioRequest.dio.fetch<dynamic>(requestOptions);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }

    handler.next(err);
  }
}
