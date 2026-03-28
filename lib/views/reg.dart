import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_client/view_models/reg_vm.dart';

class RegView extends StatefulWidget {
  const RegView({super.key});

  @override
  State<RegView> createState() => _RegViewState();
}

class _RegViewState extends State<RegView> {
  late RegVM vm;

  @override
  void initState() {
    super.initState();
    vm = RegVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Scaffold(
      appBar: const AutonannyAppBar(title: 'Регистрация'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AutonannySpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Регистрация аккаунта',
                  style: AutonannyTypography.h1(color: colors.textPrimary),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Создайте аккаунт родителя, чтобы управлять поездками, детьми и расписанием.',
                  style: AutonannyTypography.bodyS(color: colors.textSecondary),
                ),
                const SizedBox(height: AutonannySpacing.xl),
                AutonannyTextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^[^\d\W_]+$'),
                    ),
                  ],
                  labelText: 'Имя*',
                  hintText: 'Введите имя',
                  textCapitalization: TextCapitalization.words,
                  errorText: vm.errorTextName,
                  onChanged: (text) {
                    vm.firstName = text;
                    if (vm.errorTextName != null) {
                      setState(() => vm.errorTextName = null);
                    }
                  },
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^[^\d\W_]+$'),
                    ),
                  ],
                  labelText: 'Фамилия*',
                  hintText: 'Введите фамилию',
                  textCapitalization: TextCapitalization.words,
                  errorText: vm.errorTextSurname,
                  onChanged: (text) {
                    vm.lastName = text;
                    if (vm.errorTextSurname != null) {
                      setState(() => vm.errorTextSurname = null);
                    }
                  },
                ),
                const SizedBox(height: AutonannySpacing.md),
                Form(
                  key: vm.passwordState,
                  child: AutonannyTextField(
                    labelText: 'Пароль*',
                    hintText: 'Введите пароль',
                    obscureText: true,
                    errorText: vm.errorText,
                    validator: (text) {
                      if ((text ?? '').length < 8) {
                        return 'Пароль не меньше 8 символов!';
                      }
                      return null;
                    },
                    onChanged: (text) {
                      vm.password = text;
                      vm.errorText = null;
                    },
                  ),
                ),
                const SizedBox(height: AutonannySpacing.md),
                const AutonannyInlineBanner(
                  title: 'Требования к паролю',
                  message:
                      'Минимум 8 символов, одна заглавная буква, одна цифра и один специальный символ.',
                  tone: AutonannyBannerTone.info,
                  leading: AutonannyIcon(AutonannyIcons.lock),
                ),
                const SizedBox(height: AutonannySpacing.xl),
                AutonannyButton(
                  label: 'Зарегистрироваться',
                  onPressed: vm.tryReg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
