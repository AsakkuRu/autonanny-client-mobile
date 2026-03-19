import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_components/base_views/view_models/welcome_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class WelcomeView extends StatefulWidget {
  final Widget regView;
  final List<LoginPath> loginPaths;

  const WelcomeView({
    super.key,
    required this.regView,
    required this.loginPaths,
  });

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  late final WelcomeVM vm;

  @override
  void initState() {
    super.initState();
    vm = WelcomeVM(
        context: context,
        update: setState,
        regScreen: widget.regView,
        loginPaths: widget.loginPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewDesignAuthTokens.neutral50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  "packages/nanny_components/assets/images/icon.png",
                  height: 120,
                ),
                const SizedBox(height: 20),
                Text(
                  "АвтоНяня",
                  style: NewDesignAuthTokens.titleXL.copyWith(
                    color: NewDesignAuthTokens.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Безопасные поездки для детей и спокойствие для родителей.",
                  textAlign: TextAlign.center,
                  style: NewDesignAuthTokens.bodyM,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: vm.navigateToLogin,
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
                      "Войти",
                      style: NewDesignAuthTokens.bodyS.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: vm.navigateToReg,
                    style: ButtonStyle(
                      side: const WidgetStatePropertyAll(
                        BorderSide(color: NewDesignAuthTokens.primary200, width: 1.5),
                      ),
                      shape: const WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: NewDesignAuthTokens.radiusLg,
                        ),
                      ),
                      backgroundColor: const WidgetStatePropertyAll(
                        NewDesignAuthTokens.neutral0,
                      ),
                    ),
                    child: Text(
                      "Зарегистрироваться",
                      style: NewDesignAuthTokens.bodyS.copyWith(
                        color: NewDesignAuthTokens.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
