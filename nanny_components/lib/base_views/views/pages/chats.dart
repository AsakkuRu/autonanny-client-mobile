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
      appBar: const AutonannyAppBar(title: 'Чаты'),
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
          _ChatsTabBar(
            value: selectedTab,
            onChanged: (value) =>
                vm.chatsSwitch(switchToChats: value == _ChatsTab.chats),
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
            'Когда водитель напишет вам или вы откроете диалог по поездке, он появится здесь.',
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

    final activeChats =
        sortedChats.where((chat) => !_ChatCard.isCompletedChat(chat)).toList();
    final completedChats =
        sortedChats.where(_ChatCard.isCompletedChat).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: AutonannySpacing.xxl),
      children: [
        if (activeChats.isNotEmpty) ...[
          const _ChatSectionHeader(label: 'Активные'),
          for (final chat in activeChats)
            _ChatCard(
              chat: chat,
              onTap: () {
                vm.navigateToDirect(chat);
                if (vm.node.hasFocus) {
                  vm.node.unfocus();
                }
              },
            ),
        ],
        if (completedChats.isNotEmpty) ...[
          const _ChatSectionHeader(label: 'Завершённые'),
          for (final chat in completedChats)
            _ChatCard(
              chat: chat,
              onTap: () {
                vm.navigateToDirect(chat);
                if (vm.node.hasFocus) {
                  vm.node.unfocus();
                }
              },
            ),
        ],
      ],
    );
  }

  Widget _buildRequestsList(List<ScheduleResponsesData> requests) {
    if (requests.isEmpty) {
      return const AutonannyEmptyState(
        title: 'Нет заявок',
        description:
            'Когда водители откликнутся на ваши контракты и поездки, заявки появятся здесь.',
        icon: AutonannyIcon(AutonannyIcons.calendar),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AutonannySpacing.xxl),
      children: [
        const _ChatSectionHeader(label: 'Новые заявки'),
        for (final item in requests)
          _RequestRow(
            item: item,
            onTap: () => vm.checkScheduleRequest(item),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}

class _ChatsTabBar extends StatelessWidget {
  const _ChatsTabBar({
    required this.value,
    required this.onChanged,
  });

  final _ChatsTab value;
  final ValueChanged<_ChatsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChatsTabButton(
            label: 'Чаты',
            isSelected: value == _ChatsTab.chats,
            onTap: () => onChanged(_ChatsTab.chats),
          ),
        ),
        Expanded(
          child: _ChatsTabButton(
            label: 'Заявки',
            isSelected: value == _ChatsTab.requests,
            onTap: () => onChanged(_ChatsTab.requests),
          ),
        ),
      ],
    );
  }
}

class _ChatsTabButton extends StatelessWidget {
  const _ChatsTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AutonannySpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colors.actionPrimary : colors.borderSubtle,
                width: isSelected ? 2.5 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: AutonannyTypography.labelL(
              color: isSelected ? colors.actionPrimary : colors.textSecondary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
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
    final unreadCount = message?.newMessages ?? 0;
    final isUnread = unreadCount > 0;
    final isSupport = isSupportChat(chat);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.xl,
            vertical: AutonannySpacing.lg,
          ),
          decoration: BoxDecoration(
            color: isUnread ? colors.surfaceSecondary : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: colors.borderSubtle),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChatAvatar(
                chat: chat,
                isSupport: isSupport,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: AutonannySpacing.sm,
                            runSpacing: AutonannySpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                chat.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AutonannyTypography.labelL(
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (isSupport)
                                const _SupportBadge()
                              else
                                const _ChatTypeBadge(),
                            ],
                          ),
                        ),
                        const SizedBox(width: AutonannySpacing.md),
                        Text(
                          _formatTimestamp(message?.time),
                          style: AutonannyTypography.caption(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            message?.msg.isNotEmpty == true
                                ? message!.msg
                                : 'Нет сообщений',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (isUnread
                                    ? AutonannyTypography.bodyS(
                                        color: colors.textPrimary,
                                      )
                                    : AutonannyTypography.bodyS(
                                        color: colors.textSecondary,
                                      ))
                                .copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: AutonannySpacing.sm),
                          _UnreadBadge(
                            label: _formatUnreadCount(unreadCount),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool isSupportChat(ChatElement chat) {
    final normalized = chat.username.trim().toLowerCase();
    return normalized.contains('поддерж') ||
        normalized.contains('автоняня');
  }

  static bool isCompletedChat(ChatElement chat) {
    final preview = (chat.message?.msg ?? '').toLowerCase();
    return preview.contains('заверш') || preview.contains('архив');
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
    final value = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateUtils.dateOnly(value);

    if (dateOnly == today) {
      return DateFormat('HH:mm').format(value);
    }
    if (dateOnly == yesterday) {
      return 'Вчера';
    }
    return DateFormat('dd.MM').format(value);
  }

  static String _formatUnreadCount(int count) {
    if (count > 99) {
      return '99+';
    }
    return '$count';
  }
}

class _ChatSectionHeader extends StatelessWidget {
  const _ChatSectionHeader({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.xl,
        AutonannySpacing.md,
        AutonannySpacing.xl,
        AutonannySpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AutonannyTypography.caption(
          color: colors.textTertiary,
        ).copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.actionPrimary,
        borderRadius: AutonannyRadii.brFull,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AutonannyTypography.caption(
          color: colors.textInverse,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SupportBadge extends StatelessWidget {
  const _SupportBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: const BoxDecoration(
        color: Color(0x1FF59E0B),
        borderRadius: AutonannyRadii.brFull,
      ),
      child: const Text(
        'АвтоНяня',
        style: TextStyle(
          color: Color(0xFFD97706),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatTypeBadge extends StatelessWidget {
  const _ChatTypeBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.actionPrimary.withValues(alpha: 0.12),
        borderRadius: AutonannyRadii.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutonannyIcon(
            AutonannyIcons.car,
            size: 10,
            color: colors.actionPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            'Водитель',
            style: AutonannyTypography.caption(
              color: colors.actionPrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.chat,
    required this.isSupport,
  });

  final ChatElement chat;
  final bool isSupport;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    if (isSupport && chat.photoPath.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const AutonannyIcon(
          AutonannyIcons.chat,
          color: Colors.white,
          size: 22,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AutonannyAvatar(
          imageUrl: chat.photoPath,
          initials: _ChatCard._initials(chat.username),
          size: 50,
        ),
        if (!isSupport)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.statusSuccess,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.surfaceElevated,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
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
    final colors = context.autonannyColors;
    final subtitleParts = <String>[
      if ((item.schedule?.title ?? '').isNotEmpty) item.schedule!.title,
      '${item.data.length} маршрутов • ${item.fullTime ? 'полная занятость' : 'частичная'}',
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.xl,
            vertical: AutonannySpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.borderSubtle),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutonannyAvatar(
                imageUrl: item.photoPath,
                initials: _ChatCard._initials(item.name),
                size: 50,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      subtitleParts.join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              const AutonannyBadge(
                label: 'Новая',
                variant: AutonannyBadgeVariant.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
