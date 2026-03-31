import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/nanny_core.dart';

/// Приветственный чип в шапке главного экрана.
/// Показывает аватарку с инициалом и имя пользователя.
/// По тапу на имя — вызывается [onNameTap].
class NdAppBarChip extends StatelessWidget {
  final VoidCallback? onNameTap;

  const NdAppBarChip({super.key, this.onNameTap});

  @override
  Widget build(BuildContext context) {
    final user = NannyUser.userInfo;
    final name = user?.name ?? '';
    final rawPhotoPath = user?.photoPath.trim();
    final photoUrl = (rawPhotoPath?.isNotEmpty ?? false)
        ? NannyConsts.buildFileUrl(rawPhotoPath)
        : null;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'А';

    return GestureDetector(
      onTap: onNameTap,
      child: Container(
        height: 40,
        constraints: const BoxConstraints(maxWidth: 216),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(
          NDT.sp6,
          NDT.sp4,
          NDT.sp12,
          NDT.sp4,
        ),
        decoration: BoxDecoration(
          color: NDT.mapOverlayBg.withValues(alpha: 0.95),
          borderRadius: NDT.brFull,
          boxShadow: NDT.overlayShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(initial: initial, imageUrl: photoUrl),
            const SizedBox(width: NDT.sp8),
            Flexible(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: NDT.labelL,
                  children: [
                    const TextSpan(text: 'Привет, '),
                    TextSpan(
                      text: name.isNotEmpty ? name : 'друг',
                      style: NDT.labelL.copyWith(color: NDT.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final String? imageUrl;

  const _Avatar({
    required this.initial,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 28,
      child: ClipOval(
        child: AutonannyAvatar(
          imageUrl: imageUrl,
          initials: initial,
          size: 28,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
