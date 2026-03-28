import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/rating/driver_rating_details_vm.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/models/from_api/driver_rating.dart';

class DriverRatingDetailsView extends StatefulWidget {
  const DriverRatingDetailsView({
    super.key,
    required this.driverId,
    this.driverName,
    this.driverPhoto,
  });

  final int driverId;
  final String? driverName;
  final String? driverPhoto;

  @override
  State<DriverRatingDetailsView> createState() =>
      _DriverRatingDetailsViewState();
}

class _DriverRatingDetailsViewState extends State<DriverRatingDetailsView> {
  late final DriverRatingDetailsVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriverRatingDetailsVM(
      context: context,
      update: setState,
      driverId: widget.driverId,
      driverName: widget.driverName,
      driverPhoto: widget.driverPhoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'Рейтинг водителя',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
      ),
      body: vm.isLoading
          ? const AutonannyLoadingState(
              label: 'Загружаем рейтинг водителя.',
            )
          : vm.rating == null
              ? AutonannyErrorState(
                  title: 'Не удалось загрузить рейтинг',
                  description: 'Попробуйте открыть экран ещё раз.',
                  actionLabel: 'Повторить',
                  onAction: vm.refresh,
                )
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AutonannySpacing.lg,
                      AutonannySpacing.sm,
                      AutonannySpacing.lg,
                      AutonannySpacing.xxl,
                    ),
                    children: [
                      _DriverOverviewCard(
                        driverName: widget.driverName,
                        driverPhoto: widget.driverPhoto,
                        rating: vm.rating!,
                      ),
                      const SizedBox(height: AutonannySpacing.lg),
                      _RatingSummaryCard(rating: vm.rating!),
                      const SizedBox(height: AutonannySpacing.lg),
                      _ReviewsSection(rating: vm.rating!),
                    ],
                  ),
                ),
    );
  }
}

class _DriverOverviewCard extends StatelessWidget {
  const _DriverOverviewCard({
    required this.driverName,
    required this.driverPhoto,
    required this.rating,
  });

  final String? driverName;
  final String? driverPhoto;
  final DriverRating rating;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final resolvedName = (driverName?.trim().isNotEmpty ?? false)
        ? driverName!.trim()
        : 'Водитель';
    final imageUrl = NannyConsts.buildFileUrl(driverPhoto);

    return AutonannyCard(
      child: Row(
        children: [
          AutonannyAvatar(
            imageUrl: imageUrl,
            initials: _initials(resolvedName),
            size: 68,
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolvedName,
                  style: AutonannyTypography.h3(color: colors.textPrimary),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  '${rating.totalReviews} ${_reviewWord(rating.totalReviews)}',
                  style: AutonannyTypography.bodyS(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((element) => element.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'A';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _reviewWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'отзыв';
    }
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'отзыва';
    }
    return 'отзывов';
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.rating});

  final DriverRating rating;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final rounded = rating.averageRating.round().clamp(0, 5);

    return AutonannyCard(
      child: Column(
        children: [
          Text(
            rating.averageRating.toStringAsFixed(1),
            style: AutonannyTypography.h1(color: colors.textPrimary),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AutonannySpacing.xs,
            children: List.generate(5, (index) {
              return AutonannyIcon(
                AutonannyIcons.star,
                size: 24,
                color: index < rounded
                    ? colors.statusWarning
                    : colors.borderStrong,
              );
            }),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Text(
            'Средняя оценка',
            style: AutonannyTypography.bodyS(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.rating});

  final DriverRating rating;

  @override
  Widget build(BuildContext context) {
    if (rating.reviews.isEmpty) {
      return const AutonannyEmptyState(
        title: 'Пока нет отзывов',
        description:
            'Оценки клиентов появятся здесь после первых завершённых поездок.',
        icon: AutonannyIcon(AutonannyIcons.chat, size: 36),
      );
    }

    return AutonannySectionContainer(
      title: 'Отзывы',
      subtitle: 'Последние оценки и комментарии клиентов.',
      child: Column(
        children: rating.reviews
            .map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
                child: _ReviewCard(review: review),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final DriverReview review;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final dateFormat = DateFormat('dd MMM yyyy', 'ru');

    return AutonannyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: AutonannySpacing.xs,
                children: List.generate(5, (index) {
                  return AutonannyIcon(
                    AutonannyIcons.star,
                    size: 18,
                    color: index < review.rating
                        ? colors.statusWarning
                        : colors.borderStrong,
                  );
                }),
              ),
              Text(
                dateFormat.format(review.date),
                style: AutonannyTypography.caption(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          if ((review.authorName?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AutonannySpacing.sm),
            Text(
              review.authorName!,
              style: AutonannyTypography.labelL(
                color: colors.textPrimary,
              ),
            ),
          ],
          if (review.criteria != null && review.criteria!.isNotEmpty) ...[
            const SizedBox(height: AutonannySpacing.sm),
            Wrap(
              spacing: AutonannySpacing.xs,
              runSpacing: AutonannySpacing.xs,
              children: review.criteria!
                  .map(
                    (criterion) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AutonannySpacing.sm,
                        vertical: AutonannySpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.statusInfoSurface,
                        borderRadius: AutonannyRadii.brFull,
                      ),
                      child: Text(
                        criterion,
                        style: AutonannyTypography.caption(
                          color: colors.actionPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if ((review.text?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AutonannySpacing.md),
            Text(
              review.text!,
              style: AutonannyTypography.bodyM(
                color: colors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
