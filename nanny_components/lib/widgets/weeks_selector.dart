import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class WeeksSelector extends StatefulWidget {
  final void Function(NannyWeekday weekday) onChanged;
  final List<NannyWeekday> selectedWeekday;

  const WeeksSelector({
    super.key,
    required this.onChanged,
    required this.selectedWeekday,
  });

  @override
  State<WeeksSelector> createState() => _WeeksSelectorState();
}

class _WeeksSelectorState extends State<WeeksSelector> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final itemWidth =
            ((constraints.maxWidth - (spacing * 6)) / 7).clamp(34.0, 56.0);
        final itemHeight = itemWidth < 42 ? 42.0 : 48.0;

        return Row(
          children: [
            for (var index = 0; index < NannyWeekday.values.length; index++) ...[
              if (index > 0) const SizedBox(width: spacing),
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: _WeekdayButton(
                  weekday: NannyWeekday.values[index],
                  isSelected:
                      widget.selectedWeekday.contains(NannyWeekday.values[index]),
                  onPressed: () => widget.onChanged(NannyWeekday.values[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _WeekdayButton extends StatelessWidget {
  const _WeekdayButton({
    required this.weekday,
    required this.isSelected,
    required this.onPressed,
  });

  final NannyWeekday weekday;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: (isSelected
              ? NannyButtonStyles.defaultButtonStyle
              : NannyButtonStyles.whiteButton)
          .copyWith(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      onPressed: onPressed,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            weekday.shortName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? NannyTheme.secondary : const Color(0xFF2B2B2B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
