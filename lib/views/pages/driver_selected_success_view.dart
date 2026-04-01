import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';

class DriverSelectedSuccessView extends StatelessWidget {
  const DriverSelectedSuccessView({
    super.key,
    required this.driverName,
    required this.onOpenContract,
    required this.onOpenChat,
  });

  final String driverName;
  final VoidCallback onOpenContract;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AutonannyGradients.hero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AutonannySpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xl),
                Center(
                  child: Text(
                    'Водитель выбран!',
                    textAlign: TextAlign.center,
                    style: AutonannyTypography.h1(color: Colors.white),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                Center(
                  child: Text(
                    '$driverName получит уведомление, что вы выбрали его водителем.',
                    textAlign: TextAlign.center,
                    style: AutonannyTypography.bodyM(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ),
                const Spacer(),
                AutonannyButton(
                  label: 'Перейти в контракт',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: onOpenContract,
                ),
                const SizedBox(height: AutonannySpacing.sm),
                AutonannyButton(
                  label: 'Написать водителю',
                  variant: AutonannyButtonVariant.ghost,
                  onPressed: onOpenChat,
                ),
                const SizedBox(height: AutonannySpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
