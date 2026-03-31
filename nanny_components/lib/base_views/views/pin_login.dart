import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/pin_login_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class PinLoginView extends StatefulWidget {
  final Widget nextView;
  final Widget logoutView;

  const PinLoginView(
      {super.key, required this.nextView, required this.logoutView});

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
        body: FutureLoader(
          future: vm.isBioAuthAvailable,
          completeView: (context, data) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 760;
              final headerIconSize = compact ? 68.0 : 76.0;
              final headerIconRadius = compact ? 20.0 : 24.0;
              final horizontalPadding = compact ? 16.0 : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          compact ? 12 : 16,
                          24,
                          compact ? 20 : 28,
                        ),
                        decoration: const BoxDecoration(
                          gradient: NewDesignAuthTokens.primaryGradient,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: TextButton.icon(
                                onPressed: vm.logout,
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  "Выйти",
                                  style: NewDesignAuthTokens.bodyS.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 4 : 8),
                            Center(
                              child: Container(
                                width: headerIconSize,
                                height: headerIconSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(
                                    headerIconRadius,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: compact ? 30 : 34,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 16 : 20),
                            Text(
                              "Быстрый вход",
                              style: NewDesignAuthTokens.titleXL.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Введите 4-значный PIN-код, чтобы быстро вернуться в приложение.",
                              style: NewDesignAuthTokens.bodyM.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          horizontalPadding,
                          horizontalPadding,
                          horizontalPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: NewDesignAuthTokens.radiusMd,
                                border: Border.all(
                                  color: NewDesignAuthTokens.neutral200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: NewDesignAuthTokens.primary100,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: NewDesignAuthTokens.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      data
                                          ? "Можно использовать PIN-код или биометрию."
                                          : "Для входа доступен PIN-код.",
                                      style: NewDesignAuthTokens.bodyS.copyWith(
                                        color: NewDesignAuthTokens.neutral700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            FourDigitKeyboard(
                              bottomChild: data
                                  ? TextButton(
                                      onPressed: vm.useBioAuth,
                                      child: Text(
                                        "Использовать биометрию",
                                        style:
                                            NewDesignAuthTokens.bodyS.copyWith(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          errorView: (context, error) => ErrorView(errorText: error.toString()),
        ),
      ),
    );
  }
}
