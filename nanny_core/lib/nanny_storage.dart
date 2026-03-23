import 'dart:async';

import 'package:nanny_core/nanny_core.dart';

class NannyStorage {
  static late final LocalStorage _storage;
  static Future<void> _pending = Future.value();
  static Future<bool> get ready => _storage.ready;

  static Future<T> _serialized<T>(FutureOr<T> Function() action) {
    final operation =
        _pending.catchError((_) {}).then<T>((_) => Future.sync(action));
    _pending = operation.then<void>((_) {}).catchError((_) {});
    return operation;
  }

  static Future<bool> init({required bool isClient}) {
    _storage =
        LocalStorage(isClient ? "nanny_data.json" : "nanny_driver_data.json");
    return _storage.ready;
  }

  static Future<void> updateLoginData(LoginStorageData data) async {
    await _serialized(() => _storage.setItem('login_data', data.toJson()));
  }

  static Future<void> removeLoginData() async =>
      await _serialized(() => _storage.deleteItem('login_data'));

  static Future<LoginStorageData?> getLoginData() async {
    final Map<String, dynamic>? data =
        await _serialized(() => _storage.getItem('login_data'));
    if (data == null) return null;

    return LoginStorageData.fromJson(data);
  }

  static Future<void> updateSettingsData(SettingsStorageData data) async {
    await _serialized(() => _storage.setItem('settings_data', data.toJson()));
  }

  static Future<SettingsStorageData?> getSettingsData() async {
    final Map<String, dynamic>? data =
        await _serialized(() => _storage.getItem('settings_data'));
    if (data == null) return null;

    return SettingsStorageData.fromJson(data);
  }

  static Future<void> cacheSchedules(List<dynamic> schedulesJson) async {
    await _serialized(
        () => _storage.setItem('cached_schedules', schedulesJson));
  }

  static Future<List<dynamic>?> getCachedSchedules() async {
    return await _serialized(() => _storage.getItem('cached_schedules'));
  }

  static Future<void> cacheResponses(List<dynamic> responsesJson) async {
    await _serialized(
        () => _storage.setItem('cached_responses', responsesJson));
  }

  static Future<List<dynamic>?> getCachedResponses() async {
    return await _serialized(() => _storage.getItem('cached_responses'));
  }

  static Future<void> setCustomItem(String key, dynamic value) async {
    await _serialized(() => _storage.setItem(key, value));
  }

  static Future<T?> getCustomItem<T>(String key) async {
    final data = await _serialized(() => _storage.getItem(key));
    if (data is T) return data;
    return null;
  }

  static Future<void> deleteCustomItem(String key) async {
    await _serialized(() => _storage.deleteItem(key));
  }
}
