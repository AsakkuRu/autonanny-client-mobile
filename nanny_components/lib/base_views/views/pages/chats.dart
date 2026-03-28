import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/pages/chats_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/nanny_core.dart';

enum _ChatsTab { requests, chats }

class ChatsView extends StatefulWidget {
  final bool persistState;

  /// Вызывается после возврата из чата (для сброса бейджа непрочитанных в нижнем баре)
  final VoidCallback? onReturnFromChat;
  final Widget Function(int driverId)? buildDriverRatingView;

  const ChatsView({
    super.key,
    this.persistState = false,
    this.onReturnFromChat,
    this.buildDriverRatingView,
  });

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView>
    with AutomaticKeepAliveClientMixin {
  late ChatsVM vm;

  @override
  void initState() {
    super.initState();
    vm = ChatsVM(
      context: context,
      update: setState,
      onReturnFromChat: widget.onReturnFromChat,
      buildDriverRatingView: widget.buildDriverRatingView,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    final selectedTab = vm.chatsSelected ? _ChatsTab.chats : _ChatsTab.requests;

    return AutonannyListScreenShell(
      appBar: const AutonannyAppBar(title: 'Сообщения'),
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.lg,
        AutonannySpacing.sm,
        AutonannySpacing.lg,
        AutonannySpacing.xl,
      ),
      header: Column(
        children: [
          AutonannySearchField(
            focusNode: vm.node,
            hintText: 'Поиск по чатам',
            onChanged: vm.chatSearch,
            leading: const Padding(
              padding: EdgeInsets.all(14),
              child: AutonannyIcon(AutonannyIcons.search),
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          AutonannySegmentedControl<_ChatsTab>(
            value: selectedTab,
            onChanged: (value) =>
                vm.chatsSwitch(switchToChats: value == _ChatsTab.chats),
            options: const [
              AutonannySegmentedOption(
                value: _ChatsTab.requests,
                label: 'Заявки',
              ),
              AutonannySegmentedOption(
                value: _ChatsTab.chats,
                label: 'Чаты',
              ),
            ],
          ),
        ],
      ),
      body: StatefulBuilder(
        builder: (context, update) {
          vm.updateList = () => update(() {});

          return vm.chatsSelected
              ? RequestLoader(
                  request: vm.getChats,
                  completeView: (context, data) =>
                      _buildChatsList(data?.chats ?? const <ChatElement>[]),
                  errorView: (context, error) => AutonannyErrorState(
                    title: 'Не удалось загрузить чаты',
                    description: error.toString(),
                    actionLabel: 'Повторить',
                    onAction: vm.updateList,
                  ),
                )
              : RequestLoader(
                  request: vm.getRequests,
                  completeView: (context, data) => _buildRequestsList(
                    data ?? const <ScheduleResponsesData>[],
                  ),
                  errorView: (context, error) => AutonannyErrorState(
                    title: 'Не удалось загрузить заявки',
                    description: error.toString(),
                    actionLabel: 'Повторить',
                    onAction: vm.updateList,
                  ),
                );
        },
      ),
    );
  }

  Widget _buildChatsList(List<ChatElement> chats) {
    if (chats.isEmpty) {
      return const AutonannyEmptyState(
        title: 'Пока нет чатов',
        description:
            'Когда родитель напишет вам или вы откроете диалог по контракту, он появится здесь.',
        icon: AutonannyIcon(AutonannyIcons.chat),
      );
    }

    final sortedChats = List<ChatElement>.from(chats)
      ..sort((a, b) {
        final aTime = a.message?.time ?? 0;
        final bTime = b.message?.time ?? 0;
        if (aTime != bTime) {
          return bTime.compareTo(aTime);
        }

        final aUnread = a.message?.newMessages ?? 0;
        final bUnread = b.message?.newMessages ?? 0;
        if (aUnread != bUnread) {
          return bUnread.compareTo(aUnread);
        }

        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AutonannySpacing.xxl),
      itemCount: sortedChats.length,
      separatorBuilder: (_, __) => const SizedBox(height: AutonannySpacing.sm),
      itemBuilder: (context, index) {
        final chat = sortedChats[index];
        return _ChatCard(
          chat: chat,
          onTap: () {
            vm.navigateToDirect(chat);
            if (vm.node.hasFocus) {
              vm.node.unfocus();
            }
          },
        );
      },
    );
  }

  Widget _buildRequestsList(List<ScheduleResponsesData> requests) {
    if (requests.isEmpty) {
      return const AutonannyEmptyState(
        title: 'Нет заявок',
        description:
            'Когда по вашим контрактам появятся отклики, они будут собраны на этом экране.',
        icon: AutonannyIcon(AutonannyIcons.calendar),
      );
    }

    final fullTime = requests.where((item) => item.fullTime).toList();
    final partTime = requests.where((item) => !item.fullTime).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AutonannySpacing.xxl),
      children: [
        if (fullTime.isNotEmpty)
          _RequestSection(
            title: 'Заявки на полную занятость',
            items: fullTime,
            onTap: vm.checkScheduleRequest,
          ),
        if (fullTime.isNotEmpty && partTime.isNotEmpty)
          const SizedBox(height: AutonannySpacing.lg),
        if (partTime.isNotEmpty)
          _RequestSection(
            title: 'Заявки на частичную занятость',
            items: partTime,
            onTap: vm.checkScheduleRequest,
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.chat,
    required this.onTap,
  });

  final ChatElement chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final message = chat.message;

    return AutonannyCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: Padding(
          padding: const EdgeInsets.all(AutonannySpacing.lg),
          child: Row(
            children: [
              AutonannyAvatar(
                imageUrl: chat.photoPath,
                initials: _initials(chat.username),
                size: 56,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      message?.msg.isNotEmpty == true
                          ? message!.msg
                          : 'Нет сообщений',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimestamp(message?.time),
                    style: AutonannyTypography.caption(
                      color: colors.textTertiary,
                    ),
                  ),
                  if ((message?.newMessages ?? 0) > 0) ...[
                    const SizedBox(height: AutonannySpacing.sm),
                    AutonannyBadge(
                      label: _formatUnreadCount(message!.newMessages),
                      variant: AutonannyBadgeVariant.info,
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

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'A';
    }
    return parts.map((part) => part[0]).join().toUpperCase();
  }

  static String _formatTimestamp(int? timestamp) {
    if (timestamp == null || timestamp <= 0) {
      return '';
    }
    return DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
  }

  static String _formatUnreadCount(int count) {
    if (count > 99) {
      return '99+';
    }
    return '$count';
  }
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({
    required this.title,
    required this.items,
    required this.onTap,
  });

  final String title;
  final List<ScheduleResponsesData> items;
  final ValueChanged<ScheduleResponsesData> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannySectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AutonannyTypography.h3(color: colors.textPrimary),
                ),
              ),
              AutonannyBadge(
                label: '${items.length}',
                variant: AutonannyBadgeVariant.warning,
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.md),
          for (var index = 0; index < items.length; index++) ...[
            _RequestRow(
              item: items[index],
              onTap: () => onTap(items[index]),
            ),
            if (index != items.length - 1) ...[
              const SizedBox(height: AutonannySpacing.sm),
              Divider(color: colors.borderSubtle, height: 1),
              const SizedBox(height: AutonannySpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.item,
    required this.onTap,
  });

  final ScheduleResponsesData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if ((item.schedule?.title ?? '').isNotEmpty) item.schedule!.title,
      '${item.data.length} маршрутов • ${item.fullTime ? 'полная занятость' : 'частичная'}',
    ];

    return AutonannyListRow(
      onTap: onTap,
      leading: AutonannyAvatar(
        imageUrl: item.photoPath,
        initials: _ChatCard._initials(item.name),
        size: 48,
      ),
      title: item.name,
      subtitle: subtitleParts.join('\n'),
      trailing: const AutonannyIcon(
        AutonannyIcons.chevronRight,
        size: 18,
      ),
      padding: EdgeInsets.zero,
    );
  }
}
