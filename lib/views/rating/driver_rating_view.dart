import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/rating/driver_rating_vm.dart';
import 'package:nanny_core/nanny_core.dart';

class DriverRatingView extends StatefulWidget {
  const DriverRatingView({
    super.key,
    required this.orderId,
    this.driverName,
    this.driverPhoto,
  });

  final int orderId;
  final String? driverName;
  final String? driverPhoto;

  @override
  State<DriverRatingView> createState() => _DriverRatingViewState();
}

class _DriverRatingViewState extends State<DriverRatingView> {
  late final DriverRatingVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriverRatingVM(
      context: context,
      update: setState,
      orderId: widget.orderId,
      driverName: widget.driverName,
      driverPhoto: widget.driverPhoto,
    );
    vm.loadExistingRating();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    if (vm.isInitializing) {
      return const AutonannyAppScaffold(
        appBar: AutonannyAppBar(title: 'Оценка поездки'),
        body: SafeArea(
          top: false,
          child: AutonannyLoadingState(
            label: 'Загружаем данные оценки.',
          ),
        ),
      );
    }

    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: vm.hasExistingRating ? 'Изменить оценку' : 'Оцените поездку',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.close),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Закрыть',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              'Пропустить',
              style: AutonannyTypography.labelM(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.lg,
            AutonannySpacing.sm,
            AutonannySpacing.lg,
            AutonannySpacing.xxl,
          ),
          child: Column(
            children: [
              AutonannyCard(
                child: Column(
                  children: [
                    _DriverHeader(
                      driverName: widget.driverName,
                      driverPhoto: widget.driverPhoto,
                    ),
                    const SizedBox(height: AutonannySpacing.xl),
                    _RatingStars(
                      rating: vm.rating,
                      onSelected: vm.setRating,
                    ),
                    const SizedBox(height: AutonannySpacing.sm),
                    Text(
                      vm.ratingText,
                      style: AutonannyTypography.labelL(
                        color: vm.rating > 0
                            ? colors.actionPrimary
                            : colors.textTertiary,
                      ),
                    ),
                    if (vm.hasExistingRating) ...[
                      const SizedBox(height: AutonannySpacing.sm),
                      const AutonannyInlineBanner(
                        title: 'Оценка уже сохранена',
                        message:
                            'Форма заполнена текущими данными. Вы можете изменить оценку и комментарий.',
                        tone: AutonannyBannerTone.info,
                        leading: AutonannyIcon(AutonannyIcons.info),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Что понравилось?',
                subtitle:
                    'Можно отметить несколько критериев, которые запомнились в поездке.',
                child: Wrap(
                  spacing: AutonannySpacing.sm,
                  runSpacing: AutonannySpacing.sm,
                  children: vm.availableCriteria
                      .map(
                        (criterion) => _CriterionChip(
                          label: criterion,
                          selected: vm.selectedCriteria.contains(criterion),
                          onTap: () => vm.toggleCriterion(criterion),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Комментарий',
                subtitle: 'Необязательно, но помогает нам лучше понять опыт.',
                child: AutonannyTextField(
                  controller: vm.reviewController,
                  hintText: 'Расскажите подробнее о поездке...',
                  maxLines: 4,
                ),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: AutonannySpacing.lg),
                AutonannyInlineBanner(
                  title: 'Не удалось сохранить оценку',
                  message: vm.error,
                  tone: AutonannyBannerTone.danger,
                  leading: const AutonannyIcon(AutonannyIcons.error),
                ),
              ],
              const SizedBox(height: AutonannySpacing.xl),
              AutonannyButton(
                label:
                    vm.hasExistingRating ? 'Обновить оценку' : 'Отправить оценку',
                onPressed: vm.rating > 0 ? vm.submitRating : null,
                isLoading: vm.isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({
    required this.driverName,
    required this.driverPhoto,
  });

  final String? driverName;
  final String? driverPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final resolvedName = (driverName?.trim().isNotEmpty ?? false)
        ? driverName!.trim()
        : 'Водитель';
    final imageUrl = NannyConsts.buildFileUrl(driverPhoto);

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: colors.statusInfoSurface,
            borderRadius: AutonannyRadii.brFull,
          ),
          child: Center(
            child: AutonannyAvatar(
              imageUrl: imageUrl,
              initials: _initials(resolvedName),
              size: 76,
            ),
          ),
        ),
        const SizedBox(height: AutonannySpacing.lg),
        Text(
          resolvedName,
          textAlign: TextAlign.center,
          style: AutonannyTypography.h2(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AutonannySpacing.xs),
        Text(
          'Как прошла поездка?',
          textAlign: TextAlign.center,
          style: AutonannyTypography.bodyS(
            color: colors.textSecondary,
          ),
        ),
      ],
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
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({
    required this.rating,
    required this.onSelected,
  });

  final int rating;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AutonannySpacing.sm,
      children: List.generate(5, (index) {
        final selected = index < rating;
        return GestureDetector(
          onTap: () => onSelected(index + 1),
          child: AnimatedContainer(
            duration: AutonannyMotion.fast,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? colors.statusWarningSurface
                  : colors.surfaceSecondary,
              borderRadius: AutonannyRadii.brFull,
              border: Border.all(
                color: selected ? colors.statusWarning : colors.borderSubtle,
              ),
            ),
            alignment: Alignment.center,
            child: AutonannyIcon(
              AutonannyIcons.star,
              size: 28,
              color: selected ? colors.statusWarning : colors.textTertiary,
            ),
          ),
        );
      }),
    );
  }
}

class _CriterionChip extends StatelessWidget {
  const _CriterionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colors.statusInfoSurface,
      checkmarkColor: colors.actionPrimary,
      backgroundColor: colors.surfaceSecondary,
      side: BorderSide(
        color: selected ? colors.actionPrimary : colors.borderSubtle,
      ),
      labelStyle: AutonannyTypography.bodyS(
        color: selected ? colors.actionPrimary : colors.textPrimary,
      ),
      shape: const StadiumBorder(),
    );
  }
}
