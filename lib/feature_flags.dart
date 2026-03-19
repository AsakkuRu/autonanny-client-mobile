/// Статические флаги для управления функциональностью приложения.
/// При переходе на remote config — заменить на соответствующий провайдер.
abstract class NannyFeatureFlags {
  NannyFeatureFlags._();

  /// Включает новый главный экран (NewHomeView вместо HomeView).
  /// DEV: true — показывает новый дизайн.
  /// PROD: переключить на true после успешного QA.
  static const bool useNewHomeView = true;
}
