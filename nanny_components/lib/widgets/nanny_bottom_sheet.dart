import 'package:flutter/material.dart';
import 'package:nanny_components/styles/nanny_theme.dart';
import 'package:nanny_components/widgets/adapt_builder.dart';

class NannyBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final bool roundBottom;

  const NannyBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.roundBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptBuilder(
      builder: (context, size) {
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: roundBottom
                ? BorderRadius.circular(32)
                : const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
            boxShadow: [
              BoxShadow(
                color: NannyTheme.shadow.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, -8),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        );
      },
    );
  }
}
