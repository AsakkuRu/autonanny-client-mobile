import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:nanny_client/views/home.dart';

class SuccessRegView extends StatelessWidget {
  const SuccessRegView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AutonannyGradients.hero,
        ),
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
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
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
                    'Добро пожаловать!',
                    textAlign: TextAlign.center,
                    style: AutonannyTypography.h1(color: Colors.white),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                Center(
                  child: Text(
                    'Аккаунт создан. Теперь добавьте детей и создайте первое расписание.',
                    textAlign: TextAlign.center,
                    style: AutonannyTypography.bodyM(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xl),
                _ActionRow(
                  icon: Icons.child_care_outlined,
                  label: 'Добавьте профиль ребёнка',
                ),
                const SizedBox(height: AutonannySpacing.md),
                _ActionRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Создайте первое расписание',
                ),
                const Spacer(),
                AutonannyButton(
                  label: 'Перейти в приложение',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                    (route) => false,
                  ),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutonannySpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AutonannyRadii.brLg,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AutonannySpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AutonannyTypography.bodyM(
                color: Colors.white,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
