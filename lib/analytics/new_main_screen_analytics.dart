import 'package:nanny_core/nanny_core.dart';

/// Логирование ключевых действий пользователя на новом главном экране.
/// При подключении Firebase Analytics / Mixpanel — заменить Logger на реальный трекер.
abstract class NewMainScreenAnalytics {
  NewMainScreenAnalytics._();

  static final _log = Logger();

  /// Экран открыт
  static void screenOpened() {
    _log.i('[Analytics] new_main_screen: opened');
  }

  /// Выбран тариф
  static void tariffSelected(int tariffId, String tariffName) {
    _log.i('[Analytics] new_main_screen: tariff_selected '
        '| id=$tariffId name=$tariffName');
  }

  /// Ребёнок добавлен в поездку
  static void childSelected(int childId) {
    _log.i('[Analytics] new_main_screen: child_selected | id=$childId');
  }

  /// Ребёнок убран из поездки
  static void childDeselected(int childId) {
    _log.i('[Analytics] new_main_screen: child_deselected | id=$childId');
  }

  /// Попытка выбрать более 4 детей
  static void childLimitReached() {
    _log.w('[Analytics] new_main_screen: child_limit_reached');
  }

  /// Нажатие CTA «Найти автоняню»
  static void ctaTapped({
    required int selectedChildrenCount,
    required int? tariffId,
    required int addressCount,
  }) {
    _log.i('[Analytics] new_main_screen: cta_tapped '
        '| children=$selectedChildrenCount tariff=$tariffId '
        '| addresses=$addressCount');
  }

  /// Заказ успешно создан
  static void orderCreated(String token) {
    _log.i('[Analytics] new_main_screen: order_created | token=$token');
  }

  /// Ошибка при создании заказа
  static void orderFailed(String reason) {
    _log.e('[Analytics] new_main_screen: order_failed | reason=$reason');
  }

  /// Нажатие SOS
  static void sosTapped() {
    _log.w('[Analytics] new_main_screen: sos_tapped');
  }

  /// Ошибка загрузки данных экрана
  static void loadFailed(String dataType, String error) {
    _log.e('[Analytics] new_main_screen: load_failed '
        '| type=$dataType error=$error');
  }
}
