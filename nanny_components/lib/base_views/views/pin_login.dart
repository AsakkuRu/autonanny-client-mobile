import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/pin_login_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class PinLoginView extends StatefulWidget {
  final Widget nextView;
  final Widget logoutView;
  
  const PinLoginView({
    super.key,
    required this.nextView,
    required this.logoutView
  });

  @override
  State<PinLoginView> createState() => _PinLoginViewState();
}

class _PinLoginViewState extends State<PinLoginView> {
  late PinLoginVM vm;

  @override
  void initState() {
    super.initState();
    vm = PinLoginVM(
      context: context, 
      update: setState, 
      nextView: widget.nextView, 
      logoutView: widget.logoutView,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: NewDesignAuthTokens.neutral50,
        appBar: NannyAppBar(
          hasBackButton: false,
          color: NewDesignAuthTokens.neutral50,
          actions: [
            IconButton(
              onPressed: vm.logout,
              icon: const Icon(Icons.exit_to_app_rounded),
              splashRadius: 30,
            ),
          ],
        ),
        body: FutureLoader(
          future: vm.isBioAuthAvailable,
          completeView: (context, data) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  "Введите код авторизации",
                  textAlign: TextAlign.center,
                  style: NewDesignAuthTokens.titleM,
                ),
                const SizedBox(height: 8),
                Text(
                  "Это PIN‑код для быстрого входа в приложение.",
                  textAlign: TextAlign.center,
                  style: NewDesignAuthTokens.bodyM,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: FourDigitKeyboard(
                    bottomChild: data
                        ? TextButton(
                            onPressed: vm.useBioAuth,
                            child: Text(
                              "Использовать биометрию",
                              style: NewDesignAuthTokens.bodyS.copyWith(
                                color: NewDesignAuthTokens.primary,
                              ),
                            ),
                          )
                        : null,
                    onCodeChanged: (code) {
                      vm.code = code;
                      if (code.length > 3) vm.checkPinCode();
                    },
                  ),
                ),
              ],
            ),
          ),
          errorView: (context, error) =>
              ErrorView(errorText: error.toString()),
        ),
      ),
    );
  }
}