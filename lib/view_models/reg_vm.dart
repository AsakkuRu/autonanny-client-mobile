import 'package:flutter/material.dart';
import 'package:nanny_client/views/success_reg.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class RegVM extends ViewModelBase {
  RegVM({required super.context, required super.update});

  GlobalKey<FormState> passwordState = GlobalKey();

  String firstName = "";
  String? errorText;
  String? errorTextName;
  String? errorTextSurname;
  String lastName = "";
  String password = "";

  String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Пароль не меньше 8 символов';
    }
    if (!containsUpperCase(password)) {
      return 'Пароль солжен содержать заглавные буквы';
    }
    if (!containsSpecialCharacter(password)) {
      return 'Пароль должен содержать символы';
    }
    if (!containsDigit(password)) {
      return 'Пароль должен содержать цифры';
    }

    return null;
  }

  bool containsDigit(String input) {
    final RegExp digitRegExp = RegExp(
      r'^(?=.*\d).+$',
    );
    return digitRegExp.hasMatch(input);
  }

  bool containsSpecialCharacter(String input) {
    final RegExp specialCharRegExp = RegExp(
      r'^(?=.*[\W_]).+$',
    );
    return specialCharRegExp.hasMatch(input);
  }

  bool containsUpperCase(String input) {
    final RegExp upperCaseRegExp = RegExp(
      r'^(?=.*[A-Z]).+$',
    );
    return upperCaseRegExp.hasMatch(input);
  }

  void tryReg() async {
    if (firstName.isEmpty) {
      update(() {
        errorTextName = "Введите имя";
      });
      return;
    }
    if (lastName.isEmpty) {
      update(() {
        errorTextSurname = "Введите фамилию";
      });
      return;
    }
    update(() {
      errorText = validatePassword(password);
    });

    if (!passwordState.currentState!.validate()) return;
    LoadScreen.showLoad(context, true);

    String passHash = Md5Converter.convert(password);

    bool success = await DioRequest.handleRequest(
      context,
      NannyAuthApi.regParent(RegParentRequest(
          firstName: firstName,
          lastName: lastName,
          phone: NannyGlobals.phone,
          password: passHash)),
    );

    if (!success) return;

    await NannyStorage.updateLoginData(
      LoginStorageData(
        login: NannyGlobals.phone,
        password: passHash,
        // haveSetPincode: false,
      ),
    );

    final pushToken = await PushTokenSync.getTokenOrEmpty();
    await NannyUser.login(
      LoginRequest(
        login: NannyGlobals.phone,
        password: passHash,
        fbid: pushToken,
      ),
    );

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const FirstPinSet(nextView: SuccessRegView())),
        (route) => route.isFirst);
  }
}
