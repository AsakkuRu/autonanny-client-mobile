import 'package:flutter/material.dart';
import 'package:nanny_components/styles/new_design_app.dart';

/// Круглая/прямоугольная кнопка-иконка для оверлеев на карте.
class NdIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;
  final bool isDanger;
  final double size;

  const NdIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
    this.isDanger = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDanger ? NDT.danger : NDT.mapOverlayBg;
    final iconColor = isDanger ? NDT.neutral0 : NDT.neutral700;
    final shadowColor = isDanger
        ? const Color.fromRGBO(239, 68, 68, 0.4)
        : const Color.fromRGBO(15, 15, 30, 0.10);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: NDT.brSm,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          if (hasBadge)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: NDT.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: NDT.neutral0, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
