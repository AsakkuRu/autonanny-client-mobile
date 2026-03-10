import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class LoginVM extends ViewModelBase {
  LoginVM({
    required super.context,
    required super.update,
    required this.availableRoleLogin,
    required this.paths,
  });

  String password = "";
  List<LoginPath> availableRoleLogin;

  bool isLoading = false;

  final List<LoginPath> paths;

  final GlobalKey<FormState> phoneState = GlobalKey();
  final MaskTextInputFormatter phoneMask = TextMasks.phoneMask();

  final GlobalKey<FormState> passwordState = GlobalKey();

  String get phone => "7${phoneMask.getUnmaskedText()}";
  bool get canOauth => NannyConsts.availablePaths
      .where((e) => e.userType == UserType.client)
      .isNotEmpty;

  void toPasswordReset() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneConfirmView(
            nextScreen: const PasswordResetView(),
            title: "Забыли пароль?",
            text:
                "Введите номер телефона на который зарегистрирован аккаунт и мы отправим вам СМС с кодом.",
            isReg: false,
            loginPaths: paths,
          ),
        ),
      );

  void tryLogin() async {
    // MOCK AUTH: временный обход авторизации — удалить перед релизом
    const bool _mockAuth = false;
    if (_mockAuth) {
      NannyUser.userInfo = UserInfo(
        id: 1,
        surname: "Тест",
        name: "Пользователь",
        phone: "79001234567",
        role: availableRoleLogin.map((e) => e.userType).toList(),
        photoPath: "",
        videoPath: "",
        hasAuth: true,
      );
      if (!context.mounted) return;
      for (var e in availableRoleLogin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => e.path),
          (route) => false,
        );
        break;
      }
      return;
    }

    update(() => isLoading = true);
    if (!phoneState.currentState!.validate() ||
        !passwordState.currentState!.validate()) {
      update(() => isLoading = false);
      return;
    }

    String passHash = Md5Converter.convert(password);
    var request = NannyUser.login(
        LoginRequest(login: phone, password: passHash, fbid: "Пятисотый"));

    bool success = await DioRequest.handleRequest(
        // ignore: use_build_context_synchronously
        context,
        request);
    if (!success) {
      update(() => isLoading = false);
      return;
    }

    if (!context.mounted) return;
    if (availableRoleLogin
        .map((e) => e.userType)
        .toSet()
        .intersection(NannyUser.userInfo!.role.toSet())
        .isEmpty) {
      NannyDialogs.showMessageBox(
          context, "Ошибка", "Вы авторизовались в аккаунт не в том приложении");
      update(() => isLoading = false);
      return;
    }

    NannyStorage.updateLoginData(LoginStorageData(
      login: phone,
      password: passHash,
      // haveSetPincode: true,
    ));

    var me = (await request) as ApiResponse<UserInfo>;
    if (!me.success) {
      update(() => isLoading = false);
      return;
    }
    if (!context.mounted) return;

    for (var e in availableRoleLogin) {
      if (NannyUser.userInfo!.role.contains(e.userType)) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => !me.response!.hasAuth
                    ? FirstPinSet(nextView: e.path)
                    : e.path),
            (route) => false);
        break;
      }
    }

    update(() => isLoading = false);
  }

  void yandexAuth() {
    launchUrl(
        Uri.parse(
            "https://oauth.yandex.ru/authorize?response_type=code&client_id=05f788e3a4ff44b08e387ab58b083442&redirect_url=https://nyanyago.ru/api/v1.0/auth/oauth_yandex"),
        mode: LaunchMode.externalApplication);
  }

  void vkAuth() {
    launchUrl(
        Uri.parse(
            "https://oauth.vk.com/authorize?client_id=51865735&display=page&redirect_uri=https://nyanyago.ru/api/v1.0/auth/oauth_vk"),
        mode: LaunchMode.externalApplication);
  }

  void telegramAuth() {
    launchUrl(Uri.parse("https://t.me/NyanyaGo_bot?start=nyanyago_register"),
        mode: LaunchMode.externalApplication);
  }
}
