import 'package:flutter/material.dart';
import 'package:nanny_components/styles/nanny_theme.dart';

class NannyButtonStyles {
  static final ElevatedButtonThemeData elevatedBtnTheme =
      ElevatedButtonThemeData(style: defaultButtonStyle);
  static final TextButtonThemeData textBtnTheme =
      TextButtonThemeData(style: defaultButtonStyleWithNoSize);

  static final ButtonThemeData defaultButtonTheme = ButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
  );

  // Базовый стиль для старых мест использования
  static final ButtonStyle defaultButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(200, 56),
    maximumSize: const Size(double.infinity, 100),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    backgroundColor: NannyTheme.primary,
    foregroundColor: Colors.white,
  );

  static final ButtonStyle defaultButtonStyleWithNoSize =
      ElevatedButton.styleFrom(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
  );

  // Светлая кнопка (outline/secondary)
  static const ButtonStyle whiteButton = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(NannyTheme.secondary),
    foregroundColor: WidgetStatePropertyAll(NannyTheme.onSecondary),
    overlayColor: WidgetStatePropertyAll(NannyTheme.neutral100),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
  );

  static const ButtonStyle lightGreen = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(NannyTheme.lightGreen),
    foregroundColor: WidgetStatePropertyAll(NannyTheme.onSecondary),
    overlayColor: WidgetStatePropertyAll(NannyTheme.green),
  );

  static const ButtonStyle green = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(NannyTheme.success),
    foregroundColor: WidgetStatePropertyAll(NannyTheme.onSecondary),
    overlayColor: WidgetStatePropertyAll(NannyTheme.lightGreen),
  );

  static const ButtonStyle transparent = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
    foregroundColor: WidgetStatePropertyAll(NannyTheme.onSecondary),
    overlayColor: WidgetStatePropertyAll(NannyTheme.neutral100),
    elevation: WidgetStatePropertyAll(0),
  );

  // Основная CTA-кнопка
  static ButtonStyle main = const ButtonStyle(
    elevation: WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(NannyTheme.primary),
    foregroundColor: WidgetStatePropertyAll(Colors.white),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    minimumSize: WidgetStatePropertyAll(
      Size(double.infinity, 56),
    ),
  );

  // Вторичная кнопка (на белом фоне)
  static ButtonStyle secondary = const ButtonStyle(
    elevation: WidgetStatePropertyAll(0),
    backgroundColor: WidgetStatePropertyAll(NannyTheme.secondary),
    foregroundColor: WidgetStatePropertyAll(NannyTheme.neutral700),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    minimumSize: WidgetStatePropertyAll(
      Size(double.infinity, 56),
    ),
  );
}
