import 'package:flutter/material.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/dialogs/nanny_dialogs.dart';
import 'package:nanny_components/view_model_base.dart';
import 'package:nanny_core/api/api_models/verify_pass_reset_request.dart';
import 'package:nanny_core/nanny_core.dart';

class PasswordResetVm extends ViewModelBase {
  PasswordResetVm({
    required super.context, 
    required super.update
  });

  GlobalKey<FormState> passState = GlobalKey();
  GlobalKey<FormState> passConfirmState = GlobalKey();

  String password = "";
  String passwordConfirm = "";

  void tryResetPassword() async {
    LoadScreen.showLoad(context, true);

    if(!passState.currentState!.validate() || !passConfirmState.currentState!.validate()) {
      Future.delayed(const Duration(milliseconds: 500), () => LoadScreen.showLoad(context, false));
      return;
    }

    bool success = await DioRequest.handleRequest(
      context, 
      NannyAuthApi.verifyResetPassword(
        VerifyPassResetRequest(
          phone: NannyGlobals.phone, 
          password: password,
        )
      )
    );

    if(!context.mounted) return;
    LoadScreen.showLoad(context, false);
    if(!success) return;

    Navigator.popUntil(
      context, 
      (route) => route.isFirst,
    );

    if(!NannyGlobals.currentContext.mounted) return;
    NannyDialogs.showMessageBox(
      NannyGlobals.currentContext,
      "Пароль успешно изменён",
      "",
    );
  }
}