import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_client/theme_notifier.dart';
import 'package:nanny_client/feature_flags.dart';
import 'package:nanny_client/views/home.dart';
import 'package:nanny_client/views/new_main/new_home_view.dart';
import 'package:nanny_client/views/reg.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/app_link_handler.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/nanny_local_auth.dart';
import 'package:nanny_core/services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();
final LocaleNotifier localeNotifier = LocaleNotifier();

DateTime? _lastBackPressAt;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    configureAppLogging(appName: 'client');
    _configureGlobalErrorHandling();
    await _bootstrapApp();
  }, (error, stackTrace) {
    Logger().f(
      'Unhandled zone error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

Future<void> _bootstrapApp() async {
  // BUG-140326-011: кнопка «Назад» — навигация внутри приложения, на корне — двойное нажатие для выхода
  SystemChannels.navigation.setMethodCallHandler((call) async {
    if (call.method == 'popRoute') {
      final context = NannyGlobals.navKey.currentContext;
      if (context == null) {
        SystemNavigator.pop();
        return;
      }
      if (MediaQuery.of(context).viewInsets.bottom > 0) {
        FocusManager.instance.primaryFocus?.unfocus();
        return;
      }
      final didPop = await Navigator.of(context).maybePop();
      if (didPop) return;
      final now = DateTime.now();
      if (_lastBackPressAt != null &&
          now.difference(_lastBackPressAt!) < const Duration(seconds: 2)) {
        SystemNavigator.pop();
        return;
      }
      _lastBackPressAt = now;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нажмите ещё раз для выхода')),
        );
      }
    }
  });

  // Location service только для мобильных платформ
  if (Platform.isAndroid || Platform.isIOS) {
    LocationService.initBackgroundLocation();
    // Инициализируем информацию о городе для bias в подсказках адреса
    LocationService.initLocInfo();
  }

  HttpOverrides.global = MyHttpOverrides();

  // Ориентация только для мобильных
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // Firebase только для мобильных платформ
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Intl.defaultLocale = "ru_RU";
  initializeDateFormatting(Intl.defaultLocale);
  var locale = DefaultMaterialLocalizations.delegate;
  await locale.load(const Locale("ru", "ru"));

  DioRequest.init();
  DioRequest.initDebugLogs();
  await NotificationService().init(NannyGlobals.navKey);

  NannyConsts.setLoginPaths([
    LoginPath(
      userType: UserType.client,
      path: NannyFeatureFlags.useNewHomeView
          ? const NewHomeView()
          : const HomeView(),
    ),
    LoginPath(
        userType: UserType.admin,
        path: const AdminHomeView(regView: RegView())),
  ]);
  await NannyConsts.initMarkerIcons();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: NannyTheme.background));
  NannyLocalAuth.init();

  await NannyStorage.init(isClient: true);

  // Firebase Messaging только для мобильных
  if (Platform.isAndroid || Platform.isIOS) {
    FirebaseMessagingHandler.init();
  }

  AppLinksHandler.initAppLinkHandler();

  Logger().d(
      "Storage data:\nLogin data - ${(await NannyStorage.getLoginData())?.toJson()}");

  runApp(
    MainApp(
      firstScreen: await NannyUser.autoLogin(
        paths: NannyConsts.availablePaths,
        defaultView: WelcomeView(
          regView: const RegView(),
          loginPaths: NannyConsts.availablePaths,
        ),
      ),
    ),
  );
}

void _configureGlobalErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Logger().f(
      'Unhandled Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    Logger().f(
      'Unhandled platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}

class MainApp extends StatelessWidget {
  final Widget firstScreen;

  const MainApp({
    super.key,
    required this.firstScreen,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              navigatorKey: NannyGlobals.navKey,
              theme: NannyTheme.appTheme,
              darkTheme: NannyTheme.darkAppTheme,
              themeMode: themeMode,
              home: firstScreen,
              supportedLocales: const [
                Locale('ru', 'RU'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: locale,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}

// На случай, если Пятисотый забыл сертификаты обновить

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
