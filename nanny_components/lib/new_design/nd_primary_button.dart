import 'package:flutter/material.dart';
import 'package:nanny_components/styles/new_design_app.dart';

/// Большая градиентная кнопка CTA.
/// При [isLoading] показывает спиннер вместо метки.
/// При [isEnabled] == false — кнопка затемнена и некликабельна.
class NdPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isEnabled;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const NdPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = isEnabled && !isLoading && onTap != null;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: isEnabled ? NDT.ctaGradient : null,
            color: isEnabled ? null : NDT.neutral300,
            borderRadius: NDT.brXl,
            boxShadow: isEnabled && canTap ? NDT.ctaShadow : null,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: NDT.neutral0,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leadingIcon != null) ...[
                        Icon(leadingIcon, color: NDT.neutral0, size: 20),
                        const SizedBox(width: NDT.sp8),
                      ],
                      Text(label, style: NDT.ctaLabel),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: NDT.sp8),
                        Icon(trailingIcon, color: NDT.neutral0, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
