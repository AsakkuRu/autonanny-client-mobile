import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/login_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class LoginView extends StatefulWidget {
  final String imgPath;
  final List<LoginPath> paths;

  const LoginView({
    super.key,
    required this.imgPath,
    required this.paths,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginVM vm;

  @override
  void initState() {
    super.initState();
    vm = LoginVM(
      context: context,
      update: setState,
      availableRoleLogin: widget.paths,
      paths: widget.paths,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewDesignAuthTokens.neutral50,
      body: AdaptBuilder(
        builder: (context, size) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Логотип / иллюстрация
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            widget.imgPath,
                            height: size.height * 0.22,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Text(
                      "С возвращением!",
                      style: NewDesignAuthTokens.titleXL,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Войдите в аккаунт, чтобы продолжить поездки с АвтоНяня.",
                      style: NewDesignAuthTokens.bodyM,
                    ),
                    const SizedBox(height: 28),
                    Form(
                      key: vm.phoneState,
                      child: NannyTextForm(
                        isExpanded: true,
                        labelText: "Телефон",
                        hintText: "+7 (777) 777 77-77",
                        formatters: [vm.phoneMask],
                        keyType: TextInputType.number,
                        validator: (text) {
                          if (vm.phone.length < 11) {
                            return "Введите номер телефона!";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: vm.passwordState,
                      child: NannyPasswordForm(
                        isExpanded: true,
                        labelText: "Пароль",
                        hintText: "••••••••",
                        validator: (text) {
                          if (vm.password.length < 8) {
                            return "Пароль не менее 8 символов!";
                          }
                          return null;
                        },
                        onChanged: (v) => vm.password = v,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: vm.toPasswordReset,
                        child: Text(
                          "Забыли пароль?",
                          style: NewDesignAuthTokens.bodyS.copyWith(
                            color: NewDesignAuthTokens.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: vm.isLoading ? null : vm.tryLogin,
                        style: ButtonStyle(
                          elevation: const WidgetStatePropertyAll(0),
                          backgroundColor: WidgetStatePropertyAll(
                            NewDesignAuthTokens.primary,
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: NewDesignAuthTokens.radiusLg,
                            ),
                          ),
                        ),
                        child: Text(
                          "Войти",
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
        },
      ),
    );
  }
}
