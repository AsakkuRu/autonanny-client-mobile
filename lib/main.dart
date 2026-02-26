import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_client/theme_notifier.dart';
import 'package:nanny_client/views/home.dart';
import 'package:nanny_client/views/reg.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/app_link_handler.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/nanny_local_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();
final LocaleNotifier localeNotifier = LocaleNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Нужно для фикса бага с жестами
  // Если включено управление жестами, то при попытке скрыть клавиатуру происходит выход из раздела
  SystemChannels.navigation.setMethodCallHandler((call) async {
    if (call.method == 'popRoute') {
      // Получаем контекст через navigatorKey
      final context = NannyGlobals.navKey.currentContext;

      if (context != null && MediaQuery.of(context).viewInsets.bottom > 0) {
        // Закрываем клавиатуру
        FocusManager.instance.primaryFocus?.unfocus();
        return; // Блокируем действие "назад"
      }

      SystemNavigator
          .pop(); // Если клавиатура закрыта, разрешаем действие "назад"
    }
  });

  // Location service только для мобильных платформ
  if (Platform.isAndroid || Platform.isIOS) {
    LocationService.initBackgroundLocation();
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

  NannyConsts.setLoginPaths([
    LoginPath(userType: UserType.client, path: const HomeView()),
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
