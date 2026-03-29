import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class WelcomeVM extends ViewModelBase {
  WelcomeVM({
    required super.context,
    required super.update,
    required this.regScreen,
    required this.loginPaths,
  }) {
    requestPermissions();
    // TODO: сделать вывод реальной версии из pubspec (package_info_plus или аналог)
    Future.delayed(const Duration(seconds: 1), () {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Версия сборки: 0.3.21"),
      ));
    });
  }

  final Widget regScreen;
  final List<LoginPath> loginPaths;

  void navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginView(
            imgPath: "packages/nanny_components/assets/images/Saly-10.png",
            paths: loginPaths),
      ),
    );
  }

  void navigateToReg() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneConfirmView(
            nextScreen: regScreen,
            title: "Подтверждение номера",
            text:
                "Введите номер телефона и мы отправим вам код с письмом через SMS",
            isReg: true,
            loginPaths: loginPaths),
      ),
    );
  }

  Future<void> requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        sound: true,
        provisional: true);
    List<String> deniedPerms = [];

    if (await Permission.locationAlways.isDenied) {
      // TODO: Навесить только на водилу
      if (context.mounted) {
        await NannyDialogs.showMessageBox(context, "Внимание!",
            "Автоняне нужен постоянный доступ к вашей геолокации!\nМы перенаправим вас в настройки геолокации...");
      }
      await Permission.locationAlways.request();
      // if(result.isPermanentlyDenied || result.isDenied) deniedPerms.add(Permission.locationAlways.toString());
    }
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
    } else {
      await Permission.notification.request();
    }
    if (await Permission.notification.isDenied) {
      await NannyDialogs.showMessageBox(
          context,
          "Внимание!",
          "Автоняне нужны разрешения на показ уведомлений, чтобы корректно работать!"
              "\nМы перенаправим вас в настройки, чтобы вы дали разрешение...");
      await Permission.notification.request();
    }

    if (deniedPerms.isNotEmpty) {
      if (!context.mounted) {
        openAppSettings();
        return;
      }

      await NannyDialogs.showMessageBox(
          context,
          "Внимание!",
          "Автоняне нужны разрешения на ${deniedPerms.join(', ')}, чтобы корректно работать!"
              "\nМы перенаправим вас в настройки, чтобы вы дали разрешение...");
      openAppSettings();
    }
  }
}
