import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/support/complaint_vm.dart';

class ComplaintView extends StatefulWidget {
  final int? orderId;
  final int? driverId;
  final String? driverName;

  const ComplaintView({
    super.key,
    this.orderId,
    this.driverId,
    this.driverName,
  });

  @override
  State<ComplaintView> createState() => _ComplaintViewState();
}

class _ComplaintViewState extends State<ComplaintView> {
  late ComplaintVM vm;

  @override
  void initState() {
    super.initState();
    vm = ComplaintVM(
      context: context,
      update: setState,
      orderId: widget.orderId,
      driverId: widget.driverId,
      driverName: widget.driverName,
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
        title: 'Подать жалобу',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.driverName != null) ...[
                AutonannyInlineBanner(
                  title: 'Жалоба на водителя',
                  message: widget.driverName,
                  tone: AutonannyBannerTone.warning,
                  leading: const AutonannyIcon(AutonannyIcons.warning),
                ),
                const SizedBox(height: AutonannySpacing.lg),
              ],
              AutonannySectionContainer(
                title: 'Причина жалобы',
                subtitle: 'Выберите основной повод обращения.',
                child: Column(
                  children: vm.complaintReasons
                      .map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AutonannySpacing.sm,
                          ),
                          child: _ReasonTile(
                            reason: reason,
                            isSelected: vm.selectedReason == reason,
                            onTap: () => vm.selectReason(reason),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Описание проблемы',
                subtitle: 'Опишите ситуацию подробнее.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: vm.descriptionController,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Что произошло?',
                        hintStyle: AutonannyTypography.bodyS(
                          color: colors.textTertiary,
                        ),
                        filled: true,
                        fillColor: colors.surfaceSecondary,
                        contentPadding: const EdgeInsets.all(
                          AutonannySpacing.lg,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AutonannyRadii.brLg,
                          borderSide: BorderSide(color: colors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AutonannyRadii.brLg,
                          borderSide: BorderSide(
                            color: colors.actionPrimary,
                            width: 1.4,
                          ),
                        ),
                      ),
                      style: AutonannyTypography.bodyM(
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Чем подробнее описание, тем быстрее мы разберём ситуацию.',
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Доказательства',
                subtitle: 'Фото или видео можно приложить при необходимости.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vm.attachments.isNotEmpty) ...[
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: vm.attachments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AutonannySpacing.sm),
                          itemBuilder: (context, index) {
                            return _AttachmentTile(
                              file: vm.attachments[index],
                              onRemove: () => vm.removeAttachment(index),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AutonannySpacing.md),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: AutonannyButton(
                            label: 'Фото',
                            variant: AutonannyButtonVariant.secondary,
                            leading: const AutonannyIcon(
                              AutonannyIcons.card,
                            ),
                            onPressed: vm.pickImage,
                          ),
                        ),
                        const SizedBox(width: AutonannySpacing.sm),
                        Expanded(
                          child: AutonannyButton(
                            label: 'Видео',
                            variant: AutonannyButtonVariant.secondary,
                            leading: const AutonannyIcon(
                              AutonannyIcons.video,
                            ),
                            onPressed: vm.pickVideo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AutonannySpacing.xl),
              AutonannyButton(
                label: 'Отправить жалобу',
                onPressed: vm.canSubmit ? vm.submitComplaint : null,
                variant: AutonannyButtonVariant.danger,
                isLoading: vm.isSubmitting,
              ),
              const SizedBox(height: AutonannySpacing.md),
              Text(
                'Мы рассмотрим обращение в течение 24 часов и свяжемся с вами.',
                textAlign: TextAlign.center,
                style: AutonannyTypography.bodyS(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final String reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.lg,
            vertical: AutonannySpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.statusDangerSurface
                : colors.surfaceSecondary,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(
              color: isSelected
                  ? colors.statusDanger
                  : colors.borderSubtle,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AutonannyIcon(
                isSelected
                    ? AutonannyIcons.checkCircle
                    : AutonannyIcons.dot,
                color: isSelected
                    ? colors.statusDanger
                    : colors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Text(
                  reason,
                  style: AutonannyTypography.bodyM(
                    color: isSelected
                        ? colors.statusDanger
                        : colors.textPrimary,
                  ).copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.file,
    required this.onRemove,
  });

  final dynamic file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return SizedBox(
      width: 110,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: AutonannyRadii.brLg,
            child: Image.file(
              file,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.statusDanger,
                  borderRadius: AutonannyRadii.brFull,
                ),
                child: const Center(
                  child: AutonannyIcon(
                    AutonannyIcons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
