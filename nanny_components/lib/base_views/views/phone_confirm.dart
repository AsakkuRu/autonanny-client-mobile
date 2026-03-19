import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/phone_confirm_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_auth.dart';
import 'package:nanny_core/models/login_path.dart';

class PhoneConfirmView extends StatefulWidget {
  final Widget nextScreen;
  final String title;
  final String text;
  final bool isReg;
  final List<LoginPath> loginPaths;

  const PhoneConfirmView({
    super.key,
    required this.nextScreen,
    required this.title,
    required this.text,
    required this.isReg,
    required this.loginPaths,
  });

  @override
  State<PhoneConfirmView> createState() => _PhoneConfirmViewState();
}

late PhoneConfirmVM _vm;

class _PhoneConfirmViewState extends State<PhoneConfirmView> {
  @override
  void initState() {
    super.initState();
    _vm = PhoneConfirmVM(
      baseContext: context,
      context: context,
      update: setState,
      nextScreen: widget.nextScreen,
      title: widget.title,
      text: widget.text,
      isReg: widget.isReg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewDesignAuthTokens.neutral50,
      appBar: NannyAppBar(
        hasBackButton: true,
        color: NewDesignAuthTokens.neutral50,
        actions: [
          if (_vm.currentView is PhoneEnterView)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Войти',
                style: NewDesignAuthTokens.bodyS.copyWith(
                  color: NewDesignAuthTokens.primary,
                ),
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginView(
                    imgPath:
                        "packages/nanny_components/assets/images/Saly-10.png",
                    paths: widget.loginPaths,
                  ),
                ),
              ),
            ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: _vm.currentView,
    );
  }
}

class PhoneEnterView extends StatelessWidget {
  final String title;
  final String text;

  const PhoneEnterView({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _vm.phoneState,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              style: NewDesignAuthTokens.titleXL,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.left,
              style: NewDesignAuthTokens.bodyM,
            ),
            const SizedBox(height: 24),
            NannyTextForm(
              isExpanded: true,
              labelText: "Номер телефона*",
              hintText: "+7 (777) 777-77-77",
              keyType: TextInputType.number,
              formatters: [_vm.phoneMask],
              validator: (text) {
                if (text == null || text.isEmpty) {
                  return "Введите номер телефона!";
                }
                if (_vm.phoneMask.getUnmaskedText().length < 11) {
                  return "Введите полный номер телефона!";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _vm.toPhoneConfirmation,
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: const WidgetStatePropertyAll(
                    NewDesignAuthTokens.primary,
                  ),
                  shape: const WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: NewDesignAuthTokens.radiusLg,
                    ),
                  ),
                ),
                child: Text(
                  "Отправить код",
                  style: NewDesignAuthTokens.bodyS.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneEnterConfirmView extends StatefulWidget {
  const PhoneEnterConfirmView({super.key});

  @override
  State<PhoneEnterConfirmView> createState() => _PhoneEnterConfirmViewState();
}

class _PhoneEnterConfirmViewState extends State<PhoneEnterConfirmView> {
  @override
  void initState() {
    super.initState();
    _vm.update = setState;
    _vm.initTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 20, top: 80, right: 20, bottom: 24),
            child: Text(
              "Мы отправили вам\nСМС код",
              textAlign: TextAlign.center,
              style: NewDesignAuthTokens.titleM,
            ),
          ),
          Expanded(
            child: FourDigitKeyboard(
              topChild: RichText(
                text: TextSpan(
                  style: NewDesignAuthTokens.bodyM,
                  children: [
                    TextSpan(
                      text: "На номер: ",
                      style: NewDesignAuthTokens.bodyM.copyWith(
                        color: NewDesignAuthTokens.neutral400,
                      ),
                    ),
                    TextSpan(
                        text: _vm.phoneMask.getMaskedText(),
                        style: NewDesignAuthTokens.bodyM.copyWith(
                          color: NewDesignAuthTokens.primary,
                        )),
                  ],
                ),
              ),
              bottomChild: _vm.timerEnded
                  ? TextButton(
                      onPressed: _vm.resendSms,
                      child: const Text("Отправить СМС заново"))
                  : SmsTimer(secFrom: _vm.timeLeft, onEnd: _vm.onTimerEnd),
              onCodeChanged: (code) {
                _vm.code = code;
                if (code.length > 3) _vm.checkPhone();
              },
            ),
          ),
        ],
      ),
    );
  }
}
