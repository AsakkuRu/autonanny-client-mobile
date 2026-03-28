import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/support/support_chat_vm.dart';
import 'package:nanny_client/views/support/support_rating_view.dart';

class SupportChatView extends StatefulWidget {
  const SupportChatView({super.key});

  @override
  State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView> {
  late SupportChatVM vm;

  @override
  void initState() {
    super.initState();
    vm = SupportChatVM(context: context, update: setState);
    vm.loadPage();
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
        title: 'Поддержка',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: vm.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colors.actionPrimary,
                      ),
                    )
                  : vm.loadError != null && vm.messages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AutonannySpacing.xl),
                          child: AutonannyErrorState(
                            title: 'Не удалось открыть чат поддержки',
                            description: vm.loadError!,
                            actionLabel: 'Повторить',
                            onAction: vm.refresh,
                          ),
                        )
                      : vm.messages.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(AutonannySpacing.xl),
                              child: Center(
                                child: AutonannyEmptyState(
                                  title: 'Напишите нам',
                                  description:
                                      'Мы готовы помочь с любыми вопросами о сервисе АвтоНяня.',
                                  icon: AutonannyIcon(AutonannyIcons.chat),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: vm.refresh,
                              child: ListView.builder(
                                controller: vm.scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  AutonannySpacing.lg,
                                  AutonannySpacing.sm,
                                  AutonannySpacing.lg,
                                  AutonannySpacing.lg,
                                ),
                                reverse: true,
                                itemCount: vm.messages.length,
                                itemBuilder: (context, index) {
                                  final message = vm.messages[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AutonannySpacing.sm,
                                    ),
                                    child: _MessageBubble(message: message),
                                  );
                                },
                              ),
                            ),
            ),
            if (vm.showRatingBanner)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AutonannySpacing.lg,
                  0,
                  AutonannySpacing.lg,
                  AutonannySpacing.sm,
                ),
                child: _RatingBanner(
                  onRateTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupportRatingView(
                          ticketId: vm.chatId ?? 0,
                          onSubmitted: vm.onRatingSubmitted,
                        ),
                      ),
                    );
                  },
                  onDismiss: vm.dismissRatingBanner,
                ),
              ),
            _ChatComposer(vm: vm),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final components = context.autonannyComponents;
    final isMe = message.isFromMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.lg,
            vertical: AutonannySpacing.md,
          ),
          decoration: BoxDecoration(
            color: isMe ? null : colors.surfaceElevated,
            gradient: isMe ? components.primaryActionGradient : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: Radius.circular(isMe ? 24 : 8),
              bottomRight: Radius.circular(isMe ? 8 : 24),
            ),
            boxShadow: AutonannyShadows.card,
            border: isMe ? null : Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: AutonannyTypography.bodyM(
                  color: isMe ? colors.textInverse : colors.textPrimary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.timeString,
                    style: AutonannyTypography.caption(
                      color: isMe
                          ? colors.textInverse.withValues(alpha: 0.76)
                          : colors.textTertiary,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: AutonannySpacing.xs),
                    AutonannyIcon(
                      message.isRead
                          ? AutonannyIcons.checkCircle
                          : AutonannyIcons.check,
                      size: 14,
                      color: colors.textInverse.withValues(alpha: 0.84),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBanner extends StatelessWidget {
  const _RatingBanner({
    required this.onRateTap,
    required this.onDismiss,
  });

  final VoidCallback onRateTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AutonannyInlineBanner(
      title: 'Оцените качество поддержки',
      message: 'Ваш отзыв помогает нам быстрее улучшать работу операторов.',
      tone: AutonannyBannerTone.info,
      leading: const AutonannyIcon(AutonannyIcons.star),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onRateTap,
            child: Text(
              'Оценить',
              style: AutonannyTypography.labelM(
                color: context.autonannyColors.statusInfo,
              ),
            ),
          ),
          const SizedBox(width: AutonannySpacing.xs),
          GestureDetector(
            onTap: onDismiss,
            child: AutonannyIcon(
              AutonannyIcons.close,
              size: 16,
              color: context.autonannyColors.statusInfo,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.vm});

  final SupportChatVM vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AutonannySpacing.md,
        AutonannySpacing.sm,
        AutonannySpacing.md,
        MediaQuery.of(context).padding.bottom + AutonannySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        boxShadow: AutonannyShadows.card,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AutonannyTextField(
              controller: vm.messageController,
              hintText: 'Сообщение...',
              maxLines: 4,
            ),
          ),
          const SizedBox(width: AutonannySpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AutonannyIconButton(
              icon: const AutonannyIcon(AutonannyIcons.arrowRight),
              onPressed: vm.isSending ? null : vm.sendMessage,
              variant: AutonannyIconButtonVariant.primary,
              tooltip: vm.isSending ? 'Отправляем...' : 'Отправить',
            ),
          ),
        ],
      ),
    );
  }
}
