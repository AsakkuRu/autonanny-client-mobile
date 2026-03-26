import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/support/support_rating_vm.dart';
import 'package:nanny_client/widgets/rate_widget.dart';

class SupportRatingView extends StatefulWidget {
  final int ticketId;
  final VoidCallback? onSubmitted;

  const SupportRatingView({
    super.key,
    required this.ticketId,
    this.onSubmitted,
  });

  @override
  State<SupportRatingView> createState() => _SupportRatingViewState();
}

class _SupportRatingViewState extends State<SupportRatingView> {
  late SupportRatingVM vm;

  @override
  void initState() {
    super.initState();
    vm = SupportRatingVM(
      context: context,
      update: setState,
      ticketId: widget.ticketId,
      onSubmitted: widget.onSubmitted,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'Оценка поддержки',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
        actions: [
          TextButton(
            onPressed: vm.skip,
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
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: colors.statusInfoSurface,
                        borderRadius: AutonannyRadii.brFull,
                      ),
                      child: Center(
                        child: AutonannyIcon(
                          AutonannyIcons.chat,
                          size: 36,
                          color: colors.statusInfo,
                        ),
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.lg),
                    Text(
                      'Оцените качество поддержки',
                      textAlign: TextAlign.center,
                      style: AutonannyTypography.h2(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      'Ваш отзыв помогает нам становиться лучше.',
                      textAlign: TextAlign.center,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Плохо',
                          style: AutonannyTypography.caption(
                            color: colors.textTertiary,
                          ),
                        ),
                        Text(
                          'Отлично',
                          style: AutonannyTypography.caption(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AutonannySpacing.sm),
                    RateWidget(
                      tapCallback: vm.selectRating,
                      selected: vm.rating - 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Комментарий',
                subtitle: 'Необязательно, но помогает лучше понять ситуацию.',
                child: AutonannyTextField(
                  controller: vm.commentController,
                  hintText: 'Оставьте комментарий',
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: AutonannySpacing.xl),
              AutonannyButton(
                label: 'Отправить оценку',
                onPressed: vm.canSubmit ? vm.submitRating : null,
                isLoading: vm.isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
