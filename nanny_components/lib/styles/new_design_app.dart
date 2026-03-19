import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Единые токены нового дизайна для всего приложения.
/// Используются во всех экранах нового дизайна (main, schedule, balance, chats, profile).
/// Базовые цвета совпадают с [NewDesignAuthTokens], здесь добавлены
/// токены специфичные для UI экранов приложения.
class NDT {
  NDT._();

  // ─── Цвета ───────────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF5B4FCF);
  static const Color primaryLight = Color(0xFF7B70E0);
  static const Color primaryDark = Color(0xFF4338A8);

  static const Color primary100 = Color(0xFFEEF0FF);
  static const Color primary200 = Color(0xFFD5D3F5);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8F8FC);
  static const Color neutral100 = Color(0xFFF1F1F7);
  static const Color neutral200 = Color(0xFFE4E4EF);
  static const Color neutral300 = Color(0xFFC8C8DC);
  static const Color neutral400 = Color(0xFF9898B4);
  static const Color neutral500 = Color(0xFF6B6B8A);
  static const Color neutral700 = Color(0xFF2E2E4A);
  static const Color neutral900 = Color(0xFF0F0F1E);

  // Фон нижнего шита и панелей
  static const Color sheetBg = Color(0xFFFFFFFF);
  static const Color mapOverlayBg = Color(0xFFFFFFFF);

  // Цвет фона экрана (под шитом)
  static const Color screenBg = Color(0xFFF1F1F7);

  // ─── Градиенты ───────────────────────────────────────────────────────────

  /// Основной градиент для CTA-кнопок
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, primaryDark],
  );

  /// Градиент для аватаров/чипов
  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );

  // ─── Радиусы ─────────────────────────────────────────────────────────────

  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius brFull =
      BorderRadius.all(Radius.circular(radiusFull));

  // ─── Отступы ─────────────────────────────────────────────────────────────

  static const double sp2 = 2;
  static const double sp4 = 4;
  static const double sp6 = 6;
  static const double sp8 = 8;
  static const double sp10 = 10;
  static const double sp12 = 12;
  static const double sp14 = 14;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;

  // ─── Тени ────────────────────────────────────────────────────────────────

  /// Тень для CTA-кнопки
  static const List<BoxShadow> ctaShadow = [
    BoxShadow(
      color: Color.fromRGBO(91, 79, 207, 0.35),
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
  ];

  /// Лёгкая тень для карточек
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(46, 46, 74, 0.07),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// Тень для оверлеев над картой
  static const List<BoxShadow> overlayShadow = [
    BoxShadow(
      color: Color.fromRGBO(91, 79, 207, 0.08),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  // ─── Типографика (Manrope) ────────────────────────────────────────────────

  static TextStyle get h1 => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: neutral900,
      );

  static TextStyle get h2 => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: neutral900,
      );

  static TextStyle get h3 => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: neutral900,
      );

  static TextStyle get bodyL => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: neutral700,
      );

  static TextStyle get bodyM => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: neutral700,
      );

  static TextStyle get bodyS => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: neutral500,
      );

  static TextStyle get labelL => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: neutral700,
      );

  static TextStyle get labelM => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: neutral500,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: neutral400,
      );

  static TextStyle get ctaLabel => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: neutral0,
      );

  static TextStyle get chipLabel => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: neutral700,
      );

  static TextStyle get sectionCaption => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: neutral400,
      );

  // ─── Декорации (переиспользуемые) ────────────────────────────────────────

  static BoxDecoration get cardDecoration => const BoxDecoration(
        color: neutral0,
        borderRadius: brLg,
        boxShadow: cardShadow,
      );

  static BoxDecoration get sheetDecoration => const BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
      );

  static BoxDecoration cardSelectedDecoration({double borderWidth = 1.5}) =>
      BoxDecoration(
        color: primary100,
        borderRadius: brLg,
        border: Border.all(color: primary, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(91, 79, 207, 0.14),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      );

  static BoxDecoration cardUnselectedDecoration({double borderWidth = 1}) =>
      BoxDecoration(
        color: neutral0,
        borderRadius: brLg,
        border: Border.all(color: neutral200, width: borderWidth),
      );
}
