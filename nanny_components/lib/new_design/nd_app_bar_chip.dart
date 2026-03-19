import 'package:flutter/material.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/nanny_core.dart';

/// Приветственный чип в шапке главного экрана.
/// Показывает аватарку с инициалом и имя пользователя.
/// По тапу на имя — вызывается [onNameTap].
class NdAppBarChip extends StatelessWidget {
  final VoidCallback? onNameTap;

  const NdAppBarChip({super.key, this.onNameTap});

  @override
  Widget build(BuildContext context) {
    final user = NannyUser.userInfo;
    final name = user?.name ?? '';
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : 'А';

    return GestureDetector(
      onTap: onNameTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NDT.sp8,
          vertical: NDT.sp6,
        ),
        decoration: BoxDecoration(
          color: NDT.mapOverlayBg.withOpacity(0.95),
          borderRadius: NDT.brFull,
          boxShadow: NDT.overlayShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(initial: initial),
            const SizedBox(width: NDT.sp8),
            Text(
              name.isNotEmpty ? 'Привет, $name!' : 'Привет!',
              style: NDT.labelL,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;

  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: NDT.avatarGradient,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: NDT.neutral0,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
