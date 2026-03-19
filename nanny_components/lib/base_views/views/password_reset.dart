import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/password_reset_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class PasswordResetView extends StatefulWidget {
  const PasswordResetView({super.key});

  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  late PasswordResetVm vm;

  @override
  void initState() {
    super.initState();
    vm = PasswordResetVm(context: context, update: setState);
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: NewDesignAuthTokens.neutral50,
        appBar: const NannyAppBar(),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Восстановление пароля",
                style: NewDesignAuthTokens.titleM,
              ),
              const SizedBox(height: 8),
              Text(
                "Задайте новый пароль для аккаунта, чтобы продолжить пользоваться АвтоНяня.",
                textAlign: TextAlign.left,
                style: NewDesignAuthTokens.bodyM,
              ),
              const SizedBox(height: 24),
              Form(
                key: vm.passState,
                child: NannyPasswordForm(
                  labelText: "Новый пароль*",
                  validator: (text) {
                    if (vm.password.length < 8) {
                      return "Пароль не менее 8 символов!";
                    }
                    return null;
                  },
                  onChanged: (text) => vm.password = text,
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: vm.passConfirmState,
                child: NannyPasswordForm(
                  labelText: "Подтвердите новый пароль*",
                  validator: (text) {
                    if (vm.password != vm.passwordConfirm) {
                      return "Пароли должны совпадать!";
                    }
                    return null;
                  },
                  onChanged: (text) => vm.passwordConfirm = text,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: vm.tryResetPassword,
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
                    "Обновить пароль",
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
      ),
    );
  }
}