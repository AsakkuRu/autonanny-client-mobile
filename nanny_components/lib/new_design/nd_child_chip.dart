import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/nanny_core.dart';

/// Чип ребёнка для блока «Кто едет».
/// [isSelected] управляет подсветкой.
/// [onTap] — выбор/снятие выбора.
class NdChildChip extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isSelected;
  final VoidCallback? onTap;

  const NdChildChip({
    super.key,
    required this.name,
    this.photoUrl,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'Р';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: NDT.sp10,
          vertical: NDT.sp8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? NDT.primary100 : NDT.neutral100,
          borderRadius: NDT.brFull,
          border: Border.all(
            color: isSelected ? NDT.primary : NDT.neutral200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(
              initial: initial,
              photoUrl: photoUrl,
              selected: isSelected,
            ),
            const SizedBox(width: NDT.sp6),
            Text(
              name,
              style: NDT.chipLabel.copyWith(
                color: isSelected ? NDT.primary : NDT.neutral700,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: NDT.sp4),
              Icon(Icons.check_rounded, size: 14, color: NDT.primary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Пунктирная кнопка «+» для добавления ребёнка.
class NdAddChildButton extends StatelessWidget {
  final VoidCallback? onTap;

  const NdAddChildButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: NDT.neutral100,
          shape: BoxShape.circle,
          border: Border.all(
            color: NDT.neutral300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: const Icon(Icons.add_rounded, color: NDT.neutral500, size: 22),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final String? photoUrl;
  final bool selected;

  const _Avatar({
    required this.initial,
    this.photoUrl,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AutonannyAvatar(
      imageUrl: NannyConsts.buildFileUrl(photoUrl),
      initials: initial,
      size: 24,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
