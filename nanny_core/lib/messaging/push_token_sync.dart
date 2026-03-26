import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

import '../api/api_models/login_request.dart';
import '../api/dio_request.dart';
import '../api/nanny_auth_api.dart';
import '../nanny_storage.dart';

class PushTokenSync {
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static bool _isSyncing = false;

  static void init() {
    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) {
        unawaited(syncTokenWithBackend(token: token));
      },
      onError: (Object error, StackTrace stackTrace) {
        Logger().e(
          'Failed to listen for Firebase token refresh: $error\n$stackTrace',
        );
      },
    );
  }

  static Future<String> getTokenOrEmpty() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        Logger().w('Firebase returned an empty push token');
        return '';
      }

      return token;
    } catch (error, stackTrace) {
      Logger().e(
        'Failed to get Firebase push token: $error\n$stackTrace',
      );
      return '';
    }
  }

  static Future<void> syncTokenWithBackend({String? token}) async {
    if (_isSyncing) return;

    final deviceToken = token ?? await getTokenOrEmpty();
    if (deviceToken.isEmpty) return;

    await NannyStorage.ready;
    final loginData = await NannyStorage.getLoginData();
    if (loginData == null) return;

    _isSyncing = true;
    try {
      final response = await NannyAuthApi.login(
        LoginRequest(
          login: loginData.login,
          password: loginData.password,
          fbid: deviceToken,
        ),
      );

      if (response.success && response.response != null) {
        DioRequest.updateToken(response.response!);
        Logger().i('Firebase push token synchronized with backend');
        return;
      }

      Logger().w(
        'Firebase push token sync skipped: ${response.errorMessage}',
      );
    } catch (error, stackTrace) {
      Logger().e(
        'Failed to synchronize Firebase push token: $error\n$stackTrace',
      );
    } finally {
      _isSyncing = false;
    }
  }
}
