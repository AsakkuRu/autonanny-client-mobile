import 'package:flutter/cupertino.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';

class RateWidget extends StatelessWidget {
  final Function(int) tapCallback;
  final int selected;

  const RateWidget(
      {super.key, required this.tapCallback, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            5,
            (i) => CupertinoButton(
                padding: EdgeInsets.zero,
                child: AutonannyIcon(
                  AutonannyIcons.star,
                  size: 34,
                  color: i <= selected
                      ? colors.actionPrimary
                      : colors.borderStrong,
                ),
                onPressed: () => tapCallback(i))));
  }
}
