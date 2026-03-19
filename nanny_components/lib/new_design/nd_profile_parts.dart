import 'package:flutter/material.dart';
import 'package:nanny_components/styles/new_design_app.dart';

enum NdProfileAccent { purple, amber, green, gray, red }

enum NdBadgeTone { neutral, green, purple, amber, red }

class NdSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const NdSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: NDT.sp12),
      decoration: NDT.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(title.toUpperCase(), style: NDT.sectionCaption),
          ),
          const Divider(height: 1, color: NDT.neutral100),
          ...children,
        ],
      ),
    );
  }
}

class NdProfileRow extends StatelessWidget {
  final IconData icon;
  final NdProfileAccent accent;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showChevron;
  final String? badgeText;
  final NdBadgeTone badgeTone;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final Widget? trailing;
  final bool enabled;

  const NdProfileRow({
    super.key,
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.onTap,
    this.showChevron = true,
    this.badgeText,
    this.badgeTone = NdBadgeTone.neutral,
    this.toggleValue,
    this.onToggle,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(NDT.radiusMd),
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _ProfileIcon(accent: accent, icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label.isNotEmpty)
                        Text(label, style: NDT.bodyS.copyWith(color: NDT.neutral400)),
                      if (label.isNotEmpty) const SizedBox(height: 2),
                      Text(
                        value,
                        style: NDT.bodyL.copyWith(color: NDT.neutral900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (badgeText != null) ...[
                  NdBadge(text: badgeText!, tone: badgeTone),
                  const SizedBox(width: 8),
                ],
                if (toggleValue != null)
                  NdToggle(
                    value: toggleValue!,
                    onChanged: onToggle,
                  )
                else if (trailing != null)
                  trailing!
                else if (showChevron)
                  const Icon(Icons.chevron_right_rounded,
                      color: NDT.neutral300, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NdBadge extends StatelessWidget {
  final String text;
  final NdBadgeTone tone;

  const NdBadge({
    super.key,
    required this.text,
    this.tone = NdBadgeTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _badgeColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: NDT.brFull,
      ),
      child: Text(
        text,
        style: NDT.labelM.copyWith(color: colors.$2, fontSize: 11),
      ),
    );
  }

  (Color, Color) _badgeColors(NdBadgeTone tone) {
    switch (tone) {
      case NdBadgeTone.green:
        return (const Color(0xFFE8F9EE), const Color(0xFF1A9B49));
      case NdBadgeTone.purple:
        return (NDT.primary100, NDT.primary);
      case NdBadgeTone.amber:
        return (const Color(0xFFFFF4DE), const Color(0xFFD97706));
      case NdBadgeTone.red:
        return (const Color(0xFFFDECEC), NDT.danger);
      case NdBadgeTone.neutral:
        return (NDT.neutral100, NDT.neutral500);
    }
  }
}

class NdToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const NdToggle({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? NDT.primary : NDT.neutral200,
          borderRadius: NDT.brFull,
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: NDT.neutral0,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class NdThemeOptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const NdThemeOptionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? NDT.primary100 : NDT.neutral0,
            borderRadius: NDT.brMd,
            border: Border.all(
              color: isActive ? NDT.primary : NDT.neutral200,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? NDT.primary : NDT.neutral500,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: NDT.bodyM.copyWith(
                  color: isActive ? NDT.primary : NDT.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final NdProfileAccent accent;
  final IconData icon;

  const _ProfileIcon({
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colors(accent);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: colors.$2),
    );
  }

  (Color, Color) _colors(NdProfileAccent tone) {
    switch (tone) {
      case NdProfileAccent.purple:
        return (NDT.primary100, NDT.primary);
      case NdProfileAccent.amber:
        return (const Color(0xFFFFF4DE), const Color(0xFFD97706));
      case NdProfileAccent.green:
        return (const Color(0xFFE8F9EE), const Color(0xFF1A9B49));
      case NdProfileAccent.red:
        return (const Color(0xFFFDECEC), NDT.danger);
      case NdProfileAccent.gray:
        return (NDT.neutral100, NDT.neutral500);
    }
  }
}
