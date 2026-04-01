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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

  @override
  void initState() {
    super.initState();
    vm = RegVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final passwordError = vm.validatePassword(vm.password);
    final passwordsMatch = vm.password.isNotEmpty &&
        vm.password == _repeatPasswordController.text.trim();
    final canSubmit = passwordError == null && passwordsMatch;

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
                Row(
                  children: List.generate(4, (index) {
                    final isActive = index < 3;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index == 3 ? 0 : AutonannySpacing.xs,
                        ),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.actionPrimary
                              : colors.borderSubtle,
                          borderRadius: AutonannyRadii.brFull,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AutonannySpacing.md),
                Text(
                  'ШАГ 3 ИЗ 4',
                  style: AutonannyTypography.caption(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                Text(
                  'Ваши данные',
                  style: AutonannyTypography.h1(color: colors.textPrimary),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Введите имя, как вас будут видеть водители в поездках.',
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
                AutonannyTextField(
                  labelText: 'Email (необязательно)',
                  hintText: 'example@mail.ru',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                const SizedBox(height: AutonannySpacing.md),
                const AutonannyInlineBanner(
                  title: 'Имя будет видно водителю',
                  message:
                      'Имя и фамилия используются в карточке поездки и в чате с водителем.',
                  tone: AutonannyBannerTone.info,
                  leading: AutonannyIcon(AutonannyIcons.info),
                ),
                const SizedBox(height: AutonannySpacing.xl),
                Text(
                  'ШАГ 4 ИЗ 4',
                  style: AutonannyTypography.caption(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                Text(
                  'Придумайте пароль',
                  style: AutonannyTypography.h2(color: colors.textPrimary),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Минимум 8 символов для входа в аккаунт.',
                  style: AutonannyTypography.bodyS(color: colors.textSecondary),
                ),
                const SizedBox(height: AutonannySpacing.md),
                Form(
                  key: vm.passwordState,
                  child: AutonannyTextField(
                    labelText: 'Пароль*',
                    hintText: 'Введите пароль',
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      splashRadius: 18,
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
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
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  labelText: 'Повторите пароль*',
                  hintText: 'Введите пароль еще раз',
                  obscureText: _obscureRepeatPassword,
                  controller: _repeatPasswordController,
                  suffix: IconButton(
                    splashRadius: 18,
                    onPressed: () => setState(
                      () => _obscureRepeatPassword = !_obscureRepeatPassword,
                    ),
                    icon: Icon(
                      _obscureRepeatPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _PasswordStrengthBar(
                  valid: passwordError == null && vm.password.isNotEmpty,
                  match: passwordsMatch,
                  passwordError: passwordError,
                ),
                const SizedBox(height: AutonannySpacing.xl),
                AutonannyButton(
                  label: 'Создать аккаунт',
                  onPressed: canSubmit ? vm.tryReg : null,
                ),
                const SizedBox(height: AutonannySpacing.sm),
                Text(
                  'Нажимая кнопку, вы подтверждаете согласие с условиями сервиса.',
                  style: AutonannyTypography.caption(color: colors.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({
    required this.valid,
    required this.match,
    required this.passwordError,
  });

  final bool valid;
  final bool match;
  final String? passwordError;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final filled = valid ? true : index == 0 && passwordError == null;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == 2 ? 0 : AutonannySpacing.xs,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? colors.statusSuccess : colors.borderSubtle,
                  borderRadius: AutonannyRadii.brFull,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AutonannySpacing.xs),
        Text(
          valid
              ? 'Надёжный пароль'
              : (passwordError ?? 'Минимум 8 символов, цифра, спецсимвол и заглавная буква'),
          style: AutonannyTypography.caption(
            color: valid ? colors.statusSuccess : colors.textTertiary,
          ),
        ),
        const SizedBox(height: AutonannySpacing.xs),
        Text(
          match ? 'Пароли совпадают' : 'Повторите пароль для подтверждения',
          style: AutonannyTypography.caption(
            color: match ? colors.statusSuccess : colors.textTertiary,
          ),
        ),
      ],
    );
  }
}
