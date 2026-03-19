import 'package:flutter/material.dart';
import 'package:nanny_components/styles/new_design_app.dart';

/// Базовая карточка нового дизайна.
/// Поддерживает выбранное состояние [isSelected].
class NdCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const NdCard({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(NDT.sp12),
        decoration: isSelected
            ? NDT.cardSelectedDecoration()
            : NDT.cardUnselectedDecoration(),
        child: child,
      ),
    );
  }
}
