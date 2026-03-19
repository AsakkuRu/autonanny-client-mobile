import 'package:nanny_core/storage_models/base_storage.dart';

class SettingsStorageData implements BaseStorage {
  SettingsStorageData({
    required this.useBiometrics,
    this.themeMode = 'system',
    this.locale = 'ru',
    this.pushNotificationsEnabled = true,
    this.smsNotificationsEnabled = false,
  });

  final bool useBiometrics;
  final String themeMode;
  final String locale;
  final bool pushNotificationsEnabled;
  final bool smsNotificationsEnabled;
  
  @override
  Map<String, dynamic> toJson() => {
    "useBiometrics": useBiometrics,
    "themeMode": themeMode,
    "locale": locale,
    "pushNotificationsEnabled": pushNotificationsEnabled,
    "smsNotificationsEnabled": smsNotificationsEnabled,
  };

  SettingsStorageData.fromJson(Map<String, dynamic> json)
    : useBiometrics = json['useBiometrics'] ?? false,
      themeMode = json['themeMode'] ?? 'system',
      locale = json['locale'] ?? 'ru',
      pushNotificationsEnabled = json['pushNotificationsEnabled'] ?? true,
      smsNotificationsEnabled = json['smsNotificationsEnabled'] ?? false;
}