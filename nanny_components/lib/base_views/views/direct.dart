import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/direct_vm.dart';
import 'package:nanny_components/base_views/views/document_view.dart';
import 'package:nanny_components/base_views/views/video_view.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/chat_message.dart';
import 'package:nanny_core/nanny_core.dart';

class DirectView extends StatefulWidget {
  final int idChat;
  final String? name;

  const DirectView({super.key, required this.idChat, this.name});

  @override
  State<DirectView> createState() => _DirectViewState();
}

class _DirectViewState extends State<DirectView> {
  late DirectVM vm;

  @override
  void initState() {
    super.initState();
    vm = DirectVM(context: context, update: setState, idChat: widget.idChat);

    vm.scrollController.addListener(() {
      if (vm.scrollController.position.pixels ==
              vm.scrollController.position.maxScrollExtent &&
          !vm.isLoadingMore &&
          vm.hasMoreMessages) {
        vm.loadMessages();
      }
    });
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: widget.name ?? 'Чат',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
        actions: [
          AutonannyIconButton(
            icon: const AutonannyIcon(AutonannyIcons.edit),
            variant: vm.isEditingMode
                ? AutonannyIconButtonVariant.primary
                : AutonannyIconButtonVariant.surface,
            onPressed: () {
              setState(vm.toggleEditingMode);
              if (!vm.isEditingMode) {
                _resetEditing();
              }
            },
            tooltip: 'Редактировать сообщения',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (vm.isEditingMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AutonannySpacing.lg,
                  0,
                  AutonannySpacing.lg,
                  AutonannySpacing.sm,
                ),
                child: AutonannyInlineBanner(
                  title: 'Режим редактирования',
                  message:
                      'Нажмите на ваше сообщение, чтобы изменить текст, или завершите редактирование.',
                  leading: const AutonannyIcon(AutonannyIcons.edit),
                  trailing: AutonannyIconButton(
                    size: 36,
                    variant: AutonannyIconButtonVariant.ghost,
                    icon: const AutonannyIcon(AutonannyIcons.close),
                    onPressed: _resetEditing,
                    tooltip: 'Закрыть',
                  ),
                ),
              ),
            Expanded(
              child: RequestLoader(
                request: vm.messagesRequest,
                completeView: (context, data) {
                  final fetchedMessages = data?.messages ?? <ChatMessage>[];
                  vm.messages ??= <ChatMessage>[];
                  if (vm.messages!.isEmpty && fetchedMessages.isNotEmpty) {
                    vm.messages!.addAll(fetchedMessages);
                  }

                  if ((vm.messages ?? const <ChatMessage>[]).isEmpty) {
                    return const AutonannyEmptyState(
                      title: 'Сообщений пока нет',
                      description:
                          'Напишите первым, чтобы начать диалог по поездке или контракту.',
                      icon: AutonannyIcon(AutonannyIcons.chat),
                    );
                  }

                  return Stack(
                    children: [
                      ListView.separated(
                        controller: vm.scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AutonannySpacing.lg,
                          AutonannySpacing.sm,
                          AutonannySpacing.lg,
                          AutonannySpacing.lg,
                        ),
                        reverse: true,
                        itemCount: vm.messages!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AutonannySpacing.sm),
                        itemBuilder: (context, index) {
                          final message = vm.messages![index];
                          return GestureDetector(
                            onTap: () {
                              if (vm.isEditingMode && message.isMe) {
                                setState(() {
                                  vm.startEditingMessage(message);
                                });
                              }
                            },
                            child: _MessageBubble(
                              message: message,
                              onOpenImage: _openImageView,
                              onOpenPdf: _openPdfFile,
                              onOpenVideo: (url) => vm.navigateToView(
                                VideoView(url: url),
                              ),
                            ),
                          );
                        },
                      ),
                      if (vm.isLoadingMore)
                        const Positioned(
                          top: AutonannySpacing.sm,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                errorView: (context, error) => AutonannyErrorState(
                  title: 'Не удалось открыть чат',
                  description: error.toString(),
                  actionLabel: 'Повторить',
                  onAction: () {
                    setState(() {
                      vm.messages = null;
                      vm.messagesRequest = vm.reloadMessages();
                    });
                  },
                ),
              ),
            ),
            _Composer(
              vm: vm,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  void _resetEditing() {
    if (vm.isEditingMode) {
      vm.toggleEditingMode();
    }
    vm.editingMessageId = null;
    vm.textController.clear();
    setState(() {});
  }

  void _openImageView(String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: NetImage(
              url: url,
              fitToShortest: false,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(AutonannySpacing.lg),
              child: AutonannyIconButton(
                icon: const AutonannyIcon(AutonannyIcons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdfFile(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DocumentView(url: url)),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onOpenImage,
    required this.onOpenPdf,
    required this.onOpenVideo,
  });

  final ChatMessage message;
  final ValueChanged<String> onOpenImage;
  final ValueChanged<String> onOpenPdf;
  final ValueChanged<String> onOpenVideo;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final components = context.autonannyComponents;

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
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
            color: message.isMe ? null : colors.surfaceElevated,
            gradient: message.isMe ? components.primaryActionGradient : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: Radius.circular(message.isMe ? 24 : 8),
              bottomRight: Radius.circular(message.isMe ? 8 : 24),
            ),
            border:
                message.isMe ? null : Border.all(color: colors.borderSubtle),
            boxShadow: AutonannyShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageContent(
                message: message,
                onOpenImage: onOpenImage,
                onOpenPdf: onOpenPdf,
                onOpenVideo: onOpenVideo,
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                _timestampLabel(message),
                style: AutonannyTypography.caption(
                  color: message.isMe
                      ? colors.textInverse.withValues(alpha: 0.84)
                      : colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timestampLabel(ChatMessage message) {
    final timestamp = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(
        (message.timestampSend * 1000).toInt(),
      ),
    );
    return message.edited ? '(ред.) $timestamp' : timestamp;
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.onOpenImage,
    required this.onOpenPdf,
    required this.onOpenVideo,
  });

  final ChatMessage message;
  final ValueChanged<String> onOpenImage;
  final ValueChanged<String> onOpenPdf;
  final ValueChanged<String> onOpenVideo;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final textColor = message.isMe ? colors.textInverse : colors.textPrimary;
    final textStyle = AutonannyTypography.bodyM(color: textColor);

    if (message.msg.split('.').last == 'gif') {
      message.msgType = 2;
    }

    switch (message.msgType) {
      case 1:
      case 5:
        return Text(message.msg, style: textStyle);
      case 2:
        return GestureDetector(
          onTap: () => onOpenImage(message.msg),
          child: ClipRRect(
            borderRadius: AutonannyRadii.brLg,
            child: NetImage(
              radius: 0,
              url: message.msg,
              fitToShortest: false,
            ),
          ),
        );
      case 3:
        return GestureDetector(
          onTap: () => onOpenVideo(message.msg),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: AutonannyRadii.brLg,
              color: message.isMe
                  ? Colors.white.withValues(alpha: 0.16)
                  : colors.surfaceSecondary,
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: textColor,
                size: 52,
              ),
            ),
          ),
        );
      case 4:
        return InkWell(
          onTap: () => onOpenPdf(message.msg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutonannyIcon(
                AutonannyIcons.document,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Flexible(
                child: Text(
                  message.msg.split('/').last,
                  style: textStyle.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return Text(message.msg, style: textStyle);
    }
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.vm,
    required this.onChanged,
  });

  final DirectVM vm;
  final VoidCallback onChanged;

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
        border: Border(top: BorderSide(color: colors.borderSubtle)),
        boxShadow: AutonannyShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AutonannyIconButton(
            size: 44,
            icon: const AutonannyIcon(AutonannyIcons.add),
            onPressed: vm.attachImage,
            tooltip: 'Прикрепить файл',
          ),
          const SizedBox(width: AutonannySpacing.sm),
          Expanded(
            child: AutonannyTextField(
              controller: vm.textController,
              hintText: vm.editingMessageId != null
                  ? 'Измените сообщение'
                  : 'Сообщение...',
              maxLines: 4,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: AutonannySpacing.sm),
          AutonannyIconButton(
            size: 48,
            variant: AutonannyIconButtonVariant.primary,
            icon: const AutonannyIcon(AutonannyIcons.arrowRight),
            onPressed: vm.textController.text.trim().isEmpty
                ? null
                : () async {
                    await vm.sendTextMessage();
                    onChanged();
                  },
            tooltip: 'Отправить',
          ),
        ],
      ),
    );
  }
}
