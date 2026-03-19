import 'package:flutter/material.dart';
import 'package:nanny_components/widgets/net_image.dart';
import 'package:nanny_components/styles/nanny_theme.dart';

class ProfileImage extends StatelessWidget {
  final String url;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final String? initials;
  final bool showOnlineDot;

  const ProfileImage({
    super.key,
    this.padding,
    required this.url,
    required this.radius,
    this.onTap,
    this.initials,
    this.showOnlineDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(_radiusForSize(radius));

    Widget content;
    if (url.isNotEmpty) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: NetImage(
          url: url,
          placeholderPath:
              "packages/nanny_components/assets/images/no_user.jpg",
        ),
      );
    } else {
      content = Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NannyTheme.primaryLight,
              NannyTheme.primaryDark,
            ],
          ),
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          (initials ?? '')
                  .trim()
                  .isNotEmpty
              ? initials!.toUpperCase()
              : '',
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.35,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      );
    }

    return SizedBox(
      width: radius,
      height: radius,
      child: Stack(
        children: [
          Positioned.fill(
            child: IconButton(
              padding: padding,
              onPressed: onTap,
              splashRadius: radius * .5,
              icon: content,
            ),
          ),
          if (showOnlineDot)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: NannyTheme.success,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _radiusForSize(double size) {
    if (size <= 28) return size / 2;
    if (size <= 38) return 14;
    if (size <= 44) return 16;
    if (size <= 56) return 18;
    return 28;
  }
}
