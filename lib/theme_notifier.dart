import 'package:flutter/material.dart';
import 'package:nanny_core/nanny_core.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final settings = await NannyStorage.getSettingsData();
    if (settings != null) {
      value = _parseThemeMode(settings.themeMode);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    final settings = await NannyStorage.getSettingsData();
    await NannyStorage.updateSettingsData(
      SettingsStorageData(
        useBiometrics: settings?.useBiometrics ?? false,
        themeMode: _themeModeToString(mode),
        locale: settings?.locale ?? 'ru',
        pushNotificationsEnabled: settings?.pushNotificationsEnabled ?? true,
        smsNotificationsEnabled: settings?.smsNotificationsEnabled ?? false,
      ),
    );
  }

  static ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}

class LocaleNotifier extends ValueNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ru', 'RU')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final settings = await NannyStorage.getSettingsData();
    if (settings != null) {
      value = _parseLocale(settings.locale);
    }
  }

  Future<void> setLocale(String langCode) async {
    value = _parseLocale(langCode);
    final settings = await NannyStorage.getSettingsData();
    await NannyStorage.updateSettingsData(
      SettingsStorageData(
        useBiometrics: settings?.useBiometrics ?? false,
        themeMode: settings?.themeMode ?? 'system',
        locale: langCode,
        pushNotificationsEnabled: settings?.pushNotificationsEnabled ?? true,
        smsNotificationsEnabled: settings?.smsNotificationsEnabled ?? false,
      ),
    );
  }

  static Locale _parseLocale(String code) {
    switch (code) {
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ru', 'RU');
    }
  }
}
