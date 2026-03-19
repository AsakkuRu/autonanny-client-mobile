import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/checkbox_styles.dart';

/// Глобальная тема приложения, синхронизированная с новым дизайн-гайдом.
class NannyTheme {
  // Светлая тема
  static final ThemeData lightTheme = ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: neutral50,
    buttonTheme: NannyButtonStyles.defaultButtonTheme,
    elevatedButtonTheme: NannyButtonStyles.elevatedBtnTheme,
    textButtonTheme: NannyButtonStyles.textBtnTheme,
    textTheme: NannyTextStyles.textTheme,
    inputDecorationTheme: NannyTextFormStyles.defaultFormTheme,
    dialogTheme: dialogTheme,
    floatingActionButtonTheme: defaultFABStyle,
    cardTheme: defaultCardStyle,
    checkboxTheme: defaultCheckboxStyle,
    useMaterial3: false,
  );

  // Тёмная тема
  static final ThemeData darkTheme = ThemeData(
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: const Color(0xFF121220),
    cardColor: const Color(0xFF1E1E30),
    buttonTheme: NannyButtonStyles.defaultButtonTheme,
    elevatedButtonTheme: NannyButtonStyles.elevatedBtnTheme,
    textButtonTheme: NannyButtonStyles.textBtnTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A3E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
      ),
    ),
    textTheme: NannyTextStyles.textTheme,
    dialogTheme: dialogTheme,
    floatingActionButtonTheme: defaultFABStyle,
    cardTheme: defaultDarkCardStyle,
    checkboxTheme: defaultCheckboxStyle,
    useMaterial3: false,
  );

  // Обратная совместимость
  static ThemeData get appTheme => lightTheme;
  static ThemeData get darkAppTheme => darkTheme;

  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    error: danger,
    onError: onError,
    surface: surface,
    onSurface: onSurface,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Colors.white,
    secondary: Color(0xFF2A2A3E),
    onSecondary: Colors.white,
    error: danger,
    onError: onError,
    surface: Color(0xFF1E1E30),
    onSurface: Colors.white,
  );

  // Основные акцентные цвета (из дизайн-спека клиента)
  static const Color primary = Color(0xFF5B4FCF);
  static const Color primaryLight = Color(0xFF7B70E0);
  static const Color primaryDark = Color(0xFF4338A8);

  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);

  // Нейтральная палитра
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8F8FC);
  static const Color neutral100 = Color(0xFFF1F1F7);
  static const Color neutral200 = Color(0xFFE4E4EF);
  static const Color neutral300 = Color(0xFFC8C8DC);
  static const Color neutral400 = Color(0xFF9898B4);
  static const Color neutral500 = Color(0xFF6B6B8A);
  static const Color neutral600 = Color(0xFF4B4B6C);
  static const Color neutral700 = Color(0xFF2E2E4A);
  static const Color neutral900 = Color(0xFF0F0F1E);

  // Семантические цвета
  static const Color success = Color(0xFF22C55E);
  static const Color successText = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningText = Color(0xFFD97706);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color error = danger;
  static const Color onError = Colors.white;

  static const Color background = neutral50;
  static const Color onBackground = neutral900;

  static const Color surface = neutral0;
  static const Color onSurface = neutral900;

  // Старые алиасы для обратной совместимости
  static const Color grey = neutral200;
  static const Color darkGrey = neutral400;
  static const Color green = success;
  static const Color lightGreen = Color(0xFFE2FFE3);
  static const Color lightPink = Color(0xFFF6F5FF);

  static const Color shadow = Color(0xFF605B99);

  static final ShapeBorder roundBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

  static final CardThemeData defaultCardStyle = CardThemeData(
    color: surface,
    shadowColor: shadow.withOpacity(0.06),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  );

  static final CardThemeData defaultDarkCardStyle = CardThemeData(
    color: const Color(0xFF1E1E30),
    shadowColor: Colors.black.withOpacity(0.4),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  );
}
