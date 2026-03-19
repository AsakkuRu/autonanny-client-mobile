import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/first_pin_set_vm.dart';
import 'package:nanny_components/widgets/four_digit_keyboard.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class FirstPinSet extends StatefulWidget {
  final Widget nextView;
  
  const FirstPinSet({
    super.key,
    required this.nextView,
  });

  @override
  State<FirstPinSet> createState() => _FirstPinSetState();
}

class _FirstPinSetState extends State<FirstPinSet> {
  late FirstPinSetVM vm;

  @override
  void initState() {
    super.initState();
    vm = FirstPinSetVM(context: context, update: setState, nextView: widget.nextView);
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: NewDesignAuthTokens.neutral50,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                "Задайте код авторизации в приложении",
                textAlign: TextAlign.center,
                style: NewDesignAuthTokens.titleM,
              ),
              const SizedBox(height: 8),
              Text(
                "Этот PIN‑код будет использоваться для быстрого и безопасного входа.",
                textAlign: TextAlign.center,
                style: NewDesignAuthTokens.bodyM,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FourDigitKeyboard(
                  onCodeChanged: (code) {
                    vm.code = code;
                    if (code.length > 3) vm.setPinCode();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}