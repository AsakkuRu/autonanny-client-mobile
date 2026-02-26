import 'package:nanny_core/storage_models/base_storage.dart';

class SettingsStorageData implements BaseStorage {
  SettingsStorageData({
    required this.useBiometrics,
    this.themeMode = 'system',
    this.locale = 'ru',
  });

  final bool useBiometrics;
  final String themeMode;
  final String locale;
  
  @override
  Map<String, dynamic> toJson() => {
    "useBiometrics": useBiometrics,
    "themeMode": themeMode,
    "locale": locale,
  };

  SettingsStorageData.fromJson(Map<String, dynamic> json)
    : useBiometrics = json['useBiometrics'] ?? false,
      themeMode = json['themeMode'] ?? 'system',
      locale = json['locale'] ?? 'ru';
}