import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Минимальный набор токенов нового дизайна
/// для экранов авторизации / входа.
class NewDesignAuthTokens {
  // Базовые цвета (синхронизированы с АвтоНяня_Дизайн_ТЗ.md)
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

  // Градиенты для auth‑экранов
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );

  // Радиусы
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(16));

  // Тени
  static const List<BoxShadow> ctaShadow = [
    BoxShadow(
      color: Color.fromRGBO(91, 79, 207, 0.35),
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
  ];

  // Типографика (Manrope)

  static TextStyle get titleXL => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: neutral900,
      );

  static TextStyle get titleM => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: neutral900,
      );

  static TextStyle get bodyM => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: neutral500,
      );

  static TextStyle get bodyS => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: neutral700,
      );

  static TextStyle get captionS => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: neutral400,
      );
}

