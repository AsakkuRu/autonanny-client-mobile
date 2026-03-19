import 'package:flutter/material.dart';
import 'package:nanny_components/styles/nanny_theme.dart';

enum NannyBadgeType { green, purple, amber, red, gray, white }

class NannyBadge extends StatelessWidget {
  final NannyBadgeType type;
  final String text;
  final Widget? icon;
  final bool dense;

  const NannyBadge({
    super.key,
    required this.type,
    required this.text,
    this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForType(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: colors.borderColor != null
            ? Border.all(color: colors.borderColor!)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _colorsForType(NannyBadgeType type) {
    switch (type) {
      case NannyBadgeType.green:
        return _BadgeColors(
          background: const Color.fromRGBO(34, 197, 94, 0.12),
          text: NannyTheme.successText,
        );
      case NannyBadgeType.purple:
        return _BadgeColors(
          background: NannyTheme.primaryLight.withOpacity(0.08),
          text: NannyTheme.primary,
        );
      case NannyBadgeType.amber:
        return _BadgeColors(
          background: const Color.fromRGBO(245, 158, 11, 0.12),
          text: NannyTheme.warningText,
        );
      case NannyBadgeType.red:
        return _BadgeColors(
          background: const Color.fromRGBO(239, 68, 68, 0.10),
          text: NannyTheme.danger,
        );
      case NannyBadgeType.white:
        return _BadgeColors(
          background: Colors.white.withOpacity(0.2),
          text: Colors.white,
          borderColor: Colors.white.withOpacity(0.25),
        );
      case NannyBadgeType.gray:
      default:
        return _BadgeColors(
          background: NannyTheme.neutral100,
          text: NannyTheme.neutral500,
        );
    }
  }
}

class _BadgeColors {
  final Color background;
  final Color text;
  final Color? borderColor;

  const _BadgeColors({
    required this.background,
    required this.text,
    this.borderColor,
  });
}

