import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';

/// Bootstrap adapter between the client app and the shared UI SDK theme layer.
///
/// At this stage the app still keeps legacy `nanny_components`, but `MaterialApp`
/// is already allowed to consume the SDK theme directly.
abstract final class ClientUiSdkTheme {
  static ThemeData get lightTheme => AutonannyTheme.light();

  static ThemeData get darkTheme => AutonannyTheme.dark();
}
