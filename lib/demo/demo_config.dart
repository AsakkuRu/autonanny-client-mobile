/// B-012 TASK-B12: Конфигурация демо-режима (клиентская часть)
/// Активируется через --dart-define=DEMO=true или тройным тапом по логотипу
class DemoConfig {
  static bool _isDemoMode = const bool.fromEnvironment('DEMO', defaultValue: false);
  static bool get isDemoMode => _isDemoMode;

  static void enableDemo() {
    _isDemoMode = true;
  }

  static void disableDemo() {
    _isDemoMode = false;
  }

  static void toggle() {
    _isDemoMode = !_isDemoMode;
  }
}
