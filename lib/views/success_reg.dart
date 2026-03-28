import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:nanny_client/views/home.dart';

class SuccessRegView extends StatelessWidget {
  const SuccessRegView({super.key});

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                'packages/nanny_components/assets/images/connection.png'),
            const SizedBox(height: AutonannySpacing.xl),
            Text(
              "Вы успешно зарегистрировались!",
              textAlign: TextAlign.center,
              style: AutonannyTypography.h3(),
            ),
            const SizedBox(height: AutonannySpacing.md),
            Text(
              "Теперь можно перейти в приложение и продолжить настройку.",
              textAlign: TextAlign.center,
              style: AutonannyTypography.bodyM(
                color: context.autonannyColors.textSecondary,
              ),
            ),
            const SizedBox(height: AutonannySpacing.xxl),
            AutonannyButton(
              label: "Продолжить",
              expand: false,
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeView()),
                (route) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
