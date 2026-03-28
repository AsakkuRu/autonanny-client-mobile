import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/welcome_vm.dart';
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
      backgroundColor: NewDesignAuthTokens.primaryDark,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: NewDesignAuthTokens.primaryGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Image.asset(
                    "packages/nanny_components/assets/images/icon.png",
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "Безопасные поездки\nдля ваших детей",
                  textAlign: TextAlign.center,
                  style: NewDesignAuthTokens.titleXL.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Проверенные водители-няни, GPS-отслеживание и спокойствие родителей в каждой поездке.",
                  textAlign: TextAlign.center,
                  style: NewDesignAuthTokens.bodyM.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 28),
                const Row(
                  children: [
                    Expanded(
                      child: _TrustMetric(value: '1 200+', label: 'водителей'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _TrustMetric(value: '4.97', label: 'рейтинг'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _TrustMetric(value: '50К+', label: 'поездок'),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: vm.navigateToReg,
                    style: const ButtonStyle(
                      elevation: WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.white,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: NewDesignAuthTokens.radiusLg,
                        ),
                      ),
                    ),
                    child: Text(
                      "Зарегистрироваться",
                      style: NewDesignAuthTokens.bodyS.copyWith(
                        color: NewDesignAuthTokens.primaryDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: vm.navigateToLogin,
                  child: RichText(
                    text: TextSpan(
                      style: NewDesignAuthTokens.bodyS.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                      children: [
                        const TextSpan(text: "Уже есть аккаунт? "),
                        TextSpan(
                          text: "Войти",
                          style: NewDesignAuthTokens.bodyS.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: NewDesignAuthTokens.radiusMd,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: NewDesignAuthTokens.titleM.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: NewDesignAuthTokens.captionS.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
