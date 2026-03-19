import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NannyTextStyles {
  static TextStyle get _base => GoogleFonts.manrope();

  static final TextTheme textTheme = TextTheme(
    // Крупные заголовки
    headlineLarge:
        _base.copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineMedium:
        _base.copyWith(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4),
    headlineSmall:
        _base.copyWith(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),

    // Заголовки секций
    titleLarge:
        _base.copyWith(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
    titleMedium:
        _base.copyWith(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
    titleSmall:
        _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),

    // Основной текст
    bodyLarge:
        _base.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    bodyMedium:
        _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    bodySmall:
        _base.copyWith(fontSize: 14, fontWeight: FontWeight.w700),

    // Лейблы и подписи
    labelLarge:
        _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    labelMedium:
        _base.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
    labelSmall:
        _base.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
  );

  static TextStyle get nw60024 =>
      GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 24);
  static TextStyle get nw70018 =>
      GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 18);
  static TextStyle get nw40018 =>
      GoogleFonts.manrope(fontWeight: FontWeight.w400, fontSize: 18);
  static TextStyle get nw50018 =>
      GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 18);

  static TextStyle get defaultTextStyle => _base;

  static TextStyle get titleStyle =>
      _base.copyWith(fontWeight: FontWeight.w800);
}
