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
      child: _PhoneStepContent(title: title, text: text),
    );
  }
}

class _PhoneStepContent extends StatefulWidget {
  const _PhoneStepContent({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  State<_PhoneStepContent> createState() => _PhoneStepContentState();
}

class _PhoneStepContentState extends State<_PhoneStepContent> {
  bool _acceptedTerms = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _StepProgress(currentStep: 1),
          const SizedBox(height: 20),
          Text(
            'ШАГ 1 ИЗ 4',
            style: NewDesignAuthTokens.captionS,
          ),
          const SizedBox(height: 8),
          Text(widget.title, style: NewDesignAuthTokens.titleXL),
          const SizedBox(height: 8),
          Text(widget.text, style: NewDesignAuthTokens.bodyM),
          const SizedBox(height: 20),
          NannyTextForm(
            isExpanded: true,
            labelText: 'Номер телефона',
            hintText: '+7 (916) 123-45-67',
            keyType: TextInputType.number,
            formatters: [_vm.phoneMask],
            validator: (text) {
              if (text == null || text.isEmpty) {
                return 'Введите номер телефона';
              }
              if (_vm.phoneMask.getUnmaskedText().length < 11) {
                return 'Введите полный номер телефона';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Введите номер без +7 или 8',
            style: NewDesignAuthTokens.captionS.copyWith(
              letterSpacing: 0.1,
              color: NewDesignAuthTokens.neutral400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: NewDesignAuthTokens.neutral200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'ИЛИ ВОЙДИТЕ ЧЕРЕЗ',
                  style: NewDesignAuthTokens.captionS.copyWith(
                    color: NewDesignAuthTokens.neutral400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Expanded(child: Divider(color: NewDesignAuthTokens.neutral200)),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _SocialButton(label: 'Google')),
              SizedBox(width: 10),
              Expanded(child: _SocialButton(label: 'Apple')),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _acceptedTerms
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: NewDesignAuthTokens.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Я согласен с Пользовательским соглашением и Политикой конфиденциальности',
                    style: NewDesignAuthTokens.bodyM.copyWith(
                      fontSize: 13,
                      color: NewDesignAuthTokens.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _acceptedTerms ? _vm.toPhoneConfirmation : null,
              style: ButtonStyle(
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  _acceptedTerms
                      ? NewDesignAuthTokens.primary
                      : NewDesignAuthTokens.neutral300,
                ),
                shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: NewDesignAuthTokens.radiusLg,
                  ),
                ),
              ),
              child: Text(
                'Получить код',
                style: NewDesignAuthTokens.bodyS.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepProgress(currentStep: 2),
          const SizedBox(height: 20),
          Text(
            'ШАГ 2 ИЗ 4',
            style: NewDesignAuthTokens.captionS,
          ),
          const SizedBox(height: 8),
          Text(
            'Код из SMS',
            style: NewDesignAuthTokens.titleXL,
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: NewDesignAuthTokens.bodyM,
              children: [
                const TextSpan(text: 'Отправили код на '),
                TextSpan(
                  text: _vm.phoneMask.getMaskedText(),
                  style: NewDesignAuthTokens.bodyM.copyWith(
                    color: NewDesignAuthTokens.neutral900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FourDigitKeyboard(
              onCodeChanged: (code) {
                _vm.code = code;
                if (code.length > 3) {
                  _vm.checkPhone();
                }
              },
              topChild: const SizedBox.shrink(),
              bottomChild: _vm.timerEnded
                  ? TextButton(
                      onPressed: _vm.resendSms,
                      child: Text(
                        'Отправить код заново',
                        style: NewDesignAuthTokens.bodyS.copyWith(
                          color: NewDesignAuthTokens.primary,
                        ),
                      ),
                    )
                  : SmsTimer(
                      secFrom: _vm.timeLeft,
                      onEnd: _vm.onTimerEnd,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFE7CB)),
            ),
            child: Text(
              'Код придёт в течение 1 минуты. Не сообщайте его никому.',
              style: NewDesignAuthTokens.bodyS.copyWith(
                color: const Color(0xFF237A3C),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(
                'Изменить номер телефона',
                style: NewDesignAuthTokens.bodyS.copyWith(
                  color: NewDesignAuthTokens.neutral400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NewDesignAuthTokens.neutral200),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: NewDesignAuthTokens.bodyS.copyWith(
          color: NewDesignAuthTokens.neutral700,
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: isActive
                  ? NewDesignAuthTokens.primary
                  : NewDesignAuthTokens.neutral200,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
