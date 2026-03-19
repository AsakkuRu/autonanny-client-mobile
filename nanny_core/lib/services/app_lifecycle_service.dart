import 'package:flutter/widgets.dart';

/// Отслеживает жизненный цикл приложения (foreground / background).
///
/// Используется NotificationService для выбора способа показа уведомлений:
/// - foreground → in-app banner
/// - background → local notification
class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._();

  AppLifecycleState _state = AppLifecycleState.resumed;

  /// Приложение в foreground (видимо пользователю).
  static bool get isForeground => _instance._state == AppLifecycleState.resumed;

  /// Приложение в background.
  static bool get isBackground => !isForeground;

  /// Инициализация (вызвать один раз в main.dart или initState корневого виджета).
  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Очистка (при необходимости).
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _state = state;
  }
}
