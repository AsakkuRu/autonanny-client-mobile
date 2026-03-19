import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_components/nanny_components.dart';

import '../styles/nanny_theme.dart';

class NannyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isTransparent;
  final bool hasBackButton;
  final bool isWhiteSystemBar;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final String? title;
  final Function()? onBackPressed;
  final Color? color;
  final Gradient? gradient;

  const NannyAppBar({
    super.key,
    this.isTransparent = true,
    this.hasBackButton = true,
    this.isWhiteSystemBar = true,
    this.actions,
    this.leading,
    this.bottom,
    this.title,
    this.color,
    this.onBackPressed,
    this.gradient,
  });

  /// Светлый вариант AppBar (белый фон, тёмный текст).
  const NannyAppBar.light({
    super.key,
    this.isTransparent = false,
    this.hasBackButton = true,
    this.isWhiteSystemBar = true,
    this.actions,
    this.leading,
    this.bottom,
    this.title,
    this.onBackPressed,
  })  : color = NannyTheme.secondary,
        gradient = null;

  /// Градиентный вариант для экранов баланс/профиль/детали.
  const NannyAppBar.gradient({
    super.key,
    this.hasBackButton = true,
    this.isWhiteSystemBar = true,
    this.actions,
    this.leading,
    this.bottom,
    this.title,
    this.onBackPressed,
    required this.gradient,
  })  : isTransparent = false,
        color = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = gradient != null
        ? Colors.transparent
        : (color == NannyTheme.secondary && isDarkTheme
            ? Theme.of(context).colorScheme.surface
            : (color ?? NannyTheme.background));
    final bool isDarkBackground =
        (gradient != null ? NannyTheme.neutral900 : bgColor)
                .computeLuminance() <
            0.5;

    return AppBar(
      elevation: isTransparent ? 0 : 10,
      backgroundColor: bgColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: bgColor,
        statusBarIconBrightness:
            isDarkBackground ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDarkBackground ? Brightness.dark : Brightness.light,
      ),
      foregroundColor:
          isDarkBackground ? Colors.white : NannyTheme.onSurface,
      forceMaterialTransparency: isTransparent || gradient != null,
      flexibleSpace: gradient != null
          ? Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
            )
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      toolbarHeight: preferredSize.height,
      bottom: bottom,
      leading: leading != null
          ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: leading,
            )
          : (hasBackButton
              ? IconButton(
                  onPressed: onBackPressed != null
                      ? () => onBackPressed?.call()
                      : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: isDarkBackground
                        ? Colors.white
                        : NannyTheme.neutral700,
                  ),
                  splashRadius: 25,
                )
              : null),
      actions: actions
        ?..add(
          const SizedBox(width: 10),
        ),
      title: title != null
          ? FittedBox(
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDarkBackground
                          ? Colors.white
                          : NannyTheme.neutral900,
                    ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      centerTitle: true,
      shadowColor: NannyTheme.shadow.withOpacity(.19),
    );
  }

  @override
  Size get preferredSize => Size(double.maxFinite, bottom == null ? 80 : 120);
}
